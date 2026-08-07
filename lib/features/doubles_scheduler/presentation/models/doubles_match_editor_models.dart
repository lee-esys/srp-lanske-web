import 'package:srp_lanske/features/doubles_scheduler/application/doubles_match_progress_service.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';

class DoublesMatchParticipantViewModel {
  const DoublesMatchParticipantViewModel({
    required this.slotNumber,
    required this.displayName,
    this.playerId,
  });

  final int slotNumber;
  final String displayName;
  final String? playerId;
}

class DoublesMatchSelection {
  const DoublesMatchSelection({
    required this.roundNo,
    required this.courtNo,
    this.matchNo,
    required this.side1Players,
    required this.side2Players,
  });

  final int roundNo;
  final int courtNo;
  final int? matchNo;
  final List<DoublesMatchParticipantViewModel> side1Players;
  final List<DoublesMatchParticipantViewModel> side2Players;
}

DoublesMatchProgressInput buildDoublesMatchProgressInput(
  ScheduleMatchProgress progress,
) {
  final scores =
      progress.result?.type == ScheduleMatchResultSummary.simpleScoreType &&
              (progress.result?.sideScores.length ?? 0) >= 2
          ? progress.result!.sideScores
          : const <int>[];

  return DoublesMatchProgressInput(
    status: progress.status,
    side1Score: scores.length >= 2 && scores[0] <= 9 ? scores[0] : null,
    side2Score: scores.length >= 2 && scores[1] <= 9 ? scores[1] : null,
    note: progress.note,
    startedAt: progress.startedAt,
    finishedAt: progress.finishedAt,
  );
}

bool doublesMatchProgressInputsEqual(
  DoublesMatchProgressInput left,
  DoublesMatchProgressInput right,
) {
  return left.status == right.status &&
      left.side1Score == right.side1Score &&
      left.side2Score == right.side2Score &&
      left.note == right.note &&
      _dateTimesEqual(left.startedAt, right.startedAt) &&
      _dateTimesEqual(left.finishedAt, right.finishedAt);
}

bool _dateTimesEqual(DateTime? left, DateTime? right) {
  if (left == null || right == null) {
    return left == right;
  }

  return left.isAtSameMomentAs(right);
}
