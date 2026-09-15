import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/auth/application/admin_role_reader.dart';
import 'package:srp_lanske/features/auth/application/auth_repository.dart';
import 'package:srp_lanske/features/auth/domain/auth_session.dart';
import 'package:srp_lanske/features/external_identity/application/external_identity_link_repository.dart';
import 'package:srp_lanske/features/external_identity/application/external_identity_link_service.dart';
import 'package:srp_lanske/features/external_identity/application/tennisbear_admin_profile_link_review_service.dart';
import 'package:srp_lanske/features/external_identity/domain/external_identity.dart';
import 'package:srp_lanske/features/external_identity/domain/external_identity_link_request.dart';

void main() {
  final now = DateTime.utc(2026, 9, 15, 1);

  test('non-admin cannot inspect confirmation codes', () async {
    final repository = _FakeExternalIdentityLinkRepository()
      ..requestByCodeHash = _pendingRequest(now);
    final service = _service(
      repository: repository,
      now: now,
      isAdmin: false,
    );

    await expectLater(
      () => service.findRequestByConfirmationCode('LSK-ABCD-2345'),
      throwsA(
        isA<TennisBearAdminProfileLinkReviewException>().having(
          (error) => error.code,
          'code',
          TennisBearAdminProfileLinkReviewFailureCode.accessDenied,
        ),
      ),
    );
    expect(repository.findCalls, 0);
  });

  test('admin can inspect an existing request regardless of decision state',
      () async {
    final repository = _FakeExternalIdentityLinkRepository()
      ..requestByCodeHash = _pendingRequest(now);
    final service = _service(
      repository: repository,
      now: now,
      isAdmin: true,
    );

    final pending =
        await service.findRequestByConfirmationCode('LSK-ABCD-2345');
    expect(pending?.id, 'request-1');

    repository.requestByCodeHash = _pendingRequest(
      now,
      state: ExternalIdentityLinkRequestState.canceled,
    );
    final canceled =
        await service.findRequestByConfirmationCode('LSK-ABCD-2345');
    expect(canceled?.state, ExternalIdentityLinkRequestState.canceled);

    repository.requestByCodeHash = _pendingRequest(
      now,
      expiresAt: now.subtract(const Duration(seconds: 1)),
    );
    final expired =
        await service.findRequestByConfirmationCode('LSK-ABCD-2345');
    expect(expired?.id, 'request-1');

    repository.requestByCodeHash = null;
    expect(
      await service.findRequestByConfirmationCode('LSK-ABCD-2345'),
      isNull,
    );
  });

  test('review status separates display state from decision availability', () {
    final repository = _FakeExternalIdentityLinkRepository();
    final service = _service(
      repository: repository,
      now: now,
      isAdmin: true,
    );

    final pending = _pendingRequest(now);
    expect(
      service.statusOf(pending),
      TennisBearAdminProfileLinkReviewStatus.pending,
    );
    expect(service.canDecide(pending), isTrue);

    final expired = _pendingRequest(
      now,
      expiresAt: now.subtract(const Duration(seconds: 1)),
    );
    expect(
      service.statusOf(expired),
      TennisBearAdminProfileLinkReviewStatus.expired,
    );
    expect(service.canDecide(expired), isFalse);

    expect(
      service.statusOf(
        _pendingRequest(
          now,
          state: ExternalIdentityLinkRequestState.approved,
        ),
      ),
      TennisBearAdminProfileLinkReviewStatus.approved,
    );
    expect(
      service.statusOf(
        _pendingRequest(
          now,
          state: ExternalIdentityLinkRequestState.approved,
          unlinkedAt: now,
        ),
      ),
      TennisBearAdminProfileLinkReviewStatus.approvedUnlinked,
    );
    expect(
      service.statusOf(
        _pendingRequest(
          now,
          state: ExternalIdentityLinkRequestState.rejected,
        ),
      ),
      TennisBearAdminProfileLinkReviewStatus.rejected,
    );
    expect(
      service.statusOf(
        _pendingRequest(
          now,
          state: ExternalIdentityLinkRequestState.canceled,
        ),
      ),
      TennisBearAdminProfileLinkReviewStatus.canceled,
    );
    expect(
      service.statusOf(
        _pendingRequest(
          now,
          state: ExternalIdentityLinkRequestState.superseded,
        ),
      ),
      TennisBearAdminProfileLinkReviewStatus.superseded,
    );
  });

  test('approval records the current admin uid as actor', () async {
    final repository = _FakeExternalIdentityLinkRepository()
      ..requestByCodeHash = _pendingRequest(now);
    final service = _service(
      repository: repository,
      now: now,
      isAdmin: true,
    );

    final mapping = await service.approve('LSK-ABCD-2345');

    expect(mapping.id, 'tennisbear_899212');
    expect(repository.approvedBy, 'admin-1');
  });

  test('rejection records the current admin uid as actor', () async {
    final repository = _FakeExternalIdentityLinkRepository()
      ..requestByCodeHash = _pendingRequest(now);
    final service = _service(
      repository: repository,
      now: now,
      isAdmin: true,
    );

    await service.reject('LSK-ABCD-2345');

    expect(repository.rejectedBy, 'admin-1');
  });
}

