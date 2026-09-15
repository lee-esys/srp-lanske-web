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

    final approveButton = find.text('承認');
    await tester.ensureVisible(approveButton);
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

ExternalIdentityLinkRequest _request(DateTime now) {
  return ExternalIdentityLinkRequest(
    id: 'request-1',
    lanskeUserId: 'user-1',
    identity: const ExternalIdentity(
      sourceType: ExternalIdentitySourceType.tennisbear,
      sourceUserId: '899212',
      profileUrl: 'https://www.tennisbear.net/user/899212/info',
    ),
    state: ExternalIdentityLinkRequestState.pending,
    confirmationCodeHash: List<String>.filled(64, 'a').join(),
    confirmationCodeExpiresAt: now.add(const Duration(days: 1)),
    createdAt: now.subtract(const Duration(hours: 1)),
    updatedAt: now.subtract(const Duration(hours: 1)),
  );
}

class _FakeAdminReviewService
    implements TennisBearAdminProfileLinkReviewService {
  _FakeAdminReviewService({
    required this.canReviewValue,
    this.request,
  });

  final bool canReviewValue;
  final ExternalIdentityLinkRequest? request;
  int approveCalls = 0;
  int rejectCalls = 0;

  @override
  Future<bool> canReview() async => canReviewValue;

  @override
  Future<ExternalIdentityLinkRequest?> findReviewableRequest(
    String confirmationCode,
  ) async {
    return request;
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
