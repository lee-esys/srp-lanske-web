import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/auth/application/auth_repository.dart';
import 'package:srp_lanske/features/auth/application/auth_session_controller.dart';
import 'package:srp_lanske/features/auth/domain/auth_session.dart';

void main() {
  test('does not create an anonymous session on controller startup', () async {
    final repository = FakeAuthRepository();
    final controller = AuthSessionController(repository);
    addTearDown(() async {
      controller.dispose();
      await repository.close();
    });

    expect(controller.session, const AuthSession.signedOut());
    expect(repository.ensureAnonymousCalls, 0);
  });

  test('tracks session changes from the repository', () async {
    final repository = FakeAuthRepository();
    final controller = AuthSessionController(repository);
    addTearDown(() async {
      controller.dispose();
      await repository.close();
    });

    repository.emit(const AuthSession.anonymous('anonymous-uid'));

    expect(
      controller.session,
      const AuthSession.anonymous('anonymous-uid'),
    );
  });

  test('creates an anonymous session lazily and coalesces concurrent calls', () async {
    final repository = FakeAuthRepository();
    final completer = Completer<AuthSession>();
    repository.ensureAnonymousHandler = () async {
      final session = await completer.future;
      repository.emit(session);
      return session;
    };
    final controller = AuthSessionController(repository);
    addTearDown(() async {
      controller.dispose();
      await repository.close();
    });

    final first = controller.ensureAnonymousSession();
    final second = controller.ensureAnonymousSession();

    expect(repository.ensureAnonymousCalls, 1);

    const session = AuthSession.anonymous('anonymous-uid');
    completer.complete(session);

    expect(await first, session);
    expect(await second, session);
    expect(controller.session, session);
  });

  test('does not create another anonymous user when already signed in', () async {
    final repository = FakeAuthRepository(
      initialSession: const AuthSession.anonymous('anonymous-uid'),
    );
    final controller = AuthSessionController(repository);
    addTearDown(() async {
      controller.dispose();
      await repository.close();
    });

    final session = await controller.ensureAnonymousSession();

    expect(session, const AuthSession.anonymous('anonymous-uid'));
    expect(repository.ensureAnonymousCalls, 0);
  });

  test('sign out returns the controller to signed-out state', () async {
    final repository = FakeAuthRepository(
      initialSession: const AuthSession.account('account-uid'),
    );
    final controller = AuthSessionController(repository);
    addTearDown(() async {
      controller.dispose();
      await repository.close();
    });

    await controller.signOut();

    expect(repository.signOutCalls, 1);
    expect(controller.session, const AuthSession.signedOut());
  });

  test('keeps auth errors observable without changing the current session', () async {
    final repository = FakeAuthRepository();
    repository.ensureAnonymousHandler = () async {
      throw StateError('anonymous sign-in failed');
    };
    final controller = AuthSessionController(repository);
    addTearDown(() async {
      controller.dispose();
      await repository.close();
    });

    await expectLater(
      controller.ensureAnonymousSession(),
      throwsA(isA<StateError>()),
    );

    expect(controller.session, const AuthSession.signedOut());
    expect(controller.lastError, isA<StateError>());
  });
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    AuthSession initialSession = const AuthSession.signedOut(),
  }) : _currentSession = initialSession;

  final StreamController<AuthSession> _sessionController =
      StreamController<AuthSession>.broadcast(sync: true);

  AuthSession _currentSession;
  int ensureAnonymousCalls = 0;
  int signOutCalls = 0;
  Future<AuthSession> Function()? ensureAnonymousHandler;

  @override
  AuthSession get currentSession => _currentSession;

  @override
  Stream<AuthSession> sessionChanges() => _sessionController.stream;

  @override
  Future<AuthSession> ensureAnonymousSession() async {
    ensureAnonymousCalls += 1;
    final handler = ensureAnonymousHandler;
    if (handler != null) {
      return handler();
    }

    const session = AuthSession.anonymous('anonymous-uid');
    emit(session);
    return session;
  }

  @override
  Future<void> signOut() async {
    signOutCalls += 1;
    emit(const AuthSession.signedOut());
  }

  void emit(AuthSession session) {
    _currentSession = session;
    _sessionController.add(session);
  }

  Future<void> close() => _sessionController.close();
}
