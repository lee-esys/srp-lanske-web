enum AuthSessionKind {
  signedOut,
  anonymous,
  account,
}

class AuthSession {
  const AuthSession._({
    required this.kind,
    this.uid,
    this.email,
    this.displayName,
    this.photoUrl,
  });

  const AuthSession.signedOut() : this._(kind: AuthSessionKind.signedOut);

  const AuthSession.anonymous(String uid)
      : this._(
          kind: AuthSessionKind.anonymous,
          uid: uid,
        );

  const AuthSession.account(
    String uid, {
    String? email,
    String? displayName,
    String? photoUrl,
  }) : this._(
          kind: AuthSessionKind.account,
          uid: uid,
          email: email,
          displayName: displayName,
          photoUrl: photoUrl,
        );

  final AuthSessionKind kind;
  final String? uid;
  final String? email;
  final String? displayName;
  final String? photoUrl;

  bool get isSignedIn => uid != null;
  bool get isAnonymous => kind == AuthSessionKind.anonymous;
  bool get isAccount => kind == AuthSessionKind.account;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is AuthSession &&
            other.kind == kind &&
            other.uid == uid &&
            other.email == email &&
            other.displayName == displayName &&
            other.photoUrl == photoUrl;
  }

  @override
  int get hashCode => Object.hash(kind, uid, email, displayName, photoUrl);

  @override
  String toString() => 'AuthSession(kind: $kind, uid: $uid)';
}
