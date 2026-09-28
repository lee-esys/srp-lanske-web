import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/auth/application/account_auth_repository.dart';
import 'package:srp_lanske/features/auth/application/account_service.dart';
import 'package:srp_lanske/features/auth/application/admin_role_reader.dart';
import 'package:srp_lanske/features/auth/application/anonymous_event_ownership_transfer_service.dart';
import 'package:srp_lanske/features/auth/application/auth_repository.dart';
import 'package:srp_lanske/features/auth/application/event_ownership_transfer_handoff_store.dart';
import 'package:srp_lanske/features/auth/application/event_ownership_transfer_repository.dart';
import 'package:srp_lanske/features/auth/application/lanske_user_repository.dart';
import 'package:srp_lanske/features/auth/domain/auth_session.dart';
import 'package:srp_lanske/features/auth/domain/event_ownership_transfer.dart';
import 'package:srp_lanske/features/auth/domain/lanske_user.dart';
import 'package:srp_lanske/features/auth/presentation/account_page.dart';
import 'package:srp_lanske/features/auth/presentation/account_scope.dart';
import 'package:srp_lanske/features/auth/presentation/admin_role_scope.dart';
import 'package:srp_lanske/features/auth/presentation/auth_scope.dart';
import 'package:srp_lanske/features/doubles_scheduler/data/in_memory_event_repository.dart';
import 'package:srp_lanske/l10n/l10n.dart';

void main() {
  final now = DateTime.utc(2026, 9, 28, 1);

  testWidgets('prepared anonymous handoff shows safe account switch actions',
      (tester) async {
    final auth = _FakeAuthRepository(
      const AuthSession.anonymous('source-anon'),
    );
    final handoffs = _FakeHandoffStore()
      ..value = EventOwnershipTransferHandoff(
        sourceUid: 'source-anon',
        handoffSecret: 'handoff-secret',
        expiresAt: now.add(const Duration(hours: 1)),
      );

    await tester.pumpWidget(
      _app(
        auth: auth,
        handoffs: handoffs,
        now: now,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('既存アカウントへの引継ぎ準備ができました'), findsOneWidget);
    expect(find.text('既存アカウントへ切り替えて引き継ぐ'), findsOneWidget);
    expect(find.text('今は引き継がない'), findsOneWidget);

    await tester.tap(find.text('今は引き継がない'));
    await tester.pumpAndSettle();

    expect(handoffs.value, isNull);
    expect(find.text('ログインなしで利用中'), findsOneWidget);
  });

  testWidgets(
      'replacement anonymous session can be signed out but cannot cancel source handoff',
      (tester) async {
    final auth = _FakeAuthRepository(
      const AuthSession.anonymous('replacement-anon'),
    );
    final handoffs = _FakeHandoffStore()
      ..value = EventOwnershipTransferHandoff(
        sourceUid: 'source-anon',
        handoffSecret: 'handoff-secret',
        expiresAt: now.add(const Duration(hours: 1)),
      );

    await tester.pumpWidget(
      _app(
        auth: auth,
        handoffs: handoffs,
        now: now,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('既存アカウントへ切り替えて引き継ぐ'), findsOneWidget);
    expect(find.text('今は引き継がない'), findsNothing);

    await tester.tap(find.text('既存アカウントへ切り替えて引き継ぐ'));
    await tester.pumpAndSettle();

    expect(auth.currentSession, const AuthSession.signedOut());
    expect(handoffs.value, isNotNull);
    expect(find.text('既存のLanskeアカウントにログイン'), findsOneWidget);
  });

  testWidgets('signed-out handoff requires existing account login',
      (tester) async {
    final auth = _FakeAuthRepository(const AuthSession.signedOut());
    final handoffs = _FakeHandoffStore()
      ..value = EventOwnershipTransferHandoff(
        sourceUid: 'source-anon',
        handoffSecret: 'handoff-secret',
        expiresAt: now.add(const Duration(hours: 1)),
      );

    await tester.pumpWidget(
      _app(
        auth: auth,
        handoffs: handoffs,
        now: now,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('既存のLanskeアカウントにログイン'), findsOneWidget);
    expect(find.text('新しくアカウントを作成する'), findsNothing);
    expect(find.text('Google でログイン'), findsOneWidget);
  });
}

Widget _app({
  required _FakeAuthRepository auth,
  required _FakeHandoffStore handoffs,
  required DateTime now,
}) {
  final users = _FakeLanskeUserRepository();
  final accountService = AccountService(
    authRepository: auth,
    userRepository: users,
  );
  final transferService = AnonymousEventOwnershipTransferService(
    authRepository: auth,
    eventRepository: InMemoryEventRepository(),
    transferRepository: _FakeTransferRepository(),
    handoffStore: handoffs,
    clock: () => now,
  );

  return MaterialApp(
    locale: const Locale('ja'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: AuthScope(
      repository: auth,
      child: AdminRoleScope(
        reader: _FakeAdminRoleReader(),
        child: AccountScope(
          service: accountService,
          ownershipTransferService: transferService,
          child: const AccountPage(),
        ),
      ),
    ),
  );
}

class _FakeAuthRepository implements AuthRepository, AccountAuthRepository {
  _FakeAuthRepository(this.session);

  AuthSession session;

  @override
  AuthSession get currentSession => session;

  @override
  Stream<AuthSession> sessionChanges() => const Stream<AuthSession>.empty();

  @override
  Future<AuthSession> ensureAnonymousSession() async => session;

  @override
  Future<void> signOut() async {
    session = const AuthSession.signedOut();
  }

  @override
  Future<AuthSession> createAccountWithEmailPassword({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

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

  @override
  Future<AuthSession> signInWithEmailPassword({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuthSession> signInWithGoogle() => throw UnimplementedError();
}

class _FakeLanskeUserRepository implements LanskeUserRepository {
  @override
  Future<LanskeUser> ensureUser(String uid) async {
    return LanskeUser(
      uid: uid,
      schemaVersion: LanskeUser.currentSchemaVersion,
      createdAt: DateTime.utc(2026, 9, 28),
    );
  }
}

class _FakeAdminRoleReader implements AdminRoleReader {
  @override
  Future<bool> isCurrentUserAdmin({bool forceRefresh = false}) async => false;
}

class _FakeTransferRepository implements EventOwnershipTransferRepository {
  @override
  Future<void> prepare({
    required String sourceUid,
    required String handoffSecret,
    required DateTime expiresAt,
  }) async {}

  @override
  Future<void> accept({
    required String sourceUid,
    required String handoffSecret,
    required String targetUid,
    required DateTime acceptedExpiresAt,
  }) async {}

  @override
  Future<void> complete({
    required String sourceUid,
    required String targetUid,
  }) async {}
}

class _FakeHandoffStore implements EventOwnershipTransferHandoffStore {
  EventOwnershipTransferHandoff? value;

  @override
  EventOwnershipTransferHandoff? load() => value;

  @override
  void save(EventOwnershipTransferHandoff handoff) {
    value = handoff;
  }

  @override
  void clear() {
    value = null;
  }
}
