import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/auth_session.dart';
import 'auth_repository.dart';

class AuthSessionController extends ChangeNotifier {
  AuthSessionController(this._repository)
    : _session = _repository.currentSession {
    _subscription = _repository.sessionChanges().listen(
      _handleSessionChanged,
      onError: _handleSessionError,
    );
  }

  final AuthRepository _repository;
  late final StreamSubscription<AuthSession> _subscription;

  AuthSession _session;
  Object? _lastError;
  Future<AuthSession>? _ensureAnonymousFuture;

  AuthSession get session => _session;
  Object? get lastError => _lastError;

  Future<AuthSession> ensureAnonymousSession() {
    if (_session.isSignedIn) {
      return Future<AuthSession>.value(_session);
    }

    final pending = _ensureAnonymousFuture;
    if (pending != null) {
      return pending;
    }

    late final Future<AuthSession> future;
    future = _ensureAnonymous().whenComplete(() {
      if (identical(_ensureAnonymousFuture, future)) {
        _ensureAnonymousFuture = null;
      }
    });
    _ensureAnonymousFuture = future;
    return future;
  }

  Future<void> signOut() async {
    try {
      await _repository.signOut();
      _setSession(_repository.currentSession);
    } catch (error) {
      _setError(error);
      rethrow;
    }
  }

  Future<AuthSession> _ensureAnonymous() async {
    try {
      final session = await _repository.ensureAnonymousSession();
      _setSession(session);
      return session;
    } catch (error) {
      _setError(error);
      rethrow;
    }
  }

  void _handleSessionChanged(AuthSession session) {
    _setSession(session);
  }

  void _handleSessionError(Object error, StackTrace stackTrace) {
    _setError(error);
  }

  void _setSession(AuthSession session) {
    final changed = _session != session || _lastError != null;
    _session = session;
    _lastError = null;
    if (changed) {
      notifyListeners();
    }
  }

  void _setError(Object error) {
    _lastError = error;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
