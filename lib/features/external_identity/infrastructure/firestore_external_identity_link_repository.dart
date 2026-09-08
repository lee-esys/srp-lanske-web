import 'package:cloud_firestore/cloud_firestore.dart';

import '../application/external_identity_link_exception.dart';
import '../application/external_identity_link_repository.dart';
import '../domain/external_identity.dart';
import '../domain/external_identity_link_request.dart';

class FirestoreExternalIdentityLinkRepository
    implements ExternalIdentityLinkRepository {
  FirestoreExternalIdentityLinkRepository(this._firestore);

  static const _requestsCollection = 'externalIdentityLinkRequests';
  static const _requestLocksCollection = 'externalIdentityLinkRequestLocks';
  static const _requestAuditsCollection = 'externalIdentityLinkRequestAudits';
  static const _mappingsCollection = 'externalIdentityMappings';
  static const _usersCollection = 'users';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection(_requestsCollection);

  CollectionReference<Map<String, dynamic>> get _requestLocks =>
      _firestore.collection(_requestLocksCollection);

  CollectionReference<Map<String, dynamic>> get _requestAudits =>
      _firestore.collection(_requestAuditsCollection);

  CollectionReference<Map<String, dynamic>> get _mappings =>
      _firestore.collection(_mappingsCollection);

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection(_usersCollection);

  @override
  Future<ExternalIdentityLinkRequest?> getActiveRequest({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
  }) async {
    final lockSnapshot =
        await _requestLocks.doc(_requestLockId(lanskeUserId, sourceType)).get();
    if (!lockSnapshot.exists) {
      return null;
    }

    final lockData = lockSnapshot.data();
    final requestId = lockData?['requestId'];
    if (requestId is! String || requestId.isEmpty) {
      throw const ExternalIdentityLinkException(
        ExternalIdentityLinkFailureCode.conflict,
        message: 'Invalid external identity request lock.',
      );
    }

    final requestSnapshot = await _requests.doc(requestId).get();
    if (!requestSnapshot.exists) {
      throw const ExternalIdentityLinkException(
        ExternalIdentityLinkFailureCode.conflict,
        message: 'Active request lock points to a missing request.',
      );
    }
    return _requestFromSnapshot(requestSnapshot);
  }

  @override
  Future<ExternalIdentityLinkRequest> createRequest({
    required String lanskeUserId,
    required ExternalIdentity identity,
    required String confirmationCodeHash,
    required DateTime confirmationCodeExpiresAt,
  }) async {
    final requestRef = _requests.doc();
    final lockRef = _requestLocks.doc(
      _requestLockId(lanskeUserId, identity.sourceType),
    );
    final userRef = _users.doc(lanskeUserId);

    try {
      await _firestore.runTransaction<void>((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        final lockSnapshot = await transaction.get(lockRef);

        if (!userSnapshot.exists) {
          throw const ExternalIdentityLinkException(
            ExternalIdentityLinkFailureCode.userNotFound,
          );
        }
        if (lockSnapshot.exists) {
          throw const ExternalIdentityLinkException(
            ExternalIdentityLinkFailureCode.requestAlreadyExists,
          );
        }
        if (_hasSourceMapping(userSnapshot.data(), identity.sourceType)) {
          throw const ExternalIdentityLinkException(
            ExternalIdentityLinkFailureCode.sourceAlreadyLinked,
          );
        }

        transaction.set(
          requestRef,
          _newRequestData(
            lanskeUserId: lanskeUserId,
            identity: identity,
            confirmationCodeHash: confirmationCodeHash,
            confirmationCodeExpiresAt: confirmationCodeExpiresAt,
          ),
        );
        transaction.set(lockRef, <String, Object?>{
          'schemaVersion': 1,
          'lanskeUserId': lanskeUserId,
          'sourceType': identity.sourceType.value,
          'requestId': requestRef.id,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (error) {
      _throwPrivacySafeWriteError(error);
    }

    return _loadRequest(requestRef);
  }

  @override
  Future<ExternalIdentityLinkRequest> reissueRequest({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
    required String confirmationCodeHash,
    required DateTime confirmationCodeExpiresAt,
  }) async {
    final lockRef = _requestLocks.doc(
      _requestLockId(lanskeUserId, sourceType),
    );
    final userRef = _users.doc(lanskeUserId);
    final newRequestRef = _requests.doc();

    try {
      await _firestore.runTransaction<void>((transaction) async {
        final userSnapshot = await transaction.get(userRef);
        final lockSnapshot = await transaction.get(lockRef);
        if (!userSnapshot.exists) {
          throw const ExternalIdentityLinkException(
            ExternalIdentityLinkFailureCode.userNotFound,
          );
        }
        if (!lockSnapshot.exists) {
          throw const ExternalIdentityLinkException(
            ExternalIdentityLinkFailureCode.requestNotFound,
          );
        }

        final oldRequestId = lockSnapshot.data()?['requestId'];
        if (oldRequestId is! String || oldRequestId.isEmpty) {
          throw const ExternalIdentityLinkException(
            ExternalIdentityLinkFailureCode.conflict,
          );
        }

        final oldRequestRef = _requests.doc(oldRequestId);
        final oldRequestSnapshot = await transaction.get(oldRequestRef);
        if (!oldRequestSnapshot.exists) {
          throw const ExternalIdentityLinkException(
            ExternalIdentityLinkFailureCode.conflict,
          );
        }
        final oldRequest = _requestFromSnapshot(oldRequestSnapshot);

        if (oldRequest.lanskeUserId != lanskeUserId ||
            oldRequest.identity.sourceType != sourceType ||
            oldRequest.state != ExternalIdentityLinkRequestState.pending) {
          throw const ExternalIdentityLinkException(
            ExternalIdentityLinkFailureCode.invalidState,
          );
        }
        if (_hasSourceMapping(userSnapshot.data(), sourceType)) {
          throw const ExternalIdentityLinkException(
            ExternalIdentityLinkFailureCode.sourceAlreadyLinked,
          );
        }

        transaction.set(
          newRequestRef,
          _newRequestData(
            lanskeUserId: lanskeUserId,
            identity: oldRequest.identity,
            confirmationCodeHash: confirmationCodeHash,
            confirmationCodeExpiresAt: confirmationCodeExpiresAt,
          ),
        );
        transaction.update(oldRequestRef, <String, Object?>{
          'state': ExternalIdentityLinkRequestState.superseded.value,
          'supersededByRequestId': newRequestRef.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.update(lockRef, <String, Object?>{
          'requestId': newRequestRef.id,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } on FirebaseException catch (error) {
      _throwPrivacySafeWriteError(error);
    }

    return _loadRequest(newRequestRef);
  }

  @override
  Future<void> cancelRequest({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
  }) async {
    final lockRef = _requestLocks.doc(
      _requestLockId(lanskeUserId, sourceType),
    );

    await _firestore.runTransaction<void>((transaction) async {
      final lockSnapshot = await transaction.get(lockRef);
      if (!lockSnapshot.exists) {
        throw const ExternalIdentityLinkException(
          ExternalIdentityLinkFailureCode.requestNotFound,
        );
      }
      final requestId = lockSnapshot.data()?['requestId'];
      if (requestId is! String || requestId.isEmpty) {
        throw const ExternalIdentityLinkException(
          ExternalIdentityLinkFailureCode.conflict,
        );
      }

      final requestRef = _requests.doc(requestId);
      final requestSnapshot = await transaction.get(requestRef);
      if (!requestSnapshot.exists) {
        throw const ExternalIdentityLinkException(
          ExternalIdentityLinkFailureCode.conflict,
        );
      }
      final request = _requestFromSnapshot(requestSnapshot);
      if (request.lanskeUserId != lanskeUserId ||
          request.identity.sourceType != sourceType ||
          request.state != ExternalIdentityLinkRequestState.pending) {
        throw const ExternalIdentityLinkException(
          ExternalIdentityLinkFailureCode.invalidState,
        );
      }

      transaction.update(requestRef, <String, Object?>{
        'state': ExternalIdentityLinkRequestState.canceled.value,
        'canceledAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.delete(lockRef);
    });
  }

  @override
  Future<ExternalIdentityLinkRequest?> findRequestByConfirmationCodeHash(
    String confirmationCodeHash,
  ) async {
    final snapshot = await _requests
        .where('confirmationCodeHash', isEqualTo: confirmationCodeHash)
        .limit(2)
        .get();
    if (snapshot.docs.isEmpty) {
      return null;
    }
    if (snapshot.docs.length != 1) {
      throw const ExternalIdentityLinkException(
        ExternalIdentityLinkFailureCode.conflict,
        message: 'Confirmation code hash is not unique.',
      );
    }
    return _requestFromSnapshot(snapshot.docs.single);
  }

  @override
  Future<ExternalIdentityMapping> approveRequest({
    required String requestId,
    required String expectedConfirmationCodeHash,
    required String approvedBy,
    required DateTime now,
  }) async {
    final requestRef = _requests.doc(requestId);
    final auditRef = _requestAudits.doc(requestId);
    late DocumentReference<Map<String, dynamic>> mappingRef;

    await _firestore.runTransaction<void>((transaction) async {
      final requestSnapshot = await transaction.get(requestRef);
      if (!requestSnapshot.exists) {
        throw const ExternalIdentityLinkException(
          ExternalIdentityLinkFailureCode.requestNotFound,
        );
      }
      final request = _requestFromSnapshot(requestSnapshot);
      final userRef = _users.doc(request.lanskeUserId);
      final lockRef = _requestLocks.doc(
        _requestLockId(request.lanskeUserId, request.identity.sourceType),
      );
      mappingRef = _mappings.doc(request.identity.mappingId);

      final userSnapshot = await transaction.get(userRef);
      final lockSnapshot = await transaction.get(lockRef);
      final mappingSnapshot = await transaction.get(mappingRef);
      final auditSnapshot = await transaction.get(auditRef);

      if (request.state != ExternalIdentityLinkRequestState.pending ||
          request.confirmationCodeHash != expectedConfirmationCodeHash) {
        throw const ExternalIdentityLinkException(
          ExternalIdentityLinkFailureCode.invalidState,
        );
      }
      if (request.isConfirmationCodeExpired(now)) {
        throw const ExternalIdentityLinkException(
          ExternalIdentityLinkFailureCode.confirmationCodeExpired,
        );
      }
      if (!userSnapshot.exists) {
        throw const ExternalIdentityLinkException(
          ExternalIdentityLinkFailureCode.userNotFound,
        );
      }
      if (mappingSnapshot.exists) {
        throw const ExternalIdentityLinkException(
          ExternalIdentityLinkFailureCode.identityAlreadyLinked,
        );
      }
      if (auditSnapshot.exists) {
        throw const ExternalIdentityLinkException(
          ExternalIdentityLinkFailureCode.conflict,
        );
      }
      if (_hasSourceMapping(userSnapshot.data(), request.identity.sourceType)) {
        throw const ExternalIdentityLinkException(
          ExternalIdentityLinkFailureCode.sourceAlreadyLinked,
        );
      }
      if (!lockSnapshot.exists ||
          lockSnapshot.data()?['requestId'] != request.id) {
        throw const ExternalIdentityLinkException(
          ExternalIdentityLinkFailureCode.conflict,
        );
      }

      transaction.set(mappingRef, <String, Object?>{
        'schemaVersion': ExternalIdentityMapping.currentSchemaVersion,
        'sourceType': request.identity.sourceType.value,
        'sourceUserId': request.identity.sourceUserId,
        'lanskeUserId': request.lanskeUserId,
        'profileUrl': request.identity.profileUrl,
        'approvedAt': FieldValue.serverTimestamp(),
        'requestId': request.id,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.update(requestRef, <String, Object?>{
        'state': ExternalIdentityLinkRequestState.approved.value,
        'approvedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(auditRef, <String, Object?>{
        'schemaVersion': 1,
        'requestId': request.id,
        'action': 'approved',
        'actorUserId': approvedBy,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(userRef, <String, Object?>{
        'externalIdentityIds.${request.identity.sourceType.value}':
            request.identity.mappingId,
      });
      transaction.delete(lockRef);
    });

    final mappingSnapshot =
        await mappingRef.get(const GetOptions(source: Source.server));
    if (!mappingSnapshot.exists) {
      throw const ExternalIdentityLinkException(
        ExternalIdentityLinkFailureCode.conflict,
        message: 'Approved mapping was not created.',
      );
    }
    return _mappingFromSnapshot(mappingSnapshot);
  }

  @override
  Future<void> rejectRequest({
    required String requestId,
    required String expectedConfirmationCodeHash,
    required String rejectedBy,
    required DateTime now,
  }) async {
    final requestRef = _requests.doc(requestId);
    final auditRef = _requestAudits.doc(requestId);

    await _firestore.runTransaction<void>((transaction) async {
      final requestSnapshot = await transaction.get(requestRef);
      if (!requestSnapshot.exists) {
        throw const ExternalIdentityLinkException(
          ExternalIdentityLinkFailureCode.requestNotFound,
        );
      }
      final request = _requestFromSnapshot(requestSnapshot);
      final lockRef = _requestLocks.doc(
        _requestLockId(request.lanskeUserId, request.identity.sourceType),
      );
      final lockSnapshot = await transaction.get(lockRef);
      final auditSnapshot = await transaction.get(auditRef);

      if (request.state != ExternalIdentityLinkRequestState.pending ||
          request.confirmationCodeHash != expectedConfirmationCodeHash) {
        throw const ExternalIdentityLinkException(
          ExternalIdentityLinkFailureCode.invalidState,
        );
      }
      if (request.isConfirmationCodeExpired(now)) {
        throw const ExternalIdentityLinkException(
          ExternalIdentityLinkFailureCode.confirmationCodeExpired,
        );
      }
      if (auditSnapshot.exists ||
          !lockSnapshot.exists ||
          lockSnapshot.data()?['requestId'] != request.id) {
        throw const ExternalIdentityLinkException(
          ExternalIdentityLinkFailureCode.conflict,
        );
      }

      transaction.update(requestRef, <String, Object?>{
        'state': ExternalIdentityLinkRequestState.rejected.value,
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(auditRef, <String, Object?>{
        'schemaVersion': 1,
        'requestId': request.id,
        'action': 'rejected',
        'actorUserId': rejectedBy,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.delete(lockRef);
    });
  }

  @override
  Future<void> unlink({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
  }) async {
    final userRef = _users.doc(lanskeUserId);

    await _firestore.runTransaction<void>((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      if (!userSnapshot.exists) {
        throw const ExternalIdentityLinkException(
          ExternalIdentityLinkFailureCode.userNotFound,
        );
      }

      final mappingId = _sourceMappingId(userSnapshot.data(), sourceType);
      if (mappingId == null) {
        throw const ExternalIdentityLinkException(
          ExternalIdentityLinkFailureCode.requestNotFound,
        );
      }

      final mappingRef = _mappings.doc(mappingId);
      final mappingSnapshot = await transaction.get(mappingRef);
      if (!mappingSnapshot.exists) {
        throw const ExternalIdentityLinkException(
          ExternalIdentityLinkFailureCode.conflict,
        );
      }
      final mapping = _mappingFromSnapshot(mappingSnapshot);
      if (mapping.lanskeUserId != lanskeUserId ||
          mapping.identity.sourceType != sourceType) {
        throw const ExternalIdentityLinkException(
          ExternalIdentityLinkFailureCode.conflict,
        );
      }

      final requestRef = _requests.doc(mapping.requestId);
      final requestSnapshot = await transaction.get(requestRef);
      if (!requestSnapshot.exists) {
        throw const ExternalIdentityLinkException(
          ExternalIdentityLinkFailureCode.conflict,
        );
      }
      final request = _requestFromSnapshot(requestSnapshot);
      if (request.state != ExternalIdentityLinkRequestState.approved ||
          request.unlinkedAt != null) {
        throw const ExternalIdentityLinkException(
          ExternalIdentityLinkFailureCode.invalidState,
        );
      }

      transaction.update(userRef, <String, Object?>{
        'externalIdentityIds.${sourceType.value}': FieldValue.delete(),
      });
      transaction.delete(mappingRef);
      transaction.update(requestRef, <String, Object?>{
        'unlinkedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  Map<String, Object?> _newRequestData({
    required String lanskeUserId,
    required ExternalIdentity identity,
    required String confirmationCodeHash,
    required DateTime confirmationCodeExpiresAt,
  }) {
    return <String, Object?>{
      'schemaVersion': ExternalIdentityLinkRequest.currentSchemaVersion,
      'lanskeUserId': lanskeUserId,
      'sourceType': identity.sourceType.value,
      'sourceUserId': identity.sourceUserId,
      'mappingId': identity.mappingId,
      'profileUrl': identity.profileUrl,
      'state': ExternalIdentityLinkRequestState.pending.value,
      'confirmationCodeHash': confirmationCodeHash,
      'confirmationCodeExpiresAt':
          Timestamp.fromDate(confirmationCodeExpiresAt.toUtc()),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  Future<ExternalIdentityLinkRequest> _loadRequest(
    DocumentReference<Map<String, dynamic>> requestRef,
  ) async {
    final snapshot =
        await requestRef.get(const GetOptions(source: Source.server));
    if (!snapshot.exists) {
      throw const ExternalIdentityLinkException(
        ExternalIdentityLinkFailureCode.conflict,
        message: 'External identity link request was not created.',
      );
    }
    return _requestFromSnapshot(snapshot);
  }

  ExternalIdentityLinkRequest _requestFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw const ExternalIdentityLinkException(
        ExternalIdentityLinkFailureCode.conflict,
      );
    }

    final sourceType = ExternalIdentitySourceType.fromValue(
      _requiredString(data, 'sourceType'),
    );
    return ExternalIdentityLinkRequest(
      id: snapshot.id,
      lanskeUserId: _requiredString(data, 'lanskeUserId'),
      identity: ExternalIdentity(
        sourceType: sourceType,
        sourceUserId: _requiredString(data, 'sourceUserId'),
        profileUrl: _requiredString(data, 'profileUrl'),
      ),
      state: ExternalIdentityLinkRequestState.fromValue(
        _requiredString(data, 'state'),
      ),
      confirmationCodeHash: _requiredString(data, 'confirmationCodeHash'),
      confirmationCodeExpiresAt:
          _requiredTimestamp(data, 'confirmationCodeExpiresAt'),
      createdAt: _requiredTimestamp(data, 'createdAt'),
      updatedAt: _requiredTimestamp(data, 'updatedAt'),
      approvedAt: _optionalTimestamp(data, 'approvedAt'),
      rejectedAt: _optionalTimestamp(data, 'rejectedAt'),
      canceledAt: _optionalTimestamp(data, 'canceledAt'),
      unlinkedAt: _optionalTimestamp(data, 'unlinkedAt'),
      supersededByRequestId: data['supersededByRequestId'] as String?,
    );
  }

  ExternalIdentityMapping _mappingFromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    if (data == null) {
      throw const ExternalIdentityLinkException(
        ExternalIdentityLinkFailureCode.conflict,
      );
    }
    final sourceType = ExternalIdentitySourceType.fromValue(
      _requiredString(data, 'sourceType'),
    );
    return ExternalIdentityMapping(
      id: snapshot.id,
      identity: ExternalIdentity(
        sourceType: sourceType,
        sourceUserId: _requiredString(data, 'sourceUserId'),
        profileUrl: _requiredString(data, 'profileUrl'),
      ),
      lanskeUserId: _requiredString(data, 'lanskeUserId'),
      requestId: _requiredString(data, 'requestId'),
      approvedAt: _requiredTimestamp(data, 'approvedAt'),
      createdAt: _requiredTimestamp(data, 'createdAt'),
      updatedAt: _requiredTimestamp(data, 'updatedAt'),
    );
  }

  bool _hasSourceMapping(
    Map<String, dynamic>? userData,
    ExternalIdentitySourceType sourceType,
  ) {
    return _sourceMappingId(userData, sourceType) != null;
  }

  String? _sourceMappingId(
    Map<String, dynamic>? userData,
    ExternalIdentitySourceType sourceType,
  ) {
    final rawIds = userData?['externalIdentityIds'];
    if (rawIds is! Map) {
      return null;
    }
    final value = rawIds[sourceType.value];
    return value is String && value.isNotEmpty ? value : null;
  }

  String _requestLockId(
    String lanskeUserId,
    ExternalIdentitySourceType sourceType,
  ) {
    return '${lanskeUserId}_${sourceType.value}';
  }

  String _requiredString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String || value.isEmpty) {
      throw ExternalIdentityLinkException(
        ExternalIdentityLinkFailureCode.conflict,
        message: 'Invalid $key.',
      );
    }
    return value;
  }

  DateTime _requiredTimestamp(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! Timestamp) {
      throw ExternalIdentityLinkException(
        ExternalIdentityLinkFailureCode.conflict,
        message: 'Invalid $key.',
      );
    }
    return value.toDate().toUtc();
  }

  DateTime? _optionalTimestamp(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value == null) {
      return null;
    }
    if (value is! Timestamp) {
      throw ExternalIdentityLinkException(
        ExternalIdentityLinkFailureCode.conflict,
        message: 'Invalid $key.',
      );
    }
    return value.toDate().toUtc();
  }

  Never _throwPrivacySafeWriteError(FirebaseException error) {
    if (error.code == 'permission-denied') {
      throw const ExternalIdentityLinkException(
        ExternalIdentityLinkFailureCode.conflict,
      );
    }
    throw error;
  }
}
