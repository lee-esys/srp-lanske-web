import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../application/auth_repository.dart';
import '../domain/auth_session.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository(this._auth);

  final firebase.FirebaseAuth _auth;

  @override
  AuthSession get currentSession => _toSession(_auth.currentUser);

  @override
  Stream<AuthSession> sessionChanges() {
    return _auth.authStateChanges().map(_toSession);
  }

  @override
  Future<AuthSession> ensureAnonymousSession() async {
    final currentUser = _auth.currentUser;
    if (currentUser != null) {
      return _toSession(currentUser);
    }

    final credential = await _auth.signInAnonymously();
    final user = credential.user;
    if (user == null) {
      throw StateError('Anonymous sign-in completed without a Firebase user.');
    }
    return _toSession(user);
  }

  @override
  Future<void> signOut() => _auth.signOut();

  AuthSession _toSession(firebase.User? user) {
    if (user == null) {
      return const AuthSession.signedOut();
    }
    if (user.isAnonymous) {
      return AuthSession.anonymous(user.uid);
    }
    return AuthSession.account(user.uid);
  }
}
