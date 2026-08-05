import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/doubles_progress_visuals.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';

void main() {
  final colorScheme = ColorScheme.fromSeed(seedColor: Colors.blue);

  group('doubles match visual styles', () {
    test('lets scheduled matches inherit the round background', () {
      final style = resolveDoublesMatchVisualStyle(
        colorScheme,
        ScheduleMatchStatus.scheduled,
      );

      expect(style.cardBackgroundColor, Colors.transparent);
      expect(style.cardBorderColor, colorScheme.outlineVariant);
    });

    test('uses error colors to emphasize matches in progress', () {
      final style = resolveDoublesMatchVisualStyle(
        colorScheme,
        ScheduleMatchStatus.inProgress,
      );

      expect(style.cardBackgroundColor, isNot(colorScheme.surface));
      expect(style.statusBackgroundColor, colorScheme.errorContainer);
      expect(style.statusForegroundColor, colorScheme.onErrorContainer);
    });

    test('uses a darker neutral surface for completed matches', () {
      final style = resolveDoublesMatchVisualStyle(
        colorScheme,
        ScheduleMatchStatus.completed,
      );

      expect(style.cardBackgroundColor, colorScheme.surfaceContainerHighest);
      expect(style.statusBackgroundColor, isNot(style.cardBackgroundColor));
    });
  });

  group('completed round state', () {
    test('returns true only when every court in the round is completed', () {
      final progressByKey = <String, ScheduleMatchProgress>{
        'r1_c1': _progress(
          roundNo: 1,
          courtNo: 1,
          status: ScheduleMatchStatus.completed,
        ),
        'r1_c2': _progress(
          roundNo: 1,
          courtNo: 2,
          status: ScheduleMatchStatus.completed,
        ),
      };

      expect(
        isDoublesRoundCompleted(
          roundNo: 1,
          courtNumbers: const [1, 2],
          progressByKey: progressByKey,
        ),
        isTrue,
      );
    });

    test('returns false when a court is not completed or missing', () {
      final progressByKey = <String, ScheduleMatchProgress>{
        'r1_c1': _progress(
          roundNo: 1,
          courtNo: 1,
          status: ScheduleMatchStatus.completed,
        ),
        'r1_c2': _progress(
          roundNo: 1,
          courtNo: 2,
          status: ScheduleMatchStatus.inProgress,
        ),
      };

      expect(
        isDoublesRoundCompleted(
          roundNo: 1,
          courtNumbers: const [1, 2],
          progressByKey: progressByKey,
        ),
        isFalse,
      );
      expect(
        isDoublesRoundCompleted(
          roundNo: 1,
          courtNumbers: const [1, 2, 3],
          progressByKey: progressByKey,
        ),
        isFalse,
      );
    });
  });
}

ScheduleMatchProgress _progress({
  required int roundNo,
  required int courtNo,
  required ScheduleMatchStatus status,
}) {
  final now = DateTime.utc(2026, 8, 1);
  return ScheduleMatchProgress(
    schemaVersion: ScheduleMatchProgress.currentSchemaVersion,
    scheduleType: ScheduleProgressScheduleType.doubles,
    generatedScheduleId: 'generated-1',
    roundNo: roundNo,
    courtNo: courtNo,
    matchNo: courtNo,
    status: status,
    result: null,
    note: '',
    startedAt: status == ScheduleMatchStatus.scheduled ? null : now,
    finishedAt: status == ScheduleMatchStatus.completed ? now : null,
    createdAt: now,
    updatedAt: now,
    revision: 1,
  );
}
