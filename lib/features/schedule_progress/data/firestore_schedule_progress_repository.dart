import 'package:cloud_firestore/cloud_firestore.dart';

import '../application/schedule_progress_repository.dart';
import '../domain/schedule_progress_models.dart';

class FirestoreScheduleProgressRepository
    implements ScheduleProgressRepository {
  FirestoreScheduleProgressRepository({
    FirebaseFirestore? firestore,
    DateTime Function()? clock,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _clock = clock ?? DateTime.now;

  final FirebaseFirestore _firestore;
  final DateTime Function() _clock;

  @override
  Future<ScheduleProgressSummary> ensureSummary({
    required ScheduleProgressScope scope,
    required int totalMatchCount,
  }) async {
    _validateTotalMatchCount(totalMatchCount);

    final progressReference = _progressDocument(scope);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(progressReference);
      final data = snapshot.data();
      if (snapshot.exists && data != null) {
        final current = ScheduleProgressSummary.fromJson(data);
        _ensureTotalMatchCount(
          summary: current,
          totalMatchCount: totalMatchCount,
        );
        return current;
      }

      final now = _clock();
      final summary = ScheduleProgressSummary(
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
      transaction.set(progressReference, summary.toJson());
      return summary;
    });
  }

  @override
  Future<ScheduleProgressSummary?> findSummary(
    ScheduleProgressScope scope,
  ) async {
    final snapshot = await _progressDocument(scope).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return null;
    }

    return ScheduleProgressSummary.fromJson(data);
  }

  @override
  Future<List<ScheduleMatchProgress>> listMatches(
    ScheduleProgressScope scope,
  ) async {
    final snapshot = await _matchesCollection(scope).get();
    final matches = snapshot.docs
        .map((document) => ScheduleMatchProgress.fromJson(document.data()))
        .toList();
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
    final snapshot = await _matchesCollection(scope).doc(key.value).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      return ScheduleMatchProgress.scheduledPlaceholder(
        scope: scope,
        roundNo: roundNo,
        courtNo: courtNo,
        matchNo: matchNo,
      );
    }

    return ScheduleMatchProgress.fromJson(data);
  }

  @override
  Future<ScheduleMatchProgress> saveMatch({
    required ScheduleProgressScope scope,
    required ScheduleMatchProgressUpdate update,
    required int totalMatchCount,
    required int expectedRevision,
  }) async {
    _validateSaveArguments(
      totalMatchCount: totalMatchCount,
      expectedRevision: expectedRevision,
    );

    final progressReference = _progressDocument(scope);
    final matchReference = _matchesCollection(scope).doc(update.key.value);

    return _firestore.runTransaction((transaction) async {
      final matchSnapshot = await transaction.get(matchReference);
      final progressSnapshot = await transaction.get(progressReference);

      final currentMatchData = matchSnapshot.data();
      final currentMatch = matchSnapshot.exists && currentMatchData != null
          ? ScheduleMatchProgress.fromJson(currentMatchData)
          : null;
      final actualRevision = currentMatch?.revision ?? 0;
      if (actualRevision != expectedRevision) {
        throw ScheduleProgressConflictException(
          matchKey: update.key,
          expectedRevision: expectedRevision,
          actualRevision: actualRevision,
        );
      }

      final currentSummaryData = progressSnapshot.data();
      final currentSummary =
          progressSnapshot.exists && currentSummaryData != null
              ? ScheduleProgressSummary.fromJson(currentSummaryData)
              : null;
      _ensureTotalMatchCount(
        summary: currentSummary,
        totalMatchCount: totalMatchCount,
      );

      final now = _clock();
      final nextMatch = ScheduleMatchProgress(
        schemaVersion: ScheduleMatchProgress.currentSchemaVersion,
        scheduleType: scope.scheduleType,
        generatedScheduleId: scope.generatedScheduleId,
        roundNo: update.roundNo,
        courtNo: update.courtNo,
        matchNo: update.matchNo ?? currentMatch?.matchNo,
        status: update.status,
        result: update.result,
        note: update.note,
        startedAt: update.startedAt,
        finishedAt: update.finishedAt,
        createdAt: currentMatch?.createdAt ?? now,
        updatedAt: now,
        revision: actualRevision + 1,
      );
      final nextSummary = _buildNextSummary(
        scope: scope,
        currentSummary: currentSummary,
        previousStatus:
            currentMatch?.status ?? ScheduleMatchStatus.scheduled,
        nextStatus: nextMatch.status,
        totalMatchCount: totalMatchCount,
        now: now,
      );

      transaction.set(matchReference, nextMatch.toJson());
      transaction.set(progressReference, nextSummary.toJson());

      return nextMatch;
    });
  }

  DocumentReference<Map<String, dynamic>> _progressDocument(
    ScheduleProgressScope scope,
  ) {
    return _firestore
        .collection(_rootCollectionPath(scope.scheduleType))
        .doc(scope.shareId)
        .collection('schedule_progress')
        .doc(scope.generatedScheduleId);
  }

  CollectionReference<Map<String, dynamic>> _matchesCollection(
    ScheduleProgressScope scope,
  ) {
    return _progressDocument(scope).collection('matches');
  }
}

String _rootCollectionPath(ScheduleProgressScheduleType scheduleType) {
  switch (scheduleType) {
    case ScheduleProgressScheduleType.doubles:
      return 'events';
    case ScheduleProgressScheduleType.team:
      return 'team_schedules';
  }
}

void _validateTotalMatchCount(int totalMatchCount) {
  if (totalMatchCount <= 0) {
    throw ArgumentError.value(
      totalMatchCount,
      'totalMatchCount',
      'must be positive',
    );
  }
}

void _validateSaveArguments({
  required int totalMatchCount,
  required int expectedRevision,
}) {
  _validateTotalMatchCount(totalMatchCount);
  if (expectedRevision < 0) {
    throw ArgumentError.value(
      expectedRevision,
      'expectedRevision',
      'must not be negative',
    );
  }
}

void _ensureTotalMatchCount({
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

ScheduleProgressSummary _buildNextSummary({
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
