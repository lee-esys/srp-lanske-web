import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';

void main() {
  group('ScheduleMatchResultSummary', () {
    test('round-trips simple score json', () {
      final result = ScheduleMatchResultSummary.simpleScore([4, 2]);

      final restored = ScheduleMatchResultSummary.fromJson(result.toJson());

      expect(restored.type, ScheduleMatchResultSummary.simpleScoreType);
      expect(restored.sideScores, [4, 2]);
    });

    test('supports more than two sides for future team schedules', () {
      final result = ScheduleMatchResultSummary.simpleScore([3, 2, 1]);

      expect(result.sideScores, [3, 2, 1]);
    });

    test('rejects negative scores', () {
      expect(
        () => ScheduleMatchResultSummary.simpleScore([4, -1]),
        throwsArgumentError,
      );
    });
  });

  group('ScheduleMatchProgress', () {
    test('creates unpersisted scheduled placeholder', () {
      final scope = ScheduleProgressScope(
        scheduleType: ScheduleProgressScheduleType.doubles,
        shareId: 'PUBLIC01',
        generatedScheduleId: 'generated-1',
      );

      final match = ScheduleMatchProgress.scheduledPlaceholder(
        scope: scope,
        roundNo: 2,
        courtNo: 3,
      );

      expect(match.status, ScheduleMatchStatus.scheduled);
      expect(match.key.value, 'r2_c3');
      expect(match.revision, 0);
      expect(match.createdAt, isNull);
      expect(match.updatedAt, isNull);
      expect(match.isPersisted, isFalse);
      expect(match.toJson, throwsStateError);
    });

    test('round-trips persisted match json', () {
      final createdAt = DateTime.utc(2026, 7, 30, 1);
      final updatedAt = DateTime.utc(2026, 7, 30, 2);
      final match = ScheduleMatchProgress(
        schemaVersion: ScheduleMatchProgress.currentSchemaVersion,
        scheduleType: ScheduleProgressScheduleType.team,
        generatedScheduleId: 'generated-1',
        roundNo: 1,
        courtNo: 2,
        matchNo: 7,
        status: ScheduleMatchStatus.completed,
        result: ScheduleMatchResultSummary.simpleScore([5, 3]),
        note: '決勝',
        startedAt: createdAt,
        finishedAt: updatedAt,
        createdAt: createdAt,
        updatedAt: updatedAt,
        revision: 2,
      );

      final restored = ScheduleMatchProgress.fromJson(match.toJson());

      expect(restored.scheduleType, ScheduleProgressScheduleType.team);
      expect(restored.generatedScheduleId, 'generated-1');
      expect(restored.key.value, 'r1_c2');
      expect(restored.matchNo, 7);
      expect(restored.status, ScheduleMatchStatus.completed);
      expect(restored.result!.sideScores, [5, 3]);
      expect(restored.note, '決勝');
      expect(restored.startedAt, createdAt);
      expect(restored.finishedAt, updatedAt);
      expect(restored.createdAt, createdAt);
      expect(restored.updatedAt, updatedAt);
      expect(restored.revision, 2);
    });
  });

  group('ScheduleProgressSummary', () {
    ScheduleProgressSummary buildSummary({
      int total = 10,
      int completed = 0,
      int inProgress = 0,
    }) {
      final now = DateTime.utc(2026, 7, 30);
      return ScheduleProgressSummary(
        schemaVersion: ScheduleProgressSummary.currentSchemaVersion,
        scheduleType: ScheduleProgressScheduleType.doubles,
        generatedScheduleId: 'generated-1',
        totalMatchCount: total,
        completedMatchCount: completed,
        inProgressMatchCount: inProgress,
        createdAt: now,
        updatedAt: now,
        revision: 1,
      );
    }

    test('derives overall status and scheduled count', () {
      final notStarted = buildSummary();
      final inProgress = buildSummary(completed: 2, inProgress: 1);
      final completed = buildSummary(completed: 10);

      expect(
        notStarted.overallStatus,
        ScheduleOverallProgressStatus.notStarted,
      );
      expect(notStarted.scheduledMatchCount, 10);
      expect(
        inProgress.overallStatus,
        ScheduleOverallProgressStatus.inProgress,
      );
      expect(inProgress.scheduledMatchCount, 7);
      expect(
        completed.overallStatus,
        ScheduleOverallProgressStatus.completed,
      );
      expect(completed.scheduledMatchCount, 0);
    });

    test('round-trips summary json', () {
      final summary = buildSummary(completed: 4, inProgress: 2);

      final restored = ScheduleProgressSummary.fromJson(summary.toJson());

      expect(restored.totalMatchCount, 10);
      expect(restored.completedMatchCount, 4);
      expect(restored.inProgressMatchCount, 2);
      expect(restored.revision, 1);
    });
  });
}
