import '../domain/schedule_progress_models.dart';

abstract class ScheduleProgressRepository {
  Future<ScheduleProgressSummary> ensureSummary({
    required ScheduleProgressScope scope,
    required int totalMatchCount,
  });

  Future<ScheduleProgressSummary?> findSummary(
    ScheduleProgressScope scope,
  );

  Future<List<ScheduleMatchProgress>> listMatches(
    ScheduleProgressScope scope,
  );

  Future<ScheduleMatchProgress> findMatch({
    required ScheduleProgressScope scope,
    required int roundNo,
    required int courtNo,
    int? matchNo,
  });

  Future<ScheduleMatchProgress> saveMatch({
    required ScheduleProgressScope scope,
    required ScheduleMatchProgressUpdate update,
    required int totalMatchCount,
    required int expectedRevision,
  });
}

class ScheduleProgressConflictException implements Exception {
  const ScheduleProgressConflictException({
    required this.matchKey,
    required this.expectedRevision,
    required this.actualRevision,
  });

  final ScheduleMatchKey matchKey;
  final int expectedRevision;
  final int actualRevision;

  @override
  String toString() {
    return 'ScheduleProgressConflictException('
        'matchKey: $matchKey, '
        'expectedRevision: $expectedRevision, '
        'actualRevision: $actualRevision'
        ')';
  }
}
