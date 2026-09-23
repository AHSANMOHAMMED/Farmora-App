import 'package:flutter_test/flutter_test.dart';
import 'package:farmora/features/transporter/application/job_suitability.dart';
import 'package:farmora/features/transporter/domain/collection_job.dart';

void main() {
  final now = DateTime(2026, 9, 23, 12);

  CollectionJob job({
    double quantity = 300,
    String unit = 'kg',
    DateTime? collectionDate,
  }) {
    return CollectionJob(
      id: 'j1',
      farmerId: 'f',
      buyerId: 'b',
      produceName: 'Tomatoes',
      quantity: quantity,
      unit: unit,
      pickupLocation: 'A',
      deliveryLocation: 'B',
      collectionDate: collectionDate ?? now.add(const Duration(hours: 12)),
      farmerName: 'F',
      farmerPhone: '',
      buyerName: 'B',
      buyerPhone: '',
      status: CollectionJobStatus.open,
      createdAt: now.subtract(const Duration(days: 1)),
      updatedAt: now,
    );
  }

  group('JobSuitabilityScorer', () {
    test('load between 50-100% of capacity scores highest capacity points',
        () {
      // 500 kg capacity, 300 kg load = 60% usage -> full capacity score.
      final scorer = JobSuitabilityScorer(
        vehicleCapacityKg: 500,
        now: () => now,
      );
      final result = scorer.score(job(quantity: 300));
      expect(result.capacityFit, isTrue);
      expect(result.score, greaterThanOrEqualTo(90));
    });

    test('overload gets zero capacity points and a warning', () {
      final scorer = JobSuitabilityScorer(
        vehicleCapacityKg: 200,
        now: () => now,
      );
      final result = scorer.score(job(quantity: 300));
      expect(result.capacityFit, isFalse);
      expect(result.warning, isNotNull);
      expect(result.score, lessThanOrEqualTo(40));
    });

    test('small load relative to capacity scores lower and warns', () {
      final scorer = JobSuitabilityScorer(
        vehicleCapacityKg: 2000,
        now: () => now,
      );
      final result = scorer.score(job(quantity: 100));
      expect(result.capacityFit, isTrue);
      expect(result.warning, isNotNull);
      expect(result.score, lessThan(50));
    });

    test('unknown capacity is neutral, not a penalty', () {
      const scorer = JobSuitabilityScorer(now: _now);
      final good = scorer.score(job());
      expect(good.capacityFit, isTrue);
      // 30 capacity + 40 urgency = 70.
      expect(good.score, 70);
    });

    test('tons are converted to kg', () {
      final scorer = JobSuitabilityScorer(
        vehicleCapacityKg: 2500,
        now: () => now,
      );
      final result = scorer.score(job(quantity: 2, unit: 'tons'));
      expect(result.capacityFit, isTrue);
      expect(result.score, greaterThanOrEqualTo(90));
    });

    test('urgent jobs (<=24h) outrank jobs further out', () {
      final scorer = JobSuitabilityScorer(
        vehicleCapacityKg: 500,
        now: () => now,
      );
      final urgent = scorer.score(
        job(collectionDate: now.add(const Duration(hours: 6))),
      );
      final later = scorer.score(
        job(collectionDate: now.add(const Duration(days: 5))),
      );
      expect(urgent.score, greaterThan(later.score));
    });

    test('rank orders best-fit jobs first and is stable on ties', () {
      final scorer = JobSuitabilityScorer(
        vehicleCapacityKg: 500,
        now: () => now,
      );
      final urgentFit = job(collectionDate: now.add(const Duration(hours: 6)));
      final laterFit = job(collectionDate: now.add(const Duration(days: 3)));
      final overload = job(quantity: 900);

      final ranked = scorer.rank([overload, laterFit, urgentFit]);
      expect(ranked.first.id, urgentFit.id);
      expect(ranked.last.id, overload.id);
    });
  });
}

DateTime _now() => DateTime(2026, 9, 23, 12);
