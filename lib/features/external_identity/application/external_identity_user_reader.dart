import '../domain/external_identity.dart';
import '../domain/external_identity_link_request.dart';

abstract interface class ExternalIdentityUserReader {
  Future<ExternalIdentityMapping?> getActiveMapping({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
  });

  Future<ExternalIdentityLinkRequest?> getLatestRequest({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
  });
}
