import 'package:cloud_firestore/cloud_firestore.dart';

import '../application/event_ownership_transfer_repository.dart';

class FirestoreEventOwnershipTransferRepository
    implements EventOwnershipTransferRepository {
  FirestoreEventOwnershipTransferRepository(
    this._firestore, {
    String collectionPath = 'eventOwnershipTransfers',
  }) : _collectionPath = collectionPath;

  final FirebaseFirestore _firestore;
  final String _collectionPath;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection(_collectionPath);
  }

  @override
  Future<void> prepare({
    required String sourceUid,
    required String handoffSecret,
    required DateTime expiresAt,
  }) {
    return _collection.doc(sourceUid).set(<String, dynamic>{
      'schemaVersion': 1,
      'sourceUid': sourceUid,
      'handoffSecret': handoffSecret,
      'state': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
      'expiresAt': Timestamp.fromDate(expiresAt.toUtc()),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> accept({
    required String sourceUid,
    required String handoffSecret,
    required String targetUid,
    required DateTime acceptedExpiresAt,
  }) {
    return _collection.doc(sourceUid).update(<String, dynamic>{
      'state': 'accepted',
      'targetUid': targetUid,
      'handoffSecretProof': handoffSecret,
      'acceptedAt': FieldValue.serverTimestamp(),
      'acceptedExpiresAt': Timestamp.fromDate(acceptedExpiresAt.toUtc()),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> complete({
    required String sourceUid,
    required String targetUid,
  }) {
    return _collection.doc(sourceUid).update(<String, dynamic>{
      'state': 'completed',
      'targetUid': targetUid,
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
