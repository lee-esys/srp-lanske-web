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

    // Confirmed entries can be interspersed with legacy and draft records.
    // Page through the date-ordered projection instead of filtering a single
    // limited page, which could hide older confirmed participation.
    final collection = _firestore
        .collection('externalIdentityParticipationHistories')
        .doc(mappingId)
        .collection('events');
    final entries = <ParticipationHistoryEntry>[];
    QueryDocumentSnapshot<Map<String, dynamic>>? cursor;
    while (entries.length < limit) {
      var query =
          collection.orderBy('eventDate', descending: true).limit(limit);
      if (cursor != null) {
        query = query.startAfterDocument(cursor);
      }
      final snapshot = await query.get();
      for (final document in snapshot.docs) {
        final entry = parseParticipationHistoryEntry(
          eventId: document.id,
          mappingId: mappingId,
          data: document.data(),
        );
        if (entry.isConfirmed) {
          entries.add(entry);
          if (entries.length >= limit) break;
        }
      }
      if (snapshot.docs.length < limit) break;
      cursor = snapshot.docs.last;
    }
    return List<ParticipationHistoryEntry>.unmodifiable(entries);
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
    'isConfirmed',
    'participantCount',
    'updatedAt',
  };
  if (data.keys.any((key) => !fields.contains(key)) ||
      data['schemaVersion'] != 1 ||
      data['eventId'] != eventId ||
      data['statisticsEligible'] is! bool ||
      (data.containsKey('isConfirmed') && data['isConfirmed'] is! bool) ||
      (data.containsKey('participantCount') &&
          (data['participantCount'] is! int || data['participantCount'] < 1)) ||
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
        (rawSnapshot['levelId'] != null && rawSnapshot['levelId'] is! int) ||
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
    isConfirmed: data['isConfirmed'] as bool? ?? false,
    participantCount: data['participantCount'] as int?,
    updatedAt: (data['updatedAt'] as Timestamp).toDate().toUtc(),
  );
}
