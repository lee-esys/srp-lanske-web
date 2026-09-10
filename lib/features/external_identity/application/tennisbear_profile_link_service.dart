import '../domain/external_identity.dart';
import '../domain/external_identity_link_request.dart';
import 'external_identity_link_service.dart';
import 'external_identity_user_reader.dart';

class TennisBearProfileLinkSnapshot {
  const TennisBearProfileLinkSnapshot({
    required this.activeMapping,
    required this.activeRequest,
    required this.latestRequest,
  });

  final ExternalIdentityMapping? activeMapping;
  final ExternalIdentityLinkRequest? activeRequest;
  final ExternalIdentityLinkRequest? latestRequest;
}

class TennisBearProfileLinkService {
  TennisBearProfileLinkService({
    required ExternalIdentityLinkService linkService,
    required ExternalIdentityUserReader userReader,
  })  : _linkService = linkService,
        _userReader = userReader;

  final ExternalIdentityLinkService _linkService;
  final ExternalIdentityUserReader _userReader;

  Future<TennisBearProfileLinkSnapshot> load(String lanskeUserId) async {
    final activeMapping = await _userReader.getActiveMapping(
      lanskeUserId: lanskeUserId,
      sourceType: ExternalIdentitySourceType.tennisbear,
    );
    if (activeMapping != null) {
      return TennisBearProfileLinkSnapshot(
        activeMapping: activeMapping,
        activeRequest: null,
        latestRequest: null,
      );
    }

    final activeRequest = await _linkService.getActiveRequest(
      lanskeUserId: lanskeUserId,
      sourceType: ExternalIdentitySourceType.tennisbear,
    );
    if (activeRequest != null) {
      return TennisBearProfileLinkSnapshot(
        activeMapping: null,
        activeRequest: activeRequest,
        latestRequest: activeRequest,
      );
    }

    final latestRequest = await _userReader.getLatestRequest(
      lanskeUserId: lanskeUserId,
      sourceType: ExternalIdentitySourceType.tennisbear,
    );
    return TennisBearProfileLinkSnapshot(
      activeMapping: null,
      activeRequest: null,
      latestRequest: latestRequest,
    );
  }

  Future<IssuedExternalIdentityLinkRequest> createRequest({
    required String lanskeUserId,
    required String profileUrl,
  }) {
    return _linkService.createTennisBearRequest(
      lanskeUserId: lanskeUserId,
      profileUrl: profileUrl,
    );
  }

  Future<IssuedExternalIdentityLinkRequest> reissue(String lanskeUserId) {
    return _linkService.reissue(
      lanskeUserId: lanskeUserId,
      sourceType: ExternalIdentitySourceType.tennisbear,
    );
  }

  Future<void> cancel(String lanskeUserId) {
    return _linkService.cancelRequest(
      lanskeUserId: lanskeUserId,
      sourceType: ExternalIdentitySourceType.tennisbear,
    );
  }

  Future<void> unlink(String lanskeUserId) {
    return _linkService.unlink(
      lanskeUserId: lanskeUserId,
      sourceType: ExternalIdentitySourceType.tennisbear,
    );
  }
}
