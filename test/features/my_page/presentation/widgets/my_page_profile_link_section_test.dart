import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/external_identity/application/tennisbear_profile_link_service.dart';
import 'package:srp_lanske/features/external_identity/domain/external_identity.dart';
import 'package:srp_lanske/features/external_identity/domain/external_identity_link_request.dart';
import 'package:srp_lanske/features/my_page/presentation/widgets/my_page_profile_link_section.dart';
import 'package:srp_lanske/l10n/l10n.dart';

void main() {
  final now = DateTime.utc(2026, 10, 5, 3);

  testWidgets('shows unlinked state, purpose, and management action',
      (tester) async {
    var managementCalls = 0;

    await _pumpSection(
      tester,
      snapshot: const TennisBearProfileLinkSnapshot(
        activeMapping: null,
        activeRequest: null,
        latestRequest: null,
      ),
      now: now,
      onOpenManagement: () {
        managementCalls += 1;
      },
    );

    expect(find.text('プロフィール連携'), findsOneWidget);
    expect(find.text('テニスベア'), findsOneWidget);
    expect(find.text('未連携'), findsOneWidget);
    expect(
      find.textContaining('あなたの統計データを集計するために利用します'),
      findsOneWidget,
    );

    await tester.tap(find.text('プロフィール連携を管理'));
    expect(managementCalls, 1);
  });

  testWidgets('shows pending and expired request states', (tester) async {
    final pending = _request(
      now: now,
      state: ExternalIdentityLinkRequestState.pending,
    );

    await _pumpSection(
      tester,
      snapshot: TennisBearProfileLinkSnapshot(
        activeMapping: null,
        activeRequest: pending,
        latestRequest: pending,
      ),
      now: now,
    );
    expect(find.text('申請中'), findsOneWidget);

    await _pumpSection(
      tester,
      snapshot: TennisBearProfileLinkSnapshot(
        activeMapping: null,
        activeRequest: pending,
        latestRequest: pending,
      ),
      now: now.add(const Duration(days: 8)),
    );
    expect(find.text('確認コードの期限切れ'), findsOneWidget);
  });

  testWidgets('shows retryable state after a rejected request', (tester) async {
    final rejected = _request(
      now: now,
      state: ExternalIdentityLinkRequestState.rejected,
    );

    await _pumpSection(
      tester,
      snapshot: TennisBearProfileLinkSnapshot(
        activeMapping: null,
        activeRequest: null,
        latestRequest: rejected,
      ),
      now: now,
    );

    expect(find.text('再申請できます'), findsOneWidget);
  });

  testWidgets('shows linked state for an active mapping', (tester) async {
    final mapping = ExternalIdentityMapping(
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

    await _pumpSection(
      tester,
      snapshot: TennisBearProfileLinkSnapshot(
        activeMapping: mapping,
        activeRequest: null,
        latestRequest: null,
      ),
      now: now,
    );

    expect(find.text('承認済み'), findsOneWidget);
  });

  testWidgets('shows retry and management actions after load failure',
      (tester) async {
    var attempts = 0;
    var managementCalls = 0;

    await tester.pumpWidget(
      _testApp(
        loadProfileLink: (_) async {
          attempts += 1;
          if (attempts == 1) {
            throw StateError('load failed');
          }
          return const TennisBearProfileLinkSnapshot(
            activeMapping: null,
            activeRequest: null,
            latestRequest: null,
          );
        },
        now: now,
        onOpenManagement: () {
          managementCalls += 1;
        },
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('プロフィール連携の状態を確認できませんでした'), findsOneWidget);

    await tester.tap(find.text('プロフィール連携を管理'));
    expect(managementCalls, 1);

    await tester.tap(find.text('再読み込み'));
    await tester.pumpAndSettle();

    expect(find.text('未連携'), findsOneWidget);
    expect(attempts, 2);
  });
}

Future<void> _pumpSection(
  WidgetTester tester, {
  required TennisBearProfileLinkSnapshot snapshot,
  required DateTime now,
  VoidCallback? onOpenManagement,
}) async {
  await tester.pumpWidget(
    _testApp(
      loadProfileLink: (_) async => snapshot,
      now: now,
      onOpenManagement: onOpenManagement ?? () {},
    ),
  );
  await tester.pumpAndSettle();
}

Widget _testApp({
  required MyPageProfileLinkLoader loadProfileLink,
  required DateTime now,
  required VoidCallback onOpenManagement,
}) {
  return MaterialApp(
    locale: const Locale('ja'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: MyPageProfileLinkSection(
        lanskeUserId: 'user-1',
        loadProfileLink: loadProfileLink,
        onOpenManagement: onOpenManagement,
        now: () => now,
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
