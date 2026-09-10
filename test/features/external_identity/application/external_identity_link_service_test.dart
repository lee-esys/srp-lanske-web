import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/external_identity/application/external_identity_link_exception.dart';
import 'package:srp_lanske/features/external_identity/application/external_identity_link_repository.dart';
import 'package:srp_lanske/features/external_identity/application/external_identity_link_service.dart';
import 'package:srp_lanske/features/external_identity/domain/confirmation_code.dart';
import 'package:srp_lanske/features/external_identity/domain/external_identity.dart';
import 'package:srp_lanske/features/external_identity/domain/external_identity_link_request.dart';

void main() {
  final now = DateTime.utc(2026, 9, 8, 12);

  test('creates a TennisBear request with a seven-day code expiry', () async {
    final repository = _FakeExternalIdentityLinkRepository(now: now);
    final service = ExternalIdentityLinkService(
      repository: repository,
      confirmationCodeIssuer: ConfirmationCodeIssuer(random: Random(42)),
      now: () => now,
    );

    final issued = await service.createTennisBearRequest(
      lanskeUserId: 'user-1',
      profileUrl: 'https://www.tennisbear.net/user/899212/info',
    );

    expect(issued.request.lanskeUserId, 'user-1');
    expect(issued.request.identity.mappingId, 'tennisbear_899212');
    expect(
      issued.request.confirmationCodeExpiresAt,
      now.add(const Duration(days: 7)),
    );
    expect(issued.confirmationCode, startsWith('LSK-'));
    expect(repository.lastCreatedCodeHash, hasLength(64));
  });

  test('does not call approval when the confirmation code is expired',
      () async {
    final repository = _FakeExternalIdentityLinkRepository(now: now)
      ..requestByCodeHash = ExternalIdentityLinkRequest(
        id: 'request-1',
        lanskeUserId: 'user-1',
        identity: const ExternalIdentity(
          sourceType: ExternalIdentitySourceType.tennisbear,
          sourceUserId: '899212',
          profileUrl: 'https://www.tennisbear.net/user/899212/info',
        ),
        state: ExternalIdentityLinkRequestState.pending,
        confirmationCodeHash: 'hash',
        confirmationCodeExpiresAt: now.subtract(const Duration(seconds: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      );
    final service = ExternalIdentityLinkService(
      repository: repository,
      confirmationCodeIssuer: ConfirmationCodeIssuer(random: Random(1)),
      now: () => now,
    );

    await expectLater(
      () => service.approveByConfirmationCode(
        confirmationCode: 'LSK-ABCD-2345',
        approvedBy: 'admin-1',
      ),
      throwsA(
        isA<ExternalIdentityLinkException>().having(
          (error) => error.code,
          'code',
          ExternalIdentityLinkFailureCode.confirmationCodeExpired,
        ),
      ),
    );
    expect(repository.approvalCalled, isFalse);
  });
}

class _FakeExternalIdentityLinkRepository
    implements ExternalIdentityLinkRepository {
  _FakeExternalIdentityLinkRepository({required this.now});

  final DateTime now;
  String? lastCreatedCodeHash;
  ExternalIdentityLinkRequest? activeRequest;
  ExternalIdentityLinkRequest? requestByCodeHash;
  bool approvalCalled = false;

  @override
  Future<ExternalIdentityLinkRequest> createRequest({
    required String lanskeUserId,
    required ExternalIdentity identity,
    required String confirmationCodeHash,
    required DateTime confirmationCodeExpiresAt,
  }) async {
    lastCreatedCodeHash = confirmationCodeHash;
    final request = ExternalIdentityLinkRequest(
      id: 'request-1',
      lanskeUserId: lanskeUserId,
      identity: identity,
      state: ExternalIdentityLinkRequestState.pending,
      confirmationCodeHash: confirmationCodeHash,
      confirmationCodeExpiresAt: confirmationCodeExpiresAt,
      createdAt: now,
      updatedAt: now,
    );
    activeRequest = request;
    return request;
  }

  @override
  Future<ExternalIdentityLinkRequest?> findRequestByConfirmationCodeHash(
    String confirmationCodeHash,
  ) async {
    return requestByCodeHash;
  }

  @override
  Future<ExternalIdentityMapping> approveRequest({
    required String requestId,
    required String expectedConfirmationCodeHash,
    required String approvedBy,
    required DateTime now,
  }) async {
    approvalCalled = true;
    throw UnimplementedError();
  }

  @override
  Future<void> cancelRequest({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
  }) async {}

  @override
  Future<ExternalIdentityLinkRequest?> getActiveRequest({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
  }) async {
    return activeRequest;
  }

  @override
  Future<void> rejectRequest({
    required String requestId,
    required String expectedConfirmationCodeHash,
    required String rejectedBy,
    required DateTime now,
  }) async {}

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
