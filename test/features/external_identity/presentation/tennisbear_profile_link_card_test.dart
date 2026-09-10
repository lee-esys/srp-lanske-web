import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/external_identity/application/external_identity_link_repository.dart';
import 'package:srp_lanske/features/external_identity/application/external_identity_link_service.dart';
import 'package:srp_lanske/features/external_identity/application/external_identity_user_reader.dart';
import 'package:srp_lanske/features/external_identity/application/tennisbear_profile_link_service.dart';
import 'package:srp_lanske/features/external_identity/domain/confirmation_code.dart';
import 'package:srp_lanske/features/external_identity/domain/external_identity.dart';
import 'package:srp_lanske/features/external_identity/domain/external_identity_link_request.dart';
import 'package:srp_lanske/features/external_identity/presentation/external_identity_link_scope.dart';
import 'package:srp_lanske/features/external_identity/presentation/tennisbear_profile_link_card.dart';
import 'package:srp_lanske/l10n/l10n.dart';

void main() {
  final now = DateTime.utc(2026, 9, 10, 3);

  testWidgets('shows request form when no TennisBear identity is linked',
      (tester) async {
    final fixture = _Fixture(now: now);

    await tester.pumpWidget(_testApp(fixture.service));
    await tester.pumpAndSettle();

    expect(find.text('未連携'), findsOneWidget);
    expect(find.text('このプロフィールで連携を申請'), findsOneWidget);
  });

  testWidgets('shows issued confirmation code after request creation',
      (tester) async {
    final fixture = _Fixture(now: now);

    await tester.pumpWidget(_testApp(fixture.service));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField),
      'https://www.tennisbear.net/user/899212/info',
    );
    final submit = find.text('このプロフィールで連携を申請');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();

    expect(find.text('申請中'), findsOneWidget);
    expect(find.textContaining('LSK-'), findsWidgets);
    expect(find.text('新しい確認コードを再発行'), findsOneWidget);
  });

  testWidgets('does not reconstruct plaintext code after reloading pending state',
      (tester) async {
    final fixture = _Fixture(now: now)
      ..repository.activeRequest = _request(
        now: now,
        state: ExternalIdentityLinkRequestState.pending,
      )
      ..reader.latestRequest = _request(
        now: now,
        state: ExternalIdentityLinkRequestState.pending,
      );

    await tester.pumpWidget(_testApp(fixture.service));
    await tester.pumpAndSettle();

    expect(find.text('申請中'), findsOneWidget);
    expect(find.textContaining('同じコードは再表示できません'), findsOneWidget);
    expect(find.textContaining('LSK-'), findsNothing);
  });

  testWidgets('shows approved mapping and unlink action', (tester) async {
    final fixture = _Fixture(now: now)
      ..reader.activeMapping = ExternalIdentityMapping(
        id: 'tennisbear_899212',
        identity: const ExternalIdentity(
          sourceType: ExternalIdentitySourceType.tennisbear,
          sourceUserId: '899212',
          profileUrl: 'https://www.tennisbear.net/user/899212/info',
        ),
        lanskeUserId: 'user-1',
        requestId: 'request-1',
        approvedAt: now,
        createdAt: now,
        updatedAt: now,
      );

    await tester.pumpWidget(_testApp(fixture.service));
    await tester.pumpAndSettle();

    expect(find.text('承認済み'), findsOneWidget);
    expect(find.text('プロフィール連携を解除'), findsOneWidget);
  });
}

Widget _testApp(TennisBearProfileLinkService service) {
  return MaterialApp(
    locale: const Locale('ja'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ExternalIdentityLinkScope(
        service: service,
        child: const SingleChildScrollView(
          child: TennisBearProfileLinkCard(lanskeUserId: 'user-1'),
        ),
      ),
    ),
  );
}

ExternalIdentityLinkRequest _request({
  required DateTime now,
  required ExternalIdentityLinkRequestState state,
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
    confirmationCodeExpiresAt: now.add(const Duration(days: 7)),
    createdAt: now,
    updatedAt: now,
  );
}

class _Fixture {
  _Fixture({required DateTime now})
      : repository = _FakeLinkRepository(now: now),
        reader = _FakeUserReader() {
    service = TennisBearProfileLinkService(
      linkService: ExternalIdentityLinkService(
        repository: repository,
        confirmationCodeIssuer: ConfirmationCodeIssuer(random: Random(42)),
        now: () => now,
      ),
      userReader: reader,
    );
  }

  final _FakeLinkRepository repository;
  final _FakeUserReader reader;
  late final TennisBearProfileLinkService service;
}

class _FakeUserReader implements ExternalIdentityUserReader {
  ExternalIdentityMapping? activeMapping;
  ExternalIdentityLinkRequest? latestRequest;

  @override
  Future<ExternalIdentityMapping?> getActiveMapping({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
  }) async {
    return activeMapping;
  }

  @override
  Future<ExternalIdentityLinkRequest?> getLatestRequest({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
  }) async {
    return latestRequest;
  }
}

class _FakeLinkRepository implements ExternalIdentityLinkRepository {
  _FakeLinkRepository({required this.now});

  final DateTime now;
  ExternalIdentityLinkRequest? activeRequest;

  @override
  Future<ExternalIdentityLinkRequest> createRequest({
    required String lanskeUserId,
    required ExternalIdentity identity,
    required String confirmationCodeHash,
    required DateTime confirmationCodeExpiresAt,
  }) async {
    activeRequest = ExternalIdentityLinkRequest(
      id: 'request-1',
      lanskeUserId: lanskeUserId,
      identity: identity,
      state: ExternalIdentityLinkRequestState.pending,
      confirmationCodeHash: confirmationCodeHash,
      confirmationCodeExpiresAt: confirmationCodeExpiresAt,
      createdAt: now,
      updatedAt: now,
    );
    return activeRequest!;
  }

  @override
  Future<ExternalIdentityLinkRequest?> getActiveRequest({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
  }) async {
    return activeRequest;
  }

  @override
  Future<ExternalIdentityLinkRequest> reissueRequest({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
    required String confirmationCodeHash,
    required DateTime confirmationCodeExpiresAt,
  }) async {
    final current = activeRequest!;
    activeRequest = ExternalIdentityLinkRequest(
      id: 'request-2',
      lanskeUserId: lanskeUserId,
      identity: current.identity,
      state: ExternalIdentityLinkRequestState.pending,
      confirmationCodeHash: confirmationCodeHash,
      confirmationCodeExpiresAt: confirmationCodeExpiresAt,
      createdAt: now,
      updatedAt: now,
    );
    return activeRequest!;
  }

  @override
  Future<void> cancelRequest({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
  }) async {
    activeRequest = null;
  }

  @override
  Future<void> unlink({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
  }) async {}

  @override
  Future<ExternalIdentityLinkRequest?> findRequestByConfirmationCodeHash(
    String confirmationCodeHash,
  ) async {
    return null;
  }

  @override
  Future<ExternalIdentityMapping> approveRequest({
    required String requestId,
    required String expectedConfirmationCodeHash,
    required String approvedBy,
    required DateTime now,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<void> rejectRequest({
    required String requestId,
    required String expectedConfirmationCodeHash,
    required String rejectedBy,
    required DateTime now,
  }) {
    throw UnimplementedError();
  }
}
