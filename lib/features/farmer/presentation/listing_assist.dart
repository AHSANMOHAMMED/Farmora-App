import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_format.dart';
import '../../../core/localization/l10n.dart';
import '../../../models/market_price_index.dart';
import '../../../services/crop_doctor_service.dart' show kGeminiModel;

/// Market prices (public, admin-curated) cached for the session.
Future<List<MarketPriceIndex>>? _pricesFuture;

Future<List<MarketPriceIndex>> _marketPrices() => _pricesFuture ??=
    FirebaseFirestore.instance
        .collection('market_prices')
        .limit(300)
        .get()
        .then((s) => s.docs.map((d) => MarketPriceIndex.fromMap(d.data(), d.id)).toList())
        .catchError((Object _) => <MarketPriceIndex>[]);

/// Best market benchmark for a product name, preferring [district].
MarketPriceIndex? matchPrice(
    List<MarketPriceIndex> prices, String name, String district) {
  final n = name.trim().toLowerCase();
  if (n.length < 3) return null;
  final hits = prices.where((p) {
    final c = p.cropName.toLowerCase();
    return c.isNotEmpty && (c.contains(n) || n.contains(c));
  }).toList();
  if (hits.isEmpty) return null;
  hits.sort((a, b) {
    final da = a.district.toLowerCase() == district.toLowerCase() ? 0 : 1;
    final db = b.district.toLowerCase() == district.toLowerCase() ? 0 : 1;
    return da != db ? da - db : b.updatedAt.compareTo(a.updatedAt);
  });
  return hits.first;
}

/// Dynamic price suggestion: today's market range for the product typed in
/// [name], with a one-tap "use average".
class MarketPriceHint extends StatelessWidget {
  const MarketPriceHint({
    super.key,
    required this.name,
    required this.district,
    required this.onUse,
  });

  final ValueNotifier<TextEditingValue> name;
  final String district;
  final void Function(double pricePerKg) onUse;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return FutureBuilder<List<MarketPriceIndex>>(
      future: _marketPrices(),
      builder: (context, snap) => ValueListenableBuilder<TextEditingValue>(
        valueListenable: name,
        builder: (context, value, _) {
          final m = matchPrice(snap.data ?? const [], value.text, district);
          if (m == null) return const SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(children: [
              Icon(
                m.trend == 'up'
                    ? Icons.trending_up
                    : m.trend == 'down'
                        ? Icons.trending_down
                        : Icons.trending_flat,
                color: const Color(0xFFE65100),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l.priceHint(
                    m.cropName,
                    m.district,
                    AppFormat.lkr(m.minPricePerKg),
                    AppFormat.lkr(m.maxPricePerKg),
                    AppFormat.lkr(m.averagePricePerKg),
                  ),
                  style: const TextStyle(fontSize: 12),
                ),
              ),
              TextButton(
                onPressed: () => onUse(m.averagePricePerKg),
                child: Text(l.priceUseAverage),
              ),
            ]),
          );
        },
      ),
    );
  }
}

/// AI listing helper result.
class ListingSuggestion {
  const ListingSuggestion({
    required this.name,
    required this.category,
    required this.grade,
    required this.description,
  });

  final String name;
  final String category;
  final String grade;
  final String description;
}

/// Gemini (Firebase AI Logic) suggests name, category, visual grade and a
/// short buyer-facing description from a product photo.
Future<ListingSuggestion> suggestListing(
  Uint8List bytes,
  String mimeType, {
  required List<String> categories,
  String languageCode = 'en',
}) async {
  final language = const {'si': 'Sinhala', 'ta': 'Tamil'}[languageCode] ?? 'English';
  final model = FirebaseAI.googleAI().generativeModel(
    model: kGeminiModel,
    generationConfig: GenerationConfig(
      responseMimeType: 'application/json',
      temperature: 0.3,
    ),
  );
  final res = await model.generateContent([
    Content.multi([
      TextPart('You help Sri Lankan farmers list fresh produce. From the photo, '
          'return ONLY JSON {"name": string, "category": one of ${jsonEncode(categories)}, '
          '"grade": "A"|"B"|"C", "description": string}. Grade by visible '
          'uniformity, colour, damage and freshness (A best). The description is '
          '1–2 honest sentences for buyers, no prices, written in $language.'),
      InlineDataPart(mimeType, bytes),
    ]),
  ]);
  final text = res.text ?? '';
  final data = jsonDecode(text.substring(text.indexOf('{'), text.lastIndexOf('}') + 1))
      as Map<String, dynamic>;
  final category = (data['category'] ?? '').toString();
  return ListingSuggestion(
    name: (data['name'] ?? '').toString().trim(),
    category: categories.contains(category) ? category : categories.first,
    grade: const ['A', 'B', 'C'].contains(data['grade']) ? data['grade'] as String : 'B',
    description: (data['description'] ?? '').toString().trim(),
  );
}

/// Small banner shown after the AI fills the form.
class AiFilledNote extends StatelessWidget {
  const AiFilledNote({super.key, required this.grade});

  final String grade;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(context.l10n.aiListingFilled(grade),
            style: const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant)),
      );
}
