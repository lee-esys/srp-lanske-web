import '../domain/auth_session.dart';

abstract interface class AuthRepository {
  AuthSession get currentSession;

  Stream<AuthSession> sessionChanges();

  Future<AuthSession> ensureAnonymousSession();

  Future<void> signOut();
}
