import 'package:srp_lanske/features/schedule_progress/application/schedule_progress_repository.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';

class DoublesMatchProgressInput {
  const DoublesMatchProgressInput({
    required this.status,
    required this.side1Score,
    required this.side2Score,
    required this.note,
    required this.startedAt,
    required this.finishedAt,
  });

  final ScheduleMatchStatus status;
  final int? side1Score;
  final int? side2Score;
  final String note;
  final DateTime? startedAt;
  final DateTime? finishedAt;
}

class DoublesMatchProgressSaveResult {
  const DoublesMatchProgressSaveResult({
    required this.match,
    required this.summary,
  });

  final ScheduleMatchProgress match;
  final ScheduleProgressSummary summary;
}

class DoublesMatchProgressService {
  DoublesMatchProgressService({
    required ScheduleProgressRepository repository,
    DateTime Function()? clock,
  })  : _repository = repository,
        _clock = clock ?? DateTime.now;

  final ScheduleProgressRepository _repository;
  final DateTime Function() _clock;

  Future<DoublesMatchProgressSaveResult> save({
    required ScheduleProgressScope scope,
    required ScheduleMatchProgress current,
    required DoublesMatchProgressInput input,
    required int totalMatchCount,
  }) async {
    final update = buildUpdate(
      current: current,
      input: input,
      now: _clock(),
    );

    final saved = await _repository.saveMatch(
      scope: scope,
      update: update,
      totalMatchCount: totalMatchCount,
      expectedRevision: current.revision,
    );
    final summary = await _repository.findSummary(scope);
    if (summary == null) {
      throw StateError('schedule progress summary was not saved');
    }

    return DoublesMatchProgressSaveResult(
      match: saved,
      summary: summary,
    );
  }
}

ScheduleMatchProgressUpdate buildUpdate({
  required ScheduleMatchProgress current,
  required DoublesMatchProgressInput input,
  required DateTime now,
}) {
  _validateScores(input.side1Score, input.side2Score);

  DateTime? startedAt;
  DateTime? finishedAt;

  switch (input.status) {
    case ScheduleMatchStatus.scheduled:
      startedAt = null;
      finishedAt = null;
      break;
    case ScheduleMatchStatus.inProgress:
      startedAt = input.startedAt ?? current.startedAt ?? now;
      finishedAt = null;
      break;
    case ScheduleMatchStatus.completed:
      startedAt = input.startedAt ?? current.startedAt;
      finishedAt = input.finishedAt ?? current.finishedAt ?? now;
      break;
  }

  if (startedAt != null &&
      finishedAt != null &&
      finishedAt.isBefore(startedAt)) {
    throw const DoublesMatchTimeOrderException();
  }

  final hasScores = input.side1Score != null && input.side2Score != null;

  return ScheduleMatchProgressUpdate(
    roundNo: current.roundNo,
    courtNo: current.courtNo,
    matchNo: current.matchNo,
    status: input.status,
    result: hasScores
        ? ScheduleMatchResultSummary.simpleScore(<int>[
            input.side1Score!,
            input.side2Score!,
          ])
        : null,
    note: input.note.trim(),
    startedAt: startedAt,
    finishedAt: finishedAt,
  );
}

int countDoublesScheduleMatches(Map<String, dynamic>? scheduleResponse) {
  final rounds = scheduleResponse?['rounds'];
  if (rounds is! List) {
    return 0;
  }

  var count = 0;
  for (final round in rounds) {
    if (round is! Map) {
      continue;
    }
    final courts = round['courts'];
    if (courts is List) {
      count += courts.length;
    }
  }

  return count;
}

void _validateScores(int? side1Score, int? side2Score) {
  if ((side1Score == null) != (side2Score == null)) {
    throw const DoublesMatchIncompleteScoreException();
  }

  for (final score in <int?>[side1Score, side2Score]) {
    if (score != null && (score < 0 || score > 9)) {
      throw DoublesMatchScoreRangeException(score);
    }
  }
}

class DoublesMatchIncompleteScoreException implements Exception {
  const DoublesMatchIncompleteScoreException();
}

class DoublesMatchScoreRangeException implements Exception {
  const DoublesMatchScoreRangeException(this.score);

  final int score;
}

class DoublesMatchTimeOrderException implements Exception {
  const DoublesMatchTimeOrderException();
}
