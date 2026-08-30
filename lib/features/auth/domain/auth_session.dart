enum AuthSessionKind {
  signedOut,
  anonymous,
  account,
}

class AuthSession {
  const AuthSession.signedOut()
    : kind = AuthSessionKind.signedOut,
      uid = null;

  const AuthSession.anonymous(String uid)
    : kind = AuthSessionKind.anonymous,
      uid = uid;

  const AuthSession.account(String uid)
    : kind = AuthSessionKind.account,
      uid = uid;

  final AuthSessionKind kind;
  final String? uid;

  bool get isSignedIn => uid != null;
  bool get isAnonymous => kind == AuthSessionKind.anonymous;
  bool get isAccount => kind == AuthSessionKind.account;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AuthSession && other.kind == kind && other.uid == uid;
  }

  @override
  int get hashCode => Object.hash(kind, uid);

  @override
  String toString() => 'AuthSession(kind: $kind, uid: $uid)';
}
