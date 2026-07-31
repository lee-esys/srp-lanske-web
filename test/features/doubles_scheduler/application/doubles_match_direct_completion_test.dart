import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/doubles_match_progress_service.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';

void main() {
  test('direct completion sets the same start and finish time', () {
    final now = DateTime(2026, 7, 31, 15, 41);

    final update = buildUpdate(
      current: _scheduledMatch(),
      input: const DoublesMatchProgressInput(
        status: ScheduleMatchStatus.completed,
        side1Score: null,
        side2Score: null,
        note: '',
        startedAt: null,
        finishedAt: null,
      ),
      now: now,
    );

    expect(update.startedAt, now);
    expect(update.finishedAt, now);
  });

  test('equal entered start and finish times are accepted', () {
    final time = DateTime(2026, 7, 31, 15, 41);

    final update = buildUpdate(
      current: _scheduledMatch(),
      input: DoublesMatchProgressInput(
        status: ScheduleMatchStatus.completed,
        side1Score: null,
        side2Score: null,
        note: '',
        startedAt: time,
        finishedAt: time,
      ),
      now: time,
    );

    expect(update.startedAt, time);
    expect(update.finishedAt, time);
  });
}

ScheduleMatchProgress _scheduledMatch() {
  final now = DateTime.utc(2026, 7, 31, 1);
  return ScheduleMatchProgress(
    schemaVersion: ScheduleMatchProgress.currentSchemaVersion,
    scheduleType: ScheduleProgressScheduleType.doubles,
    generatedScheduleId: 'generated-1',
    roundNo: 1,
    courtNo: 1,
    matchNo: null,
    status: ScheduleMatchStatus.scheduled,
    result: null,
    note: '',
    startedAt: null,
    finishedAt: null,
    createdAt: now,
    updatedAt: now,
    revision: 0,
  );
}
