import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/external_identity/application/tennisbear_admin_profile_link_review_service.dart';
import 'package:srp_lanske/features/external_identity/domain/external_identity.dart';
import 'package:srp_lanske/features/external_identity/domain/external_identity_link_request.dart';
import 'package:srp_lanske/features/external_identity/presentation/admin_profile_link_review_page.dart';
import 'package:srp_lanske/features/external_identity/presentation/external_identity_admin_review_scope.dart';
import 'package:srp_lanske/l10n/l10n.dart';

void main() {
  final now = DateTime.utc(2026, 9, 15, 1);

  testWidgets('non-admin cannot open the review form', (tester) async {
    final service = _FakeAdminReviewService(canReviewValue: false);

    await tester.pumpWidget(_testApp(service));
    await tester.pumpAndSettle();

    expect(find.text('管理者権限が必要です。'), findsOneWidget);
    expect(find.text('申請を確認'), findsNothing);
  });

  testWidgets('admin can find a reviewable TennisBear request', (tester) async {
    final service = _FakeAdminReviewService(
      canReviewValue: true,
      request: _request(now),
    );

    await tester.pumpWidget(_testApp(service));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField),
      'LSK-ABCD-2345',
    );
    await tester.tap(find.text('申請を確認'));
    await tester.pumpAndSettle();

    expect(find.text('899212'), findsOneWidget);
    expect(
      find.text('https://www.tennisbear.net/user/899212/info'),
      findsOneWidget,
    );
    expect(find.text('承認'), findsOneWidget);
    expect(find.text('却下'), findsOneWidget);
  });

  testWidgets('missing confirmation code result shows only not-found message',
      (tester) async {
    final service = _FakeAdminReviewService(
      canReviewValue: true,
      request: null,
    );

    await tester.pumpWidget(_testApp(service));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField),
      'LSK-NONE-0000',
    );
    await tester.tap(find.text('申請を確認'));
    await tester.pumpAndSettle();

    expect(
      find.text('該当する申請が見つかりません。確認コードを確認してください。'),
      findsOneWidget,
    );
    expect(find.text('899212'), findsNothing);
  });

  testWidgets('terminal request states are shown without decision buttons',
      (tester) async {
    final scenarios = <({
      ExternalIdentityLinkRequest request,
      String label,
      String note,
    })>[
      (
        request: _request(
          now,
          expiresAt: now.subtract(const Duration(seconds: 1)),
        ),
        label: '期限切れ',
        note: 'この確認コードは有効期限が切れています。',
      ),
      (
        request: _request(
          now,
          state: ExternalIdentityLinkRequestState.approved,
        ),
        label: '承認済み',
        note: 'この申請は承認済みのため、追加の操作はできません。',
      ),
      (
        request: _request(
          now,
          state: ExternalIdentityLinkRequestState.approved,
          unlinkedAt: now,
        ),
        label: '承認済み（連携解除済み）',
        note: 'この申請は承認後にプロフィール連携が解除されています。',
      ),
      (
        request: _request(
          now,
          state: ExternalIdentityLinkRequestState.rejected,
        ),
        label: '却下済み',
        note: 'この申請は却下済みのため、追加の操作はできません。',
      ),
      (
        request: _request(
          now,
          state: ExternalIdentityLinkRequestState.canceled,
        ),
        label: 'キャンセル済み',
        note: 'この申請はユーザーによりキャンセルされています。',
      ),
      (
        request: _request(
          now,
          state: ExternalIdentityLinkRequestState.superseded,
        ),
        label: '再発行済み',
        note: 'この確認コードは再発行により無効になっています。',
      ),
    ];

    for (final scenario in scenarios) {
      final service = _FakeAdminReviewService(
        canReviewValue: true,
        request: scenario.request,
        now: now,
      );

      await tester.pumpWidget(_testApp(service));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField),
        'LSK-ABCD-2345',
      );
      await tester.tap(find.text('申請を確認'));
      await tester.pumpAndSettle();

      expect(find.text(scenario.label), findsOneWidget);
      expect(find.text(scenario.note), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '承認'), findsNothing);
      expect(find.widgetWithText(OutlinedButton, '却下'), findsNothing);
    }
  });

  testWidgets('admin rejection clears the reviewed request after confirmation',
      (tester) async {
    final service = _FakeAdminReviewService(
      canReviewValue: true,
      request: _request(now),
    );

    await tester.pumpWidget(_testApp(service));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField),
      'LSK-ABCD-2345',
    );
    await tester.tap(find.text('申請を確認'));
    await tester.pumpAndSettle();

    final rejectButton = find.widgetWithText(OutlinedButton, '却下');
    await tester.ensureVisible(rejectButton);
    await tester.pumpAndSettle();
    await tester.tap(rejectButton);
    await tester.pumpAndSettle();

    expect(find.text('このプロフィール連携を却下しますか？'), findsOneWidget);

    await tester.tap(find.text('却下する'));
    await tester.pumpAndSettle();

    expect(service.rejectCalls, 1);
    expect(find.text('プロフィール連携を却下しました。'), findsOneWidget);
    expect(find.text('899212'), findsNothing);
  });

  testWidgets('admin approval clears the reviewed request after confirmation',
      (tester) async {
    final service = _FakeAdminReviewService(
      canReviewValue: true,
      request: _request(now),
    );

    await tester.pumpWidget(_testApp(service));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextFormField),
      'LSK-ABCD-2345',
    );
    await tester.tap(find.text('申請を確認'));
    await tester.pumpAndSettle();

    final approveButton = find.widgetWithText(FilledButton, '承認');
    await tester.ensureVisible(approveButton);
    await tester.pumpAndSettle();
    await tester.tap(approveButton);
    await tester.pumpAndSettle();

    expect(find.text('このプロフィール連携を承認しますか？'), findsOneWidget);

    await tester.tap(find.text('承認する'));
    await tester.pumpAndSettle();

    expect(service.approveCalls, 1);
    expect(find.text('プロフィール連携を承認しました。'), findsOneWidget);
    expect(find.text('899212'), findsNothing);
  });
}

