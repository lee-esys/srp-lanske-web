import 'package:cloud_firestore/cloud_firestore.dart';

import '../application/external_identity_link_exception.dart';
import '../application/external_identity_user_reader.dart';
import '../domain/external_identity.dart';
import '../domain/external_identity_link_request.dart';

class FirestoreExternalIdentityUserReader implements ExternalIdentityUserReader {
  FirestoreExternalIdentityUserReader(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _users =>
      _firestore.collection('users');
  CollectionReference<Map<String, dynamic>> get _requests =>
      _firestore.collection('externalIdentityLinkRequests');
  CollectionReference<Map<String, dynamic>> get _mappings =>
      _firestore.collection('externalIdentityMappings');

  @override
  Future<ExternalIdentityMapping?> getActiveMapping({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
  }) async {
    final userSnapshot = await _users.doc(lanskeUserId).get();
    if (!userSnapshot.exists) {
      throw const ExternalIdentityLinkException(
        ExternalIdentityLinkFailureCode.userNotFound,
      );
    }

    final rawIds = userSnapshot.data()?['externalIdentityIds'];
    if (rawIds == null) {
      return null;
    }
    if (rawIds is! Map) {
      throw const ExternalIdentityLinkException(
        ExternalIdentityLinkFailureCode.conflict,
      );
    }

    final mappingId = rawIds[sourceType.value];
    if (mappingId == null) {
      return null;
    }
    if (mappingId is! String || mappingId.isEmpty) {
      throw const ExternalIdentityLinkException(
        ExternalIdentityLinkFailureCode.conflict,
      );
    }

    final mappingSnapshot = await _mappings.doc(mappingId).get();
    if (!mappingSnapshot.exists) {
      throw const ExternalIdentityLinkException(
        ExternalIdentityLinkFailureCode.conflict,
      );
    }

    final mapping = _mappingFromSnapshot(mappingSnapshot);
    if (mapping.lanskeUserId != lanskeUserId ||
        mapping.identity.sourceType != sourceType ||
        mapping.id != mapping.identity.mappingId) {
      throw const ExternalIdentityLinkException(
        ExternalIdentityLinkFailureCode.conflict,
      );
    }
    return mapping;
  }

  @override
  Future<ExternalIdentityLinkRequest?> getLatestRequest({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
  }) async {
    final snapshot = await _requests
        .where('lanskeUserId', isEqualTo: lanskeUserId)
        .get();

    ExternalIdentityLinkRequest? latest;
    for (final document in snapshot.docs) {
      final request = _requestFromSnapshot(document);
      if (request.identity.sourceType != sourceType) {
        continue;
      }
      if (latest == null || request.updatedAt.isAfter(latest.updatedAt)) {
        latest = request;
      }
    }
    return latest;
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

  String _requiredString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! String || value.isEmpty) {
      throw const ExternalIdentityLinkException(
        ExternalIdentityLinkFailureCode.conflict,
      );
    }
    return value;
  }

  DateTime _requiredTimestamp(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is! Timestamp) {
      throw const ExternalIdentityLinkException(
        ExternalIdentityLinkFailureCode.conflict,
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
      throw const ExternalIdentityLinkException(
        ExternalIdentityLinkFailureCode.conflict,
      );
    }
    return value.toDate().toUtc();
  }
}
