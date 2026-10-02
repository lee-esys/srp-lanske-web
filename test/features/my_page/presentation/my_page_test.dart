import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/auth/application/account_auth_repository.dart';
import 'package:srp_lanske/features/auth/application/account_service.dart';
import 'package:srp_lanske/features/auth/application/auth_repository.dart';
import 'package:srp_lanske/features/auth/application/lanske_user_repository.dart';
import 'package:srp_lanske/features/auth/domain/auth_session.dart';
import 'package:srp_lanske/features/auth/domain/lanske_plan.dart';
import 'package:srp_lanske/features/auth/domain/lanske_user.dart';
import 'package:srp_lanske/features/auth/presentation/auth_scope.dart';
import 'package:srp_lanske/features/my_page/presentation/my_page.dart';
import 'package:srp_lanske/l10n/l10n.dart';

void main() {
  testWidgets('shows account requirement for signed-out users', (tester) async {
    final auth = _FakeAuthRepository(const AuthSession.signedOut());
    final users = _FakeLanskeUserRepository();

    await _pumpMyPage(tester, auth: auth, users: users);

    expect(
      find.text('マイページを利用するにはLanskeアカウントが必要です'),
      findsOneWidget,
    );
    expect(find.text('ログイン・アカウント管理へ'), findsOneWidget);
    expect(users.calls, 0);
  });

  testWidgets('shows account requirement for anonymous users', (tester) async {
    final auth =
        _FakeAuthRepository(const AuthSession.anonymous('anonymous-uid'));
    final users = _FakeLanskeUserRepository();

    await _pumpMyPage(tester, auth: auth, users: users);

    expect(
      find.text('マイページを利用するにはLanskeアカウントが必要です'),
      findsOneWidget,
    );
    expect(users.calls, 0);
  });

  testWidgets('shows safe registered account summary without provider profile',
      (tester) async {
    final auth = _FakeAuthRepository(
      const AuthSession.account(
        'account-uid',
        email: 'user@example.com',
        displayName: 'Provider Display Name',
        photoUrl: 'https://example.com/provider-photo.jpg',
      ),
    );
    final users = _FakeLanskeUserRepository(
      plan: LanskePlan.premium,
      createdAt: DateTime.utc(2026, 9, 15),
    );

    await _pumpMyPage(tester, auth: auth, users: users);
    await tester.pumpAndSettle();

    expect(find.text('Lanskeアカウント'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.text('Premium'), findsOneWidget);
    expect(find.textContaining('利用開始日:'), findsOneWidget);
    expect(find.text('アカウント管理'), findsWidgets);

    expect(find.text('Provider Display Name'), findsNothing);
    expect(users.calls, 1);
    expect(users.ensuredUids, ['account-uid']);
  });

  testWidgets('shows loading while account information is pending',
      (tester) async {
    final auth = _FakeAuthRepository(
      const AuthSession.account(
        'account-uid',
        email: 'user@example.com',
      ),
    );
    final completer = Completer<LanskeUser>();
    final users = _FakeLanskeUserRepository(completer: completer);

    await _pumpMyPage(tester, auth: auth, users: users);
    await tester.pump();

    expect(find.text('アカウント情報を読み込んでいます…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('shows an error and retries account loading', (tester) async {
    final auth = _FakeAuthRepository(
      const AuthSession.account(
        'account-uid',
        email: 'user@example.com',
      ),
    );
    final users = _FakeLanskeUserRepository(failuresBeforeSuccess: 1);

    await _pumpMyPage(tester, auth: auth, users: users);
    await tester.pumpAndSettle();

    expect(find.text('アカウント情報を読み込めませんでした'), findsOneWidget);
    expect(find.text('再読み込み'), findsOneWidget);

    await tester.tap(find.text('再読み込み'));
    await tester.pumpAndSettle();

    expect(find.text('アカウント情報を読み込めませんでした'), findsNothing);
    expect(find.text('Free'), findsOneWidget);
    expect(users.calls, 2);
  });
}

Future<void> _pumpMyPage(
  WidgetTester tester, {
  required _FakeAuthRepository auth,
  required _FakeLanskeUserRepository users,
}) async {
  final accountService = AccountService(
    authRepository: auth,
    userRepository: users,
  );

  await tester.pumpWidget(
    AuthScope(
      repository: auth,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ja'),
        home: MyPage(accountService: accountService),
      ),
    ),
  );
}

class _FakeAuthRepository implements AuthRepository, AccountAuthRepository {
  _FakeAuthRepository(this.currentSession);

  @override
  final AuthSession currentSession;

  @override
  Stream<AuthSession> sessionChanges() => const Stream<AuthSession>.empty();

  @override
  Future<AuthSession> ensureAnonymousSession() => throw UnimplementedError();

  @override
  Future<void> signOut() => throw UnimplementedError();

  @override
  Future<AuthSession> createAccountWithEmailPassword({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuthSession> signInWithEmailPassword({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuthSession> signInWithGoogle() => throw UnimplementedError();

  @override
  Future<AuthSession> linkAnonymousWithEmailPassword({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuthSession> linkAnonymousWithGoogle() => throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      throw UnimplementedError();
}

class _FakeLanskeUserRepository implements LanskeUserRepository {
  _FakeLanskeUserRepository({
    this.plan = LanskePlan.free,
    DateTime? createdAt,
    this.failuresBeforeSuccess = 0,
    this.completer,
  }) : createdAt = createdAt ?? DateTime.utc(2026, 9, 15);

  final LanskePlan plan;
  final DateTime createdAt;
  final int failuresBeforeSuccess;
  final Completer<LanskeUser>? completer;

  int calls = 0;
  final List<String> ensuredUids = [];

  @override
  Future<LanskeUser> ensureUser(String uid) async {
    calls += 1;
    ensuredUids.add(uid);

    final pending = completer;
    if (pending != null) {
      return pending.future;
    }

    if (calls <= failuresBeforeSuccess) {
      throw StateError('load failed');
    }

    return LanskeUser(
      uid: uid,
      schemaVersion: LanskeUser.currentSchemaVersion,
      createdAt: createdAt,
      plan: plan,
    );
  }
}