Widget _testApp(TennisBearAdminProfileLinkReviewService service) {
  return MaterialApp(
    locale: const Locale('ja'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: ExternalIdentityAdminReviewScope(
      service: service,
      child: const AdminProfileLinkReviewPage(),
    ),
  );
}

ExternalIdentityLinkRequest _request(
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

class _FakeAdminReviewService
    implements TennisBearAdminProfileLinkReviewService {
  _FakeAdminReviewService({
    required this.canReviewValue,
    this.request,
    DateTime? now,
  }) : now = now ?? DateTime.utc(2026, 9, 15, 1);

  final bool canReviewValue;
  final ExternalIdentityLinkRequest? request;
  final DateTime now;
  int approveCalls = 0;
  int rejectCalls = 0;

  @override
  Future<bool> canReview() async => canReviewValue;

  @override
  Future<ExternalIdentityLinkRequest?> findRequestByConfirmationCode(
    String confirmationCode,
  ) async {
    return request;
  }

  @override
  TennisBearAdminProfileLinkReviewStatus statusOf(
    ExternalIdentityLinkRequest request,
  ) {
    if (request.state == ExternalIdentityLinkRequestState.pending &&
        request.isConfirmationCodeExpired(now)) {
      return TennisBearAdminProfileLinkReviewStatus.expired;
    }
    return switch (request.state) {
      ExternalIdentityLinkRequestState.pending =>
        TennisBearAdminProfileLinkReviewStatus.pending,
      ExternalIdentityLinkRequestState.approved
          when request.unlinkedAt != null =>
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

  @override
  bool canDecide(ExternalIdentityLinkRequest request) {
    return statusOf(request) == TennisBearAdminProfileLinkReviewStatus.pending;
  }

  @override
  Future<ExternalIdentityMapping> approve(String confirmationCode) async {
    approveCalls += 1;
    final reviewed = request!;
    final now = DateTime.utc(2026, 9, 15, 1);
    return ExternalIdentityMapping(
      id: reviewed.identity.mappingId,
      identity: reviewed.identity,
      lanskeUserId: reviewed.lanskeUserId,
      requestId: reviewed.id,
      approvedAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<void> reject(String confirmationCode) async {
    rejectCalls += 1;
  }
}
