import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/doubles_match_progress_service.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/models/doubles_match_editor_models.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';

void main() {
  test('builds an editor input from saved match progress', () {
    final startedAt = DateTime(2026, 8, 6, 9, 15);
    final finishedAt = DateTime(2026, 8, 6, 9, 28);
    final progress = _progress(
      status: ScheduleMatchStatus.completed,
      scores: const <int>[4, 2],
      note: 'saved note',
      startedAt: startedAt,
      finishedAt: finishedAt,
    );

    final input = buildDoublesMatchProgressInput(progress);

    expect(input.status, ScheduleMatchStatus.completed);
    expect(input.side1Score, 4);
    expect(input.side2Score, 2);
    expect(input.note, 'saved note');
    expect(input.startedAt, startedAt);
    expect(input.finishedAt, finishedAt);
  });

  test('compares all draft fields with the saved baseline', () {
    final startedAt = DateTime.utc(2026, 8, 6, 0, 15);
    final baseline = DoublesMatchProgressInput(
      status: ScheduleMatchStatus.inProgress,
      side1Score: 2,
      side2Score: 1,
      note: 'note',
      startedAt: startedAt,
      finishedAt: null,
    );
    final sameInstant = DoublesMatchProgressInput(
      status: ScheduleMatchStatus.inProgress,
      side1Score: 2,
      side2Score: 1,
      note: 'note',
      startedAt: startedAt.toLocal(),
      finishedAt: null,
    );
    final changed = DoublesMatchProgressInput(
      status: ScheduleMatchStatus.inProgress,
      side1Score: 2,
      side2Score: 1,
      note: 'changed',
      startedAt: startedAt.toLocal(),
      finishedAt: null,
    );

    expect(doublesMatchProgressInputsEqual(baseline, sameInstant), isTrue);
    expect(doublesMatchProgressInputsEqual(baseline, changed), isFalse);
  });
}

ScheduleMatchProgress _progress({
  required ScheduleMatchStatus status,
  required List<int>? scores,
  required String note,
  required DateTime? startedAt,
  required DateTime? finishedAt,
}) {
  final now = DateTime(2026, 8, 6, 9, 30);
  return ScheduleMatchProgress(
    schemaVersion: ScheduleMatchProgress.currentSchemaVersion,
    scheduleType: ScheduleProgressScheduleType.doubles,
    generatedScheduleId: 'generated-1',
    roundNo: 1,
    courtNo: 1,
    matchNo: 1,
    status: status,
    result:
        scores == null ? null : ScheduleMatchResultSummary.simpleScore(scores),
    note: note,
    startedAt: startedAt,
    finishedAt: finishedAt,
    createdAt: now,
    updatedAt: now,
    revision: 1,
  );
}
