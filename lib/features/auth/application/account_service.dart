import '../domain/account_transition.dart';
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

  static const Set<String> _existingAccountCollisionCodes = <String>{
    'credential-already-in-use',
    'email-already-in-use',
    'account-exists-with-different-credential',
  };

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

  Future<AccountTransitionResult> linkAnonymousWithEmailPassword({
    required String email,
    required String password,
  }) {
    return _linkAnonymous(
      provider: AccountTransitionProvider.emailPassword,
      link: () => _authRepository.linkAnonymousWithEmailPassword(
        email: email,
        password: password,
      ),
    );
  }

  Future<AccountTransitionResult> linkAnonymousWithGoogle() {
    return _linkAnonymous(
      provider: AccountTransitionProvider.google,
      link: _authRepository.linkAnonymousWithGoogle,
    );
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _authRepository.sendPasswordResetEmail(email);
  }

  Future<LanskeUser> ensureCurrentUser() {
    return _ensureUserForAccountSession(_authRepository.currentSession);
  }

  Future<AccountTransitionResult> _linkAnonymous({
    required AccountTransitionProvider provider,
    required Future<AuthSession> Function() link,
  }) async {
    final sourceUid = _requireAnonymousUid();

    try {
      final linkedSession = await link();
      if (!linkedSession.isAccount || linkedSession.uid != sourceUid) {
        throw StateError(
          'Anonymous account link changed the Firebase UID unexpectedly.',
        );
      }

      final user = await _ensureUserForAccountSession(linkedSession);
      return AccountTransitionResult.linked(
        sourceUid: sourceUid,
        provider: provider,
        user: user,
      );
    } on AccountAuthException catch (error) {
      if (!_existingAccountCollisionCodes.contains(error.code)) {
        rethrow;
      }

      _ensureAnonymousSessionPreserved(sourceUid);
      return AccountTransitionResult.existingAccountCollision(
        sourceUid: sourceUid,
        provider: provider,
      );
    }
  }

  String _requireAnonymousUid() {
    final session = _authRepository.currentSession;
    final uid = session.uid;
    if (!session.isAnonymous || uid == null) {
      throw const AccountTransitionRequiredException();
    }
    return uid;
  }

  void _ensureAnonymousSessionPreserved(String sourceUid) {
    final session = _authRepository.currentSession;
    if (!session.isAnonymous || session.uid != sourceUid) {
      throw StateError(
        'Anonymous session changed while handling an account collision.',
      );
    }
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
