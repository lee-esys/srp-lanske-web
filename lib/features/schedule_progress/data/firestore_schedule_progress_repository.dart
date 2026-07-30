import 'package:cloud_firestore/cloud_firestore.dart';

import '../application/schedule_progress_repository.dart';
import '../domain/schedule_progress_models.dart';
import '../domain/schedule_progress_transition.dart';

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
    validateScheduleProgressTotalMatchCount(totalMatchCount);

    final progressReference = _progressDocument(scope);
    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(progressReference);
      final data = snapshot.data();
      if (snapshot.exists && data != null) {
        final current = ScheduleProgressSummary.fromJson(data);
        ensureScheduleProgressTotalMatchCount(
          summary: current,
          totalMatchCount: totalMatchCount,
        );
        return current;
      }

      final summary = createInitialScheduleProgressSummary(
        scope: scope,
        totalMatchCount: totalMatchCount,
        now: _clock(),
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
    validateScheduleProgressSaveArguments(
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
      ensureScheduleProgressTotalMatchCount(
        summary: currentSummary,
        totalMatchCount: totalMatchCount,
      );

      final now = _clock();
      final nextMatch = buildSavedScheduleMatchProgress(
        scope: scope,
        update: update,
        current: currentMatch,
        now: now,
      );
      final nextSummary = buildUpdatedScheduleProgressSummary(
        scope: scope,
        currentSummary: currentSummary,
        previousStatus: currentMatch?.status ?? ScheduleMatchStatus.scheduled,
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
