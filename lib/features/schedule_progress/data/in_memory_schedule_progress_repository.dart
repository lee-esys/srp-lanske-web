import '../application/schedule_progress_repository.dart';
import '../domain/schedule_progress_models.dart';
import '../domain/schedule_progress_transition.dart';

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
    validateScheduleProgressTotalMatchCount(totalMatchCount);

    final current = _summaries[scope.storageKey];
    ensureScheduleProgressTotalMatchCount(
      summary: current,
      totalMatchCount: totalMatchCount,
    );
    if (current != null) {
      return current;
    }

    final summary = createInitialScheduleProgressSummary(
      scope: scope,
      totalMatchCount: totalMatchCount,
      now: _clock(),
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
    validateScheduleProgressSaveArguments(
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
    ensureScheduleProgressTotalMatchCount(
      summary: currentSummary,
      totalMatchCount: totalMatchCount,
    );

    final now = _clock();
    final nextMatch = buildSavedScheduleMatchProgress(
      scope: scope,
      update: update,
      current: current,
      now: now,
    );
    final nextSummary = buildUpdatedScheduleProgressSummary(
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
