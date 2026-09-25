import '../../../core/localization/l10n.dart';
import '../domain/collection_job.dart';

/// Result of scoring a job against a transporter's vehicle.
class JobSuitability {
  final int score;
  final bool capacityFit;
  final String? warning;

  const JobSuitability({
    required this.score,
    required this.capacityFit,
    this.warning,
  });

  bool get isGoodFit => score >= 70 && capacityFit;
}

/// Computes a 0–100 suitability score for a job.
///
/// Weighting:
///  - Capacity fit (60 pts): load must not exceed vehicle capacity; loads
///    between 50–100% of capacity score highest (efficient use of the trip).
///  - Date urgency (40 pts): sooner collection dates score higher; overdue
///    jobs get a small penalty since they may be stale.
class JobSuitabilityScorer {
  final double? vehicleCapacityKg;
  final DateTime Function() now;

  const JobSuitabilityScorer({
    this.vehicleCapacityKg,
    DateTime Function()? now,
  }) : now = now ?? DateTime.now;

  JobSuitability score(CollectionJob job) {
    final loadKg = _loadInKg(job);
    final capacity = vehicleCapacityKg;

    // --- Capacity fit: 0–60 points ------------------------------------
    double capacityScore;
    bool capacityFit = true;
    String? warning;

    if (capacity == null || capacity <= 0) {
      // Unknown vehicle capacity: neutral, no penalty.
      capacityScore = 30;
      capacityFit = true;
    } else if (loadKg > capacity) {
      capacityScore = 0;
      capacityFit = false;
      warning = L10n.current.jobWarnLoadExceeds;
    } else {
      final usage = loadKg / capacity; // 0..1
      // Best (60 pts) when the load uses 50–100% of capacity.
      capacityScore = usage >= 0.5 ? 60 : 60 * (usage / 0.5);
      if (loadKg > 0 && usage < 0.2) {
        warning = L10n.current.jobWarnSmallLoad;
      }
    }

    // --- Date urgency: 0–40 points ------------------------------------
    final hoursUntil = job.collectionDate.difference(now()).inHours;
    double urgencyScore;
    if (hoursUntil < 0) {
      urgencyScore = 20; // overdue — likely stale
    } else if (hoursUntil <= 24) {
      urgencyScore = 40; // urgent: today/tomorrow
    } else if (hoursUntil <= 72) {
      urgencyScore = 32;
    } else if (hoursUntil <= 7 * 24) {
      urgencyScore = 24;
    } else {
      urgencyScore = 12;
    }

    final clamped = (capacityScore + urgencyScore).round().clamp(0, 100);
    return JobSuitability(
      score: clamped.toInt(),
      capacityFit: capacityFit,
      warning: warning,
    );
  }

  /// Ranks [jobs] best-first. Stable for equal scores (earliest date first).
  List<CollectionJob> rank(Iterable<CollectionJob> jobs) {
    final scored = [
      for (final job in jobs) (job: job, suitability: score(job)),
    ]..sort((a, b) {
        final byScore = b.suitability.score.compareTo(a.suitability.score);
        if (byScore != 0) return byScore;
        return a.job.collectionDate.compareTo(b.job.collectionDate);
      });
    return [for (final entry in scored) entry.job];
  }

  double _loadInKg(CollectionJob job) => job.unit.toLowerCase().contains('ton')
      ? job.quantity * 1000
      : job.quantity;
}
