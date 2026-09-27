import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/utils/firebase_values.dart';
import 'service_errors.dart';

/// Gemini model used by the crop doctor (Firebase AI Logic, Gemini
/// Developer API: free tier available on the Spark plan). Override with
/// `--dart-define=GEMINI_MODEL=...`.
const String kGeminiModel =
    String.fromEnvironment('GEMINI_MODEL', defaultValue: 'gemini-flash-latest');

/// Per-device daily cap that keeps usage inside the free quota.
const int kDailyDiagnoses = 15;

/// A photo diagnosis of a crop problem.
class CropDiagnosis {
  const CropDiagnosis({
    required this.healthy,
    required this.issue,
    required this.confidence,
    required this.summary,
    this.symptoms = const [],
    this.organicTreatment = const [],
    this.chemicalTreatment = const [],
    this.prevention = const [],
    this.seeExpert = false,
    this.id = '',
    this.crop = '',
    this.imageUrl,
    this.createdAt,
  });

  final String id;
  final String crop;
  final bool healthy;
  final String issue;

  /// low, medium or high.
  final String confidence;
  final String summary;
  final List<String> symptoms;
  final List<String> organicTreatment;
  final List<String> chemicalTreatment;
  final List<String> prevention;
  final bool seeExpert;
  final String? imageUrl;
  final DateTime? createdAt;

  static List<String> _list(Object? v) =>
      (v is List ? v : const []).map((e) => e.toString()).take(8).toList();

  factory CropDiagnosis.fromMap(Map<String, dynamic> d, {String id = ''}) =>
      CropDiagnosis(
        id: id,
        crop: (d['crop'] ?? '').toString(),
        healthy: d['healthy'] == true,
        issue: (d['issue'] ?? '').toString(),
        confidence: const ['low', 'medium', 'high']
                .contains((d['confidence'] ?? '').toString().toLowerCase())
            ? d['confidence'].toString().toLowerCase()
            : 'low',
        summary: (d['summary'] ?? '').toString(),
        symptoms: _list(d['symptoms']),
        organicTreatment: _list(d['organicTreatment']),
        chemicalTreatment: _list(d['chemicalTreatment']),
        prevention: _list(d['prevention']),
        seeExpert: d['seeExpert'] == true,
        imageUrl: (d['imageUrl'] ?? '').toString().isEmpty
            ? null
            : d['imageUrl'].toString(),
        createdAt: firebaseDate(d['createdAt']),
      );

  Map<String, dynamic> toMap() => {
        'crop': crop,
        'healthy': healthy,
        'issue': issue,
        'confidence': confidence,
        'summary': summary,
        'symptoms': symptoms,
        'organicTreatment': organicTreatment,
        'chemicalTreatment': chemicalTreatment,
        'prevention': prevention,
        'seeExpert': seeExpert,
      };
}

/// AI pest & disease identification from a photo, with a saved history.
class CropDoctorService {
  CropDoctorService({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw UserStateError('Authentication required.');
    return uid;
  }

  static const _languageNames = {
    'en': 'English',
    'si': 'Sinhala',
    'ta': 'Tamil',
  };

  static const _instruction = '''
You are an agronomist and plant-protection officer helping smallholder
farmers in Sri Lanka. Look at the photo and identify the most likely pest,
disease or nutrient problem of the crop. Be honest about uncertainty: if the
photo is unclear or not a plant, say so with low confidence. Prefer
integrated pest management: cultural and organic measures first. When you
suggest a chemical, name the active ingredient only, and remind the farmer to
follow the label and the Department of Agriculture recommendations. Recommend
an expert or the local agriculture instructor when the problem is serious or
you are unsure.

Reply ONLY with JSON:
{"healthy": bool, "issue": string, "confidence": "low"|"medium"|"high",
 "summary": string, "symptoms": [string], "organicTreatment": [string],
 "chemicalTreatment": [string], "prevention": [string], "seeExpert": bool}
Keep every list to at most 5 short items.''';

  Future<void> _checkQuota() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final key = 'crop_doctor_$today';
    final used = prefs.getInt(key) ?? 0;
    if (used >= kDailyDiagnoses) {
      throw UserStateError(
          'Daily photo check limit reached. Try again tomorrow or ask an expert.');
    }
    await prefs.setInt(key, used + 1);
  }

  /// Diagnoses the photo, then saves it (with the uploaded photo URL).
  Future<CropDiagnosis> diagnose({
    required Uint8List bytes,
    required String mimeType,
    String crop = '',
    String notes = '',
    String languageCode = 'en',
    String? imageUrl,
  }) async {
    final uid = _uid;
    await _checkQuota();
    final model = FirebaseAI.googleAI().generativeModel(
      model: kGeminiModel,
      systemInstruction: Content.system(_instruction),
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
        temperature: 0.2,
      ),
    );
    final language = _languageNames[languageCode] ?? 'English';
    final prompt = [
      if (crop.trim().isNotEmpty) 'Crop: ${crop.trim()}.',
      if (notes.trim().isNotEmpty) 'Farmer notes: ${notes.trim()}.',
      'Write all text values in $language.',
    ].join(' ');
    GenerateContentResponse response;
    try {
      response = await model.generateContent([
        Content.multi([TextPart(prompt), InlineDataPart(mimeType, bytes)]),
      ]);
    } on FirebaseAIException catch (e) {
      throw UserStateError('The crop doctor is unavailable right now (${e.message}).');
    }
    final text = response.text ?? '';
    Map<String, dynamic> data;
    try {
      final start = text.indexOf('{');
      final end = text.lastIndexOf('}');
      data = jsonDecode(text.substring(start, end + 1)) as Map<String, dynamic>;
    } catch (_) {
      throw UserStateError('Could not read the diagnosis. Try a clearer photo.');
    }
    final result = CropDiagnosis.fromMap({...data, 'crop': crop.trim()});
    final ref = _db.collection('crop_diagnoses').doc();
    await ref.set({
      ...result.toMap(),
      'farmerId': uid,
      'imageUrl': imageUrl,
      'model': kGeminiModel,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return CropDiagnosis.fromMap(
        {...result.toMap(), 'imageUrl': imageUrl}, id: ref.id);
  }

  Stream<List<CropDiagnosis>> history({int limit = 30}) => _db
      .collection('crop_diagnoses')
      .where('farmerId', isEqualTo: _uid)
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs
          .map((d) => CropDiagnosis.fromMap(d.data(), id: d.id))
          .toList());

  Future<void> delete(String id) =>
      _db.collection('crop_diagnoses').doc(id).delete();
}
