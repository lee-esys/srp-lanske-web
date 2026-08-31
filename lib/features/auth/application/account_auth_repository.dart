import '../domain/auth_session.dart';

abstract interface class AccountAuthRepository {
  AuthSession get currentSession;

  Future<AuthSession> createAccountWithEmailPassword({
    required String email,
    required String password,
  });

  Future<AuthSession> signInWithEmailPassword({
    required String email,
    required String password,
  });

  Future<AuthSession> signInWithGoogle();

  Future<void> sendPasswordResetEmail(String email);
}

class AccountAuthException implements Exception {
  const AccountAuthException({
    required this.code,
    this.message,
  });

  final String code;
  final String? message;

  @override
  String toString() => 'AccountAuthException(code: $code)';
}
