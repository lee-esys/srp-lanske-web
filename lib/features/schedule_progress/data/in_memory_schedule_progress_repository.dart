import '../application/schedule_progress_repository.dart';
import '../domain/schedule_progress_models.dart';

class InMemoryScheduleProgressRepository
    implements ScheduleProgressRepository {
  InMemoryScheduleProgressRepository({
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final DateTime Function() _clock;
  final Map<String, ScheduleProgressSummary> _summaries = {};
  final Map<String, Map<String, ScheduleMatchProgress>> _matchesByScope = {};

  @override
  Future<ScheduleProgressSummary> ensureSummary({
    required ScheduleProgressScope scope,
    required int totalMatchCount,
  }) async {
    _validateTotalMatchCount(totalMatchCount);

    final current = _summaries[scope.storageKey];
    _ensureTotalMatchCount(
      summary: current,
      totalMatchCount: totalMatchCount,
    );
    if (current != null) {
      return current;
    }

    final now = _clock();
    final summary = ScheduleProgressSummary(
      schemaVersion: ScheduleProgressSummary.currentSchemaVersion,
      scheduleType: scope.scheduleType,
      generatedScheduleId: scope.generatedScheduleId,
      totalMatchCount: totalMatchCount,
      completedMatchCount: 0,
      inProgressMatchCount: 0,
      createdAt: now,
      updatedAt: now,
      revision: 1,
    );
    _summaries[scope.storageKey] = summary;
    return summary;
  }

  @override
  Future<ScheduleProgressSummary?> findSummary(
    ScheduleProgressScope scope,
  ) async {
    return _summaries[scope.storageKey];
  }

  @override
  Future<List<ScheduleMatchProgress>> listMatches(
    ScheduleProgressScope scope,
  ) async {
    final matches = _matchesByScope[scope.storageKey]?.values.toList() ??
        <ScheduleMatchProgress>[];
    matches.sort((left, right) => left.key.compareTo(right.key));
    return List<ScheduleMatchProgress>.unmodifiable(matches);
  }

  @override
  Future<ScheduleMatchProgress> findMatch({
    required ScheduleProgressScope scope,
    required int roundNo,
    required int courtNo,
    int? matchNo,
  }) async {
    final key = ScheduleMatchKey(roundNo: roundNo, courtNo: courtNo);
    final existing = _matchesByScope[scope.storageKey]?[key.value];
    if (existing != null) {
      return existing;
    }

    return ScheduleMatchProgress.scheduledPlaceholder(
      scope: scope,
      roundNo: roundNo,
      courtNo: courtNo,
      matchNo: matchNo,
    );
  }

  @override
  Future<ScheduleMatchProgress> saveMatch({
    required ScheduleProgressScope scope,
    required ScheduleMatchProgressUpdate update,
    required int totalMatchCount,
    required int expectedRevision,
  }) async {
    _validateSaveArguments(
      totalMatchCount: totalMatchCount,
      expectedRevision: expectedRevision,
    );

    final scopeMatches = _matchesByScope.putIfAbsent(
      scope.storageKey,
      () => <String, ScheduleMatchProgress>{},
    );
    final current = scopeMatches[update.key.value];
    final actualRevision = current?.revision ?? 0;
    if (actualRevision != expectedRevision) {
      throw ScheduleProgressConflictException(
        matchKey: update.key,
        expectedRevision: expectedRevision,
        actualRevision: actualRevision,
      );
    }

    final currentSummary = _summaries[scope.storageKey];
    _ensureTotalMatchCount(
      summary: currentSummary,
      totalMatchCount: totalMatchCount,
    );

    final now = _clock();
    final nextMatch = ScheduleMatchProgress(
      schemaVersion: ScheduleMatchProgress.currentSchemaVersion,
      scheduleType: scope.scheduleType,
      generatedScheduleId: scope.generatedScheduleId,
      roundNo: update.roundNo,
      courtNo: update.courtNo,
      matchNo: update.matchNo ?? current?.matchNo,
      status: update.status,
      result: update.result,
      note: update.note,
      startedAt: update.startedAt,
      finishedAt: update.finishedAt,
      createdAt: current?.createdAt ?? now,
      updatedAt: now,
      revision: actualRevision + 1,
    );

    final nextSummary = _buildNextSummary(
      scope: scope,
      currentSummary: currentSummary,
      previousStatus: current?.status ?? ScheduleMatchStatus.scheduled,
      nextStatus: nextMatch.status,
      totalMatchCount: totalMatchCount,
      now: now,
    );

    scopeMatches[update.key.value] = nextMatch;
    _summaries[scope.storageKey] = nextSummary;

    return nextMatch;
  }
}

void _validateTotalMatchCount(int totalMatchCount) {
  if (totalMatchCount <= 0) {
    throw ArgumentError.value(
      totalMatchCount,
      'totalMatchCount',
      'must be positive',
    );
  }
}

void _validateSaveArguments({
  required int totalMatchCount,
  required int expectedRevision,
}) {
  _validateTotalMatchCount(totalMatchCount);
  if (expectedRevision < 0) {
    throw ArgumentError.value(
      expectedRevision,
      'expectedRevision',
      'must not be negative',
    );
  }
}

void _ensureTotalMatchCount({
  required ScheduleProgressSummary? summary,
  required int totalMatchCount,
}) {
  if (summary != null && summary.totalMatchCount != totalMatchCount) {
    throw StateError(
      'total match count mismatch: '
      'expected ${summary.totalMatchCount}, actual $totalMatchCount',
    );
  }
}

ScheduleProgressSummary _buildNextSummary({
  required ScheduleProgressScope scope,
  required ScheduleProgressSummary? currentSummary,
  required ScheduleMatchStatus previousStatus,
  required ScheduleMatchStatus nextStatus,
  required int totalMatchCount,
  required DateTime now,
}) {
  final completedMatchCount =
      (currentSummary?.completedMatchCount ?? 0) -
          _statusCount(previousStatus, ScheduleMatchStatus.completed) +
          _statusCount(nextStatus, ScheduleMatchStatus.completed);
  final inProgressMatchCount =
      (currentSummary?.inProgressMatchCount ?? 0) -
          _statusCount(previousStatus, ScheduleMatchStatus.inProgress) +
          _statusCount(nextStatus, ScheduleMatchStatus.inProgress);

  return ScheduleProgressSummary(
    schemaVersion: ScheduleProgressSummary.currentSchemaVersion,
    scheduleType: scope.scheduleType,
    generatedScheduleId: scope.generatedScheduleId,
    totalMatchCount: totalMatchCount,
    completedMatchCount: completedMatchCount,
    inProgressMatchCount: inProgressMatchCount,
    createdAt: currentSummary?.createdAt ?? now,
    updatedAt: now,
    revision: (currentSummary?.revision ?? 0) + 1,
  );
}

int _statusCount(
  ScheduleMatchStatus actual,
  ScheduleMatchStatus target,
) {
  return actual == target ? 1 : 0;
}
