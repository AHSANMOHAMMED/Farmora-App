import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/services/crop_doctor_service.dart';

void main() {
  test('diagnosis parsing normalises confidence and caps lists', () {
    final d = CropDiagnosis.fromMap({
      'healthy': false,
      'issue': 'Early blight',
      'confidence': 'HIGH',
      'summary': 'Fungal leaf spots',
      'symptoms': List.generate(12, (i) => 's$i'),
      'organicTreatment': ['Remove infected leaves'],
      'chemicalTreatment': 'not a list',
      'seeExpert': true,
    });
    expect(d.confidence, 'high');
    expect(d.symptoms, hasLength(8));
    expect(d.chemicalTreatment, isEmpty);
    expect(d.seeExpert, isTrue);
    expect(CropDiagnosis.fromMap({'confidence': 'certain'}).confidence, 'low');
  });

  test('toMap round-trips the saved fields', () {
    const d = CropDiagnosis(
      healthy: true,
      issue: '',
      confidence: 'medium',
      summary: 'No problem found',
      crop: 'Tomato',
    );
    final back = CropDiagnosis.fromMap(d.toMap());
    expect(back.crop, 'Tomato');
    expect(back.healthy, isTrue);
    expect(back.confidence, 'medium');
  });
}
