import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_navigation.dart';

void main() {
  group('resolveScheduleProgressNavigation', () {
    test('selects the first scheduled match when nothing has started', () {
      final navigation = resolveScheduleProgressNavigation(
        matchKeys: [_key(2, 1), _key(1, 2), _key(1, 1)],
        progresses: const [],
      );

      expect(navigation.kind, ScheduleProgressNavigationKind.nextScheduled);
      expect(navigation.primaryMatchKey, _key(1, 1));
      expect(navigation.inProgressMatchKeys, isEmpty);
    });

    test('selects the first in-progress match in display order', () {
      final navigation = resolveScheduleProgressNavigation(
        matchKeys: [_key(1, 1), _key(1, 2), _key(2, 1)],
        progresses: [
          _progress(_key(2, 1), ScheduleMatchStatus.inProgress),
          _progress(_key(1, 2), ScheduleMatchStatus.inProgress),
        ],
      );

      expect(navigation.kind, ScheduleProgressNavigationKind.inProgress);
      expect(navigation.primaryMatchKey, _key(1, 2));
      expect(
        navigation.inProgressMatchKeys,
        [_key(1, 2), _key(2, 1)],
      );
    });

    test('prefers later in-progress match over earlier scheduled match', () {
      final navigation = resolveScheduleProgressNavigation(
        matchKeys: [_key(1, 1), _key(1, 2), _key(2, 1)],
        progresses: [
          _progress(_key(2, 1), ScheduleMatchStatus.inProgress),
        ],
      );

      expect(navigation.kind, ScheduleProgressNavigationKind.inProgress);
      expect(navigation.primaryMatchKey, _key(2, 1));
    });

    test('returns to the first scheduled match after a skipped-ahead match ends', () {
      final navigation = resolveScheduleProgressNavigation(
        matchKeys: [_key(1, 1), _key(1, 2), _key(2, 1)],
        progresses: [
          _progress(_key(2, 1), ScheduleMatchStatus.completed),
        ],
      );

      expect(navigation.kind, ScheduleProgressNavigationKind.nextScheduled);
      expect(navigation.primaryMatchKey, _key(1, 1));
    });

    test('treats missing progress documents as scheduled', () {
      final navigation = resolveScheduleProgressNavigation(
        matchKeys: [_key(1, 1), _key(1, 2)],
        progresses: [
          _progress(_key(1, 1), ScheduleMatchStatus.completed),
        ],
      );

      expect(navigation.kind, ScheduleProgressNavigationKind.nextScheduled);
      expect(navigation.primaryMatchKey, _key(1, 2));
    });

    test('ignores progress records outside the displayed schedule', () {
      final navigation = resolveScheduleProgressNavigation(
        matchKeys: [_key(1, 1)],
        progresses: [
          _progress(_key(9, 9), ScheduleMatchStatus.inProgress),
        ],
      );

      expect(navigation.kind, ScheduleProgressNavigationKind.nextScheduled);
      expect(navigation.primaryMatchKey, _key(1, 1));
    });

    test('reports completed when every displayed match is completed', () {
      final navigation = resolveScheduleProgressNavigation(
        matchKeys: [_key(1, 1), _key(1, 2)],
        progresses: [
          _progress(_key(1, 1), ScheduleMatchStatus.completed),
          _progress(_key(1, 2), ScheduleMatchStatus.completed),
        ],
      );

      expect(navigation.kind, ScheduleProgressNavigationKind.completed);
      expect(navigation.primaryMatchKey, isNull);
      expect(navigation.inProgressMatchKeys, isEmpty);
    });

    test('reports completed for an empty schedule', () {
      final navigation = resolveScheduleProgressNavigation(
        matchKeys: const [],
        progresses: const [],
      );

      expect(navigation.kind, ScheduleProgressNavigationKind.completed);
      expect(navigation.primaryMatchKey, isNull);
    });
  });
}

ScheduleMatchKey _key(int roundNo, int courtNo) {
  return ScheduleMatchKey(roundNo: roundNo, courtNo: courtNo);
}

ScheduleMatchProgress _progress(
  ScheduleMatchKey key,
  ScheduleMatchStatus status,
) {
  final now = DateTime.utc(2026, 8, 10, 1);
  return ScheduleMatchProgress(
    schemaVersion: ScheduleMatchProgress.currentSchemaVersion,
    scheduleType: ScheduleProgressScheduleType.doubles,
    generatedScheduleId: 'generated-1',
    roundNo: key.roundNo,
    courtNo: key.courtNo,
    matchNo: null,
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
