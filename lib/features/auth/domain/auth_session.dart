enum AuthSessionKind {
  signedOut,
  anonymous,
  account,
}

class AuthSession {
  const AuthSession._({
    required this.kind,
    this.uid,
  });

  const AuthSession.signedOut() : this._(kind: AuthSessionKind.signedOut);

  const AuthSession.anonymous(String uid)
      : this._(
          kind: AuthSessionKind.anonymous,
          uid: uid,
        );

  const AuthSession.account(String uid)
      : this._(
          kind: AuthSessionKind.account,
          uid: uid,
        );

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
