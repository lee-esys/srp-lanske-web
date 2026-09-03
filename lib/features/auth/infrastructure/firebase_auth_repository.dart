import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/foundation.dart';

import '../application/account_auth_repository.dart';
import '../application/auth_repository.dart';
import '../domain/auth_session.dart';

class FirebaseAuthRepository implements AuthRepository, AccountAuthRepository {
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
  Future<AuthSession> createAccountWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _requireAccountSession(credential.user);
    } on firebase.FirebaseAuthException catch (error) {
      throw _toAccountAuthException(error);
    }
  }

  @override
  Future<AuthSession> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _requireAccountSession(credential.user);
    } on firebase.FirebaseAuthException catch (error) {
      throw _toAccountAuthException(error);
    }
  }

  @override
  Future<AuthSession> signInWithGoogle() async {
    try {
      final provider = firebase.GoogleAuthProvider();
      final credential = kIsWeb
          ? await _auth.signInWithPopup(provider)
          : await _auth.signInWithProvider(provider);
      return _requireAccountSession(credential.user);
    } on firebase.FirebaseAuthException catch (error) {
      throw _toAccountAuthException(error);
    }
  }

  @override
  Future<AuthSession> linkAnonymousWithEmailPassword({
    required String email,
    required String password,
  }) async {
    final credential = firebase.EmailAuthProvider.credential(
      email: email,
      password: password,
    );
    return _linkAnonymousUser(
      (user) => user.linkWithCredential(credential),
    );
  }

  @override
  Future<AuthSession> linkAnonymousWithGoogle() {
    final provider = firebase.GoogleAuthProvider();
    return _linkAnonymousUser(
      (user) => kIsWeb
          ? user.linkWithPopup(provider)
          : user.linkWithProvider(provider),
    );
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase.FirebaseAuthException catch (error) {
      throw _toAccountAuthException(error);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  Future<AuthSession> _linkAnonymousUser(
    Future<firebase.UserCredential> Function(firebase.User user) link,
  ) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null || !currentUser.isAnonymous) {
        throw StateError('An anonymous Firebase user is required for linking.');
      }

      final credential = await link(currentUser);
      final linkedUser = credential.user;
      if (linkedUser == null) {
        throw StateError('Account linking completed without a Firebase user.');
      }

      // Account linking does not reliably emit authStateChanges(). Refresh the
      // token and return the updated session explicitly instead of relying on
      // the auth stream to observe the anonymous -> account transition.
      await linkedUser.getIdToken(true);
      return _requireAccountSession(linkedUser);
    } on firebase.FirebaseAuthException catch (error) {
      throw _toAccountAuthException(error);
    }
  }

  AuthSession _requireAccountSession(firebase.User? user) {
    final session = _toSession(user);
    if (!session.isAccount) {
      throw StateError('Account sign-in completed without a registered user.');
    }
    return session;
  }

  AuthSession _toSession(firebase.User? user) {
    if (user == null) {
      return const AuthSession.signedOut();
    }
    if (user.isAnonymous) {
      return AuthSession.anonymous(user.uid);
    }
    return AuthSession.account(
      user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
    );
  }

  AccountAuthException _toAccountAuthException(
    firebase.FirebaseAuthException error,
  ) {
    return AccountAuthException(
      code: error.code,
      message: error.message,
    );
  }
}
