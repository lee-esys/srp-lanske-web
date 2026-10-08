import 'package:cloud_firestore/cloud_firestore.dart';

import '../application/participation_history_repository.dart';
import '../domain/participation_history_entry.dart';

/// Reads a trusted, privacy-safe projection; never reads events/{publicId}.
class FirestoreParticipationHistoryRepository
    implements ParticipationHistoryRepository {
  FirestoreParticipationHistoryRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<List<ParticipationHistoryEntry>> listByMappingId({
    required String mappingId,
    int limit = 20,
  }) async {
    if (!RegExp(r'^[a-z][a-z0-9]*_[0-9]{1,20}$').hasMatch(mappingId)) {
      throw ArgumentError.value(mappingId, 'mappingId', 'invalid identity key');
    }
    if (limit < 1 || limit > 100) {
      throw RangeError.range(limit, 1, 100, 'limit');
    }

    final snapshot = await _firestore
        .collection('externalIdentityParticipationHistories')
        .doc(mappingId)
        .collection('events')
        .orderBy('eventDate', descending: true)
        .limit(limit)
        .get();

    return List<ParticipationHistoryEntry>.unmodifiable(
      snapshot.docs.map((document) => parseParticipationHistoryEntry(
            eventId: document.id,
            mappingId: mappingId,
            data: document.data(),
          )),
    );
  }
}

/// Strict parsing ensures a broken projector cannot accidentally leak a raw
/// event payload through the client-side domain model.
ParticipationHistoryEntry parseParticipationHistoryEntry({
  required String eventId,
  required String mappingId,
  required Map<String, dynamic> data,
}) {
  const fields = {
    'schemaVersion',
    'eventId',
    'sourceType',
    'sourceUserId',
    'eventDate',
    'selfSnapshot',
    'statisticsEligible',
    'updatedAt',
  };
  if (data.keys.any((key) => !fields.contains(key)) ||
      data['schemaVersion'] != 1 ||
      data['eventId'] != eventId ||
      data['statisticsEligible'] is! bool ||
      data['updatedAt'] is! Timestamp) {
    throw const FormatException('Invalid participation projection');
  }

  final sourceType = data['sourceType'];
  final sourceUserId = data['sourceUserId'];
  if (sourceType is! String ||
      sourceUserId is! String ||
      '${sourceType}_$sourceUserId' != mappingId) {
    throw const FormatException('Invalid participation identity');
  }

  final rawDate = data['eventDate'];
  if (rawDate != null && rawDate is! Timestamp) {
    throw const FormatException('Invalid participation event date');
  }

  final rawSnapshot = data['selfSnapshot'];
  ParticipationSelfSnapshot? selfSnapshot;
  if (rawSnapshot != null) {
    if (rawSnapshot is! Map ||
        rawSnapshot.keys.any((key) => !{
              'sourceDisplayName',
              'levelId',
              'levelName',
              'observedAt',
            }.contains(key)) ||
        rawSnapshot['sourceDisplayName'] is! String ||
        (rawSnapshot['levelId'] != null &&
            rawSnapshot['levelId'] is! int) ||
        (rawSnapshot['levelName'] != null &&
            rawSnapshot['levelName'] is! String) ||
        (rawSnapshot['observedAt'] != null &&
            rawSnapshot['observedAt'] is! Timestamp)) {
      throw const FormatException('Invalid participation self snapshot');
    }
    selfSnapshot = ParticipationSelfSnapshot(
      sourceDisplayName: rawSnapshot['sourceDisplayName'] as String,
      levelId: rawSnapshot['levelId'] as int?,
      levelName: rawSnapshot['levelName'] as String?,
      observedAt: (rawSnapshot['observedAt'] as Timestamp?)?.toDate().toUtc(),
    );
  }

  return ParticipationHistoryEntry(
    eventId: eventId,
    sourceType: sourceType,
    sourceUserId: sourceUserId,
    eventDate: (rawDate as Timestamp?)?.toDate().toUtc(),
    selfSnapshot: selfSnapshot,
    statisticsEligible: data['statisticsEligible'] as bool,
    updatedAt: (data['updatedAt'] as Timestamp).toDate().toUtc(),
  );
}
