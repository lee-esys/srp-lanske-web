import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/auth/application/account_auth_repository.dart';
import 'package:srp_lanske/features/auth/application/account_service.dart';
import 'package:srp_lanske/features/auth/application/lanske_user_repository.dart';
import 'package:srp_lanske/features/auth/domain/auth_session.dart';
import 'package:srp_lanske/features/auth/domain/lanske_user.dart';

void main() {
  test('creates a Lanske user after email account registration', () async {
    final auth = FakeAccountAuthRepository();
    final users = FakeLanskeUserRepository();
    final service = AccountService(
      authRepository: auth,
      userRepository: users,
    );

    final user = await service.createAccountWithEmailPassword(
      email: 'user@example.com',
      password: 'secret12',
    );

    expect(auth.createCalls, 1);
    expect(users.ensuredUids, ['account-uid']);
    expect(user.uid, 'account-uid');
    expect(auth.currentSession.isAccount, isTrue);
  });

  test('ensures a Lanske user after email login', () async {
    final auth = FakeAccountAuthRepository();
    final users = FakeLanskeUserRepository();
    final service = AccountService(
      authRepository: auth,
      userRepository: users,
    );

    await service.signInWithEmailPassword(
      email: 'user@example.com',
      password: 'secret12',
    );

    expect(auth.emailSignInCalls, 1);
    expect(users.ensuredUids, ['account-uid']);
  });

  test('ensures a Lanske user after Google login', () async {
    final auth = FakeAccountAuthRepository();
    final users = FakeLanskeUserRepository();
    final service = AccountService(
      authRepository: auth,
      userRepository: users,
    );

    await service.signInWithGoogle();

    expect(auth.googleSignInCalls, 1);
    expect(users.ensuredUids, ['account-uid']);
  });

  test('blocks account auth while an anonymous session exists', () async {
    final auth = FakeAccountAuthRepository(
      initialSession: const AuthSession.anonymous('anonymous-uid'),
    );
    final users = FakeLanskeUserRepository();
    final service = AccountService(
      authRepository: auth,
      userRepository: users,
    );

    expect(
      () => service.createAccountWithEmailPassword(
        email: 'user@example.com',
        password: 'secret12',
      ),
      throwsA(isA<AccountTransitionRequiredException>()),
    );
    expect(
      () => service.signInWithEmailPassword(
        email: 'user@example.com',
        password: 'secret12',
      ),
      throwsA(isA<AccountTransitionRequiredException>()),
    );
    expect(
      service.signInWithGoogle,
      throwsA(isA<AccountTransitionRequiredException>()),
    );

    expect(auth.createCalls, 0);
    expect(auth.emailSignInCalls, 0);
    expect(auth.googleSignInCalls, 0);
    expect(users.ensuredUids, isEmpty);
  });

  test('does not replace an already signed-in account', () async {
    final auth = FakeAccountAuthRepository(
      initialSession: const AuthSession.account('existing-uid'),
    );
    final users = FakeLanskeUserRepository();
    final service = AccountService(
      authRepository: auth,
      userRepository: users,
    );

    expect(
      service.signInWithGoogle,
      throwsA(isA<AccountAlreadySignedInException>()),
    );
    expect(auth.googleSignInCalls, 0);
  });

  test('keeps the Firebase account session when user document setup fails', () async {
    final auth = FakeAccountAuthRepository();
    final users = FakeLanskeUserRepository()..error = StateError('write failed');
    final service = AccountService(
      authRepository: auth,
      userRepository: users,
    );

    await expectLater(
      service.signInWithGoogle(),
      throwsA(isA<StateError>()),
    );

    expect(auth.currentSession, const AuthSession.account('account-uid'));
    expect(users.ensuredUids, ['account-uid']);
  });

  test('ensures a restored registered account user', () async {
    final auth = FakeAccountAuthRepository(
      initialSession: const AuthSession.account('restored-uid'),
    );
    final users = FakeLanskeUserRepository();
    final service = AccountService(
      authRepository: auth,
      userRepository: users,
    );

    final user = await service.ensureCurrentUser();

    expect(user.uid, 'restored-uid');
    expect(users.ensuredUids, ['restored-uid']);
  });

  test('delegates password reset without changing auth state', () async {
    final auth = FakeAccountAuthRepository();
    final users = FakeLanskeUserRepository();
    final service = AccountService(
      authRepository: auth,
      userRepository: users,
    );

    await service.sendPasswordResetEmail('user@example.com');

    expect(auth.passwordResetEmails, ['user@example.com']);
    expect(auth.currentSession, const AuthSession.signedOut());
  });
}

class FakeAccountAuthRepository implements AccountAuthRepository {
  FakeAccountAuthRepository({
    AuthSession initialSession = const AuthSession.signedOut(),
  }) : _currentSession = initialSession;

  AuthSession _currentSession;
  int createCalls = 0;
  int emailSignInCalls = 0;
  int googleSignInCalls = 0;
  final List<String> passwordResetEmails = [];

  @override
  AuthSession get currentSession => _currentSession;

  @override
  Future<AuthSession> createAccountWithEmailPassword({
    required String email,
    required String password,
  }) async {
    createCalls += 1;
    _currentSession = AuthSession.account('account-uid', email: email);
    return _currentSession;
  }

  @override
  Future<AuthSession> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    emailSignInCalls += 1;
    _currentSession = AuthSession.account('account-uid', email: email);
    return _currentSession;
  }

  @override
  Future<AuthSession> signInWithGoogle() async {
    googleSignInCalls += 1;
    _currentSession = const AuthSession.account('account-uid');
    return _currentSession;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    passwordResetEmails.add(email);
  }
}

class FakeLanskeUserRepository implements LanskeUserRepository {
  final List<String> ensuredUids = [];
  Object? error;

  @override
  Future<LanskeUser> ensureUser(String uid) async {
    ensuredUids.add(uid);
    final currentError = error;
    if (currentError != null) {
      throw currentError;
    }
    return LanskeUser(
      uid: uid,
      schemaVersion: LanskeUser.currentSchemaVersion,
      createdAt: DateTime.utc(2026, 8, 31),
    );
  }
}
