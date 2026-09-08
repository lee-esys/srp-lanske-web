enum ExternalIdentityLinkFailureCode {
  userNotFound,
  requestAlreadyExists,
  requestNotFound,
  identityAlreadyLinked,
  sourceAlreadyLinked,
  invalidState,
  confirmationCodeExpired,
  confirmationCodeNotFound,
  conflict,
}

class ExternalIdentityLinkException implements Exception {
  const ExternalIdentityLinkException(
    this.code, {
    this.message,
  });

  final ExternalIdentityLinkFailureCode code;
  final String? message;

  @override
  String toString() {
    final details = message;
    return details == null
        ? 'ExternalIdentityLinkException($code)'
        : 'ExternalIdentityLinkException($code, $details)';
  }
}
