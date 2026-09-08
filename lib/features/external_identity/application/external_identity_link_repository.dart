import '../domain/external_identity.dart';
import '../domain/external_identity_link_request.dart';

abstract interface class ExternalIdentityLinkRepository {
  Future<ExternalIdentityLinkRequest?> getActiveRequest({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
  });

  Future<ExternalIdentityLinkRequest> createRequest({
    required String lanskeUserId,
    required ExternalIdentity identity,
    required String confirmationCodeHash,
    required DateTime confirmationCodeExpiresAt,
  });

  Future<ExternalIdentityLinkRequest> reissueRequest({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
    required String confirmationCodeHash,
    required DateTime confirmationCodeExpiresAt,
  });

  Future<void> cancelRequest({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
  });

  Future<ExternalIdentityLinkRequest?> findRequestByConfirmationCodeHash(
    String confirmationCodeHash,
  );

  Future<ExternalIdentityMapping> approveRequest({
    required String requestId,
    required String expectedConfirmationCodeHash,
    required String approvedBy,
    required DateTime now,
  });

  Future<void> rejectRequest({
    required String requestId,
    required String expectedConfirmationCodeHash,
    required String rejectedBy,
    required DateTime now,
  });

  Future<void> unlink({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
  });
}
