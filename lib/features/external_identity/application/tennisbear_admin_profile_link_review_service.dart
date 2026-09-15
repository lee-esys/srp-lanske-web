import '../../auth/application/admin_role_reader.dart';
import '../../auth/application/auth_repository.dart';
import '../domain/external_identity.dart';
import '../domain/external_identity_link_request.dart';
import 'external_identity_link_service.dart';

enum TennisBearAdminProfileLinkReviewFailureCode {
  accessDenied,
}

enum TennisBearAdminProfileLinkReviewStatus {
  pending,
  expired,
  approved,
  approvedUnlinked,
  rejected,
  canceled,
  superseded,
}

class TennisBearAdminProfileLinkReviewException implements Exception {
  const TennisBearAdminProfileLinkReviewException(this.code);

  final TennisBearAdminProfileLinkReviewFailureCode code;
}

class TennisBearAdminProfileLinkReviewService {
  TennisBearAdminProfileLinkReviewService({
    required AuthRepository authRepository,
    required AdminRoleReader adminRoleReader,
    required ExternalIdentityLinkService linkService,
    DateTime Function()? now,
  })  : _authRepository = authRepository,
        _adminRoleReader = adminRoleReader,
        _linkService = linkService,
        _now = now ?? DateTime.now;

  final AuthRepository _authRepository;
  final AdminRoleReader _adminRoleReader;
  final ExternalIdentityLinkService _linkService;
  final DateTime Function() _now;

  Future<bool> canReview() async {
    final session = _authRepository.currentSession;
    if (!session.isAccount || session.uid == null) {
      return false;
    }
    return _adminRoleReader.isCurrentUserAdmin();
  }

  Future<ExternalIdentityLinkRequest?> findRequestByConfirmationCode(
    String confirmationCode,
  ) async {
    await _requireAdminUserId();

    final request =
        await _linkService.findByConfirmationCode(confirmationCode.trim());
    if (request == null ||
        request.identity.sourceType != ExternalIdentitySourceType.tennisbear) {
      return null;
    }
    return request;
  }

  TennisBearAdminProfileLinkReviewStatus statusOf(
    ExternalIdentityLinkRequest request,
  ) {
    if (request.state == ExternalIdentityLinkRequestState.pending &&
        request.isConfirmationCodeExpired(_now().toUtc())) {
      return TennisBearAdminProfileLinkReviewStatus.expired;
    }

    return switch (request.state) {
      ExternalIdentityLinkRequestState.pending =>
        TennisBearAdminProfileLinkReviewStatus.pending,
      ExternalIdentityLinkRequestState.approved when request.unlinkedAt != null =>
        TennisBearAdminProfileLinkReviewStatus.approvedUnlinked,
      ExternalIdentityLinkRequestState.approved =>
        TennisBearAdminProfileLinkReviewStatus.approved,
      ExternalIdentityLinkRequestState.rejected =>
        TennisBearAdminProfileLinkReviewStatus.rejected,
      ExternalIdentityLinkRequestState.canceled =>
        TennisBearAdminProfileLinkReviewStatus.canceled,
      ExternalIdentityLinkRequestState.expired =>
        TennisBearAdminProfileLinkReviewStatus.expired,
      ExternalIdentityLinkRequestState.superseded =>
        TennisBearAdminProfileLinkReviewStatus.superseded,
    };
  }

  bool canDecide(ExternalIdentityLinkRequest request) {
    return statusOf(request) == TennisBearAdminProfileLinkReviewStatus.pending;
  }

  Future<ExternalIdentityMapping> approve(String confirmationCode) async {
    final adminUserId = await _requireAdminUserId();
    return _linkService.approveByConfirmationCode(
      confirmationCode: confirmationCode.trim(),
      approvedBy: adminUserId,
    );
  }

  Future<void> reject(String confirmationCode) async {
    final adminUserId = await _requireAdminUserId();
    await _linkService.rejectByConfirmationCode(
      confirmationCode: confirmationCode.trim(),
      rejectedBy: adminUserId,
    );
  }

  Future<String> _requireAdminUserId() async {
    final session = _authRepository.currentSession;
    final uid = session.uid;
    if (!session.isAccount ||
        uid == null ||
        !await _adminRoleReader.isCurrentUserAdmin()) {
      throw const TennisBearAdminProfileLinkReviewException(
        TennisBearAdminProfileLinkReviewFailureCode.accessDenied,
      );
    }
    return uid;
  }
}
