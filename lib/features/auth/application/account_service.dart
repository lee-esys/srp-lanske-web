import '../domain/auth_session.dart';
import '../domain/lanske_user.dart';
import 'account_auth_repository.dart';
import 'lanske_user_repository.dart';

class AccountTransitionRequiredException implements Exception {
  const AccountTransitionRequiredException();
}

class AccountAlreadySignedInException implements Exception {
  const AccountAlreadySignedInException();
}

class AccountService {
  AccountService({
    required AccountAuthRepository authRepository,
    required LanskeUserRepository userRepository,
  })  : _authRepository = authRepository,
        _userRepository = userRepository;

  final AccountAuthRepository _authRepository;
  final LanskeUserRepository _userRepository;

  Future<LanskeUser> createAccountWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _ensureAccountAuthCanStart();
    final session = await _authRepository.createAccountWithEmailPassword(
      email: email,
      password: password,
    );
    return _ensureUserForAccountSession(session);
  }

  Future<LanskeUser> signInWithEmailPassword({
    required String email,
    required String password,
  }) async {
    _ensureAccountAuthCanStart();
    final session = await _authRepository.signInWithEmailPassword(
      email: email,
      password: password,
    );
    return _ensureUserForAccountSession(session);
  }

  Future<LanskeUser> signInWithGoogle() async {
    _ensureAccountAuthCanStart();
    final session = await _authRepository.signInWithGoogle();
    return _ensureUserForAccountSession(session);
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _authRepository.sendPasswordResetEmail(email);
  }

  Future<LanskeUser> ensureCurrentUser() {
    return _ensureUserForAccountSession(_authRepository.currentSession);
  }

  void _ensureAccountAuthCanStart() {
    final session = _authRepository.currentSession;
    if (session.isAnonymous) {
      throw const AccountTransitionRequiredException();
    }
    if (session.isAccount) {
      throw const AccountAlreadySignedInException();
    }
  }

  Future<LanskeUser> _ensureUserForAccountSession(AuthSession session) {
    final uid = session.uid;
    if (!session.isAccount || uid == null) {
      throw StateError('Registered account session is required.');
    }
    return _userRepository.ensureUser(uid);
  }
}
