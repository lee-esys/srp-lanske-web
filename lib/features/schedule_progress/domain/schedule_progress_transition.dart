import 'schedule_progress_models.dart';

void validateScheduleProgressTotalMatchCount(int totalMatchCount) {
  if (totalMatchCount <= 0) {
    throw ArgumentError.value(
      totalMatchCount,
      'totalMatchCount',
      'must be positive',
    );
  }
}

void validateScheduleProgressSaveArguments({
  required int totalMatchCount,
  required int expectedRevision,
}) {
  validateScheduleProgressTotalMatchCount(totalMatchCount);
  if (expectedRevision < 0) {
    throw ArgumentError.value(
      expectedRevision,
      'expectedRevision',
      'must not be negative',
    );
  }
}

void ensureScheduleProgressTotalMatchCount({
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

ScheduleProgressSummary createInitialScheduleProgressSummary({
  required ScheduleProgressScope scope,
  required int totalMatchCount,
  required DateTime now,
}) {
  validateScheduleProgressTotalMatchCount(totalMatchCount);

  return ScheduleProgressSummary(
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
}

ScheduleMatchProgress buildSavedScheduleMatchProgress({
  required ScheduleProgressScope scope,
  required ScheduleMatchProgressUpdate update,
  required ScheduleMatchProgress? current,
  required DateTime now,
}) {
  return ScheduleMatchProgress(
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
    revision: (current?.revision ?? 0) + 1,
  );
}

ScheduleProgressSummary buildUpdatedScheduleProgressSummary({
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
