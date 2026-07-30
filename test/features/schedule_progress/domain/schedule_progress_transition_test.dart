import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_transition.dart';

void main() {
  final scope = ScheduleProgressScope(
    scheduleType: ScheduleProgressScheduleType.doubles,
    shareId: 'PUBLIC01',
    generatedScheduleId: 'generated-1',
  );

  test('creates initial not-started summary', () {
    final now = DateTime.utc(2026, 7, 30);

    final summary = createInitialScheduleProgressSummary(
      scope: scope,
      totalMatchCount: 10,
      now: now,
    );

    expect(summary.completedMatchCount, 0);
    expect(summary.inProgressMatchCount, 0);
    expect(summary.scheduledMatchCount, 10);
    expect(summary.overallStatus, ScheduleOverallProgressStatus.notStarted);
    expect(summary.createdAt, now);
    expect(summary.updatedAt, now);
    expect(summary.revision, 1);
  });

  test('preserves match identity data and increments revision', () {
    final createdAt = DateTime.utc(2026, 7, 30, 1);
    final updatedAt = DateTime.utc(2026, 7, 30, 2);
    final current = ScheduleMatchProgress(
      schemaVersion: ScheduleMatchProgress.currentSchemaVersion,
      scheduleType: ScheduleProgressScheduleType.team,
      generatedScheduleId: 'generated-1',
      roundNo: 1,
      courtNo: 1,
      matchNo: 5,
      status: ScheduleMatchStatus.inProgress,
      result: null,
      note: '',
      startedAt: createdAt,
      finishedAt: null,
      createdAt: createdAt,
      updatedAt: createdAt,
      revision: 1,
    );

    final next = buildSavedScheduleMatchProgress(
      scope: ScheduleProgressScope(
        scheduleType: ScheduleProgressScheduleType.team,
        shareId: 'TEAM0001',
        generatedScheduleId: 'generated-1',
      ),
      update: ScheduleMatchProgressUpdate(
        roundNo: 1,
        courtNo: 1,
        status: ScheduleMatchStatus.completed,
        result: ScheduleMatchResultSummary.simpleScore([4, 2]),
        finishedAt: updatedAt,
      ),
      current: current,
      now: updatedAt,
    );

    expect(next.matchNo, 5);
    expect(next.createdAt, createdAt);
    expect(next.updatedAt, updatedAt);
    expect(next.revision, 2);
  });

  test('decrements completed count when match returns to scheduled', () {
    final createdAt = DateTime.utc(2026, 7, 30, 1);
    final now = DateTime.utc(2026, 7, 30, 2);
    final currentSummary = ScheduleProgressSummary(
      schemaVersion: ScheduleProgressSummary.currentSchemaVersion,
      scheduleType: scope.scheduleType,
      generatedScheduleId: scope.generatedScheduleId,
      totalMatchCount: 10,
      completedMatchCount: 3,
      inProgressMatchCount: 1,
      createdAt: createdAt,
      updatedAt: createdAt,
      revision: 4,
    );

    final next = buildUpdatedScheduleProgressSummary(
      scope: scope,
      currentSummary: currentSummary,
      previousStatus: ScheduleMatchStatus.completed,
      nextStatus: ScheduleMatchStatus.scheduled,
      totalMatchCount: 10,
      now: now,
    );

    expect(next.completedMatchCount, 2);
    expect(next.inProgressMatchCount, 1);
    expect(next.scheduledMatchCount, 7);
    expect(next.createdAt, createdAt);
    expect(next.updatedAt, now);
    expect(next.revision, 5);
  });
}