TennisBearAdminProfileLinkReviewService _service({
  required _FakeExternalIdentityLinkRepository repository,
  required DateTime now,
  required bool isAdmin,
}) {
  return TennisBearAdminProfileLinkReviewService(
    authRepository: _FakeAuthRepository(
      const AuthSession.account('admin-1'),
    ),
    adminRoleReader: _FakeAdminRoleReader(isAdmin),
    linkService: ExternalIdentityLinkService(
      repository: repository,
      now: () => now,
    ),
    now: () => now,
  );
}

ExternalIdentityLinkRequest _pendingRequest(
  DateTime now, {
  ExternalIdentityLinkRequestState state =
      ExternalIdentityLinkRequestState.pending,
  DateTime? expiresAt,
  DateTime? unlinkedAt,
}) {
  return ExternalIdentityLinkRequest(
    id: 'request-1',
    lanskeUserId: 'user-1',
    identity: const ExternalIdentity(
      sourceType: ExternalIdentitySourceType.tennisbear,
      sourceUserId: '899212',
      profileUrl: 'https://www.tennisbear.net/user/899212/info',
    ),
    state: state,
    confirmationCodeHash: List<String>.filled(64, 'a').join(),
    confirmationCodeExpiresAt: expiresAt ?? now.add(const Duration(days: 1)),
    createdAt: now.subtract(const Duration(hours: 1)),
    updatedAt: now.subtract(const Duration(hours: 1)),
    unlinkedAt: unlinkedAt,
  );
}

class _FakeAdminRoleReader implements AdminRoleReader {
  _FakeAdminRoleReader(this.isAdmin);

  final bool isAdmin;

  @override
  Future<bool> isCurrentUserAdmin({bool forceRefresh = false}) async {
    return isAdmin;
  }
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository(this.session);

  AuthSession session;

  @override
  AuthSession get currentSession => session;

  @override
  Future<AuthSession> ensureAnonymousSession() async => session;

  @override
  Stream<AuthSession> sessionChanges() => Stream.value(session);

  @override
  Future<void> signOut() async {}
}

class _FakeExternalIdentityLinkRepository
    implements ExternalIdentityLinkRepository {
  ExternalIdentityLinkRequest? requestByCodeHash;
  int findCalls = 0;
  String? approvedBy;
  String? rejectedBy;

  @override
  Future<ExternalIdentityLinkRequest?> findRequestByConfirmationCodeHash(
    String confirmationCodeHash,
  ) async {
    findCalls += 1;
    return requestByCodeHash;
  }

  @override
  Future<ExternalIdentityMapping> approveRequest({
    required String requestId,
    required String expectedConfirmationCodeHash,
    required String approvedBy,
    required DateTime now,
  }) async {
    this.approvedBy = approvedBy;
    final request = requestByCodeHash!;
    return ExternalIdentityMapping(
      id: request.identity.mappingId,
      identity: request.identity,
      lanskeUserId: request.lanskeUserId,
      requestId: request.id,
      approvedAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> rejectRequest({
    required String requestId,
    required String expectedConfirmationCodeHash,
    required String rejectedBy,
    required DateTime now,
  }) async {
    this.rejectedBy = rejectedBy;
  }

  @override
  Future<void> cancelRequest({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
  }) async {}

  @override
  Future<ExternalIdentityLinkRequest> createRequest({
    required String lanskeUserId,
    required ExternalIdentity identity,
    required String confirmationCodeHash,
    required DateTime confirmationCodeExpiresAt,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ExternalIdentityLinkRequest?> getActiveRequest({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
  }) async {
    return null;
  }

  @override
  Future<ExternalIdentityLinkRequest> reissueRequest({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
    required String confirmationCodeHash,
    required DateTime confirmationCodeExpiresAt,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> unlink({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
  }) async {}
}
