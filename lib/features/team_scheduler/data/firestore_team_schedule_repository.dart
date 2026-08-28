import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/public_id.dart';
import 'package:srp_lanske/shared/infrastructure/firestore_provenance.dart';

import '../application/team_schedule_repository.dart';
import '../domain/saved_team_schedule.dart';
import '../domain/team_generated_schedule.dart';
import '../presentation/models/team_setup_draft.dart';

class FirestoreTeamScheduleRepository implements TeamScheduleRepository {
  FirestoreTeamScheduleRepository({
    FirebaseFirestore? firestore,
    String collectionPath = 'team_schedules',
    String Function()? shareIdGenerator,
    FirestoreWriteOrigin Function()? writeOriginProvider,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _collectionPath = collectionPath,
        _shareIdGenerator = shareIdGenerator ?? generatePublicId,
        _writeOriginProvider = writeOriginProvider;

  final FirebaseFirestore _firestore;
  final String _collectionPath;
  final String Function() _shareIdGenerator;
  final FirestoreWriteOrigin Function()? _writeOriginProvider;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection(_collectionPath);
  }

  @override
  Future<SavedTeamSchedule> createFromGenerated({
    required TeamSetupDraft draft,
    required TeamGeneratedSchedule generated,
    required String eventTitle,
    required Map<int, String> teamNames,
    required Map<int, String> memberNames,
  }) async {
    final now = DateTime.now();
    final shareId = await _generateUniqueShareId();

    final saved = SavedTeamSchedule(
      schemaVersion: SavedTeamSchedule.currentSchemaVersion,
      shareId: shareId,
      status: 'active',
      scheduleType: SavedTeamSchedule.teamScheduleType,
      createdAt: now,
      updatedAt: now,
      setup: SavedTeamScheduleSetup(
        concurrentMatchCount: draft.concurrentMatchCount,
        participantCount: draft.participantCount,
        preferredTeamSize: draft.preferredTeamSize,
        teamsPerMatch: draft.teamsPerMatch,
        roundCount: generated.roundCount,
      ),
      display: SavedTeamScheduleDisplay(
        eventTitle: eventTitle,
        teamNames: Map<int, String>.unmodifiable(teamNames),
        memberNames: Map<int, String>.unmodifiable(memberNames),
      ),
      snapshot: generated.rawJson,
      scores: const <String, dynamic>{},
    );

    final stored = withCreatedFirestoreProvenance(
      data: saved.toJson(),
      origin: _currentWriteOrigin(),
    );
    await _collection.doc(shareId).set(stored);

    return saved;
  }

  @override
  Future<SavedTeamSchedule?> findByShareId(String shareId) async {
    final snapshot = await _collection.doc(shareId).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return SavedTeamSchedule.fromJson(data);
  }

  @override
  Future<SavedTeamSchedule> updateDisplay({
    required String shareId,
    required SavedTeamScheduleDisplay display,
  }) async {
    final currentData = await _readExistingData(shareId);
    final current = SavedTeamSchedule.fromJson(currentData);

    final updated = current.copyWith(
      display: display,
      updatedAt: DateTime.now(),
    );

    await _writeUpdated(
      shareId: shareId,
      data: updated.toJson(),
      currentProvenance: currentData['provenance'],
    );

    return updated;
  }

  @override
  Future<SavedTeamSchedule> updateScores({
    required String shareId,
    required Map<String, dynamic> scores,
  }) async {
    final currentData = await _readExistingData(shareId);
    final current = SavedTeamSchedule.fromJson(currentData);

    final updated = current.copyWith(
      scores: Map<String, dynamic>.unmodifiable(scores),
      updatedAt: DateTime.now(),
    );

    await _writeUpdated(
      shareId: shareId,
      data: updated.toJson(),
      currentProvenance: currentData['provenance'],
    );

    return updated;
  }

  Future<Map<String, dynamic>> _readExistingData(String shareId) async {
    final snapshot = await _collection.doc(shareId).get();
    final data = snapshot.data();
    if (!snapshot.exists || data == null) {
      throw StateError('team schedule not found: $shareId');
    }
    return data;
  }

  Future<void> _writeUpdated({
    required String shareId,
    required Map<String, dynamic> data,
    required Object? currentProvenance,
  }) async {
    final stored = withUpdatedFirestoreProvenance(
      data: data,
      currentProvenance: currentProvenance,
      origin: _currentWriteOrigin(),
    );
    await _collection.doc(shareId).set(stored);
  }

  FirestoreWriteOrigin _currentWriteOrigin() {
    return _writeOriginProvider?.call() ??
        FirestoreWriteOrigin.current(
          firebaseProjectId: _firestore.app.options.projectId,
        );
  }

  Future<String> _generateUniqueShareId() async {
    for (var attempt = 0; attempt < 10; attempt += 1) {
      final candidate = _shareIdGenerator();

      if (!isValidPublicId(candidate)) {
        throw StateError('invalid share_id generated: $candidate');
      }

      final existing = await _collection.doc(candidate).get();
      if (!existing.exists) {
        return candidate;
      }
    }

    throw StateError('failed to generate unique share_id');
  }
}
