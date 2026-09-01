import 'lanske_user.dart';

enum AccountTransitionProvider {
  emailPassword,
  google,
}

enum AccountTransitionStatus {
  linked,
  existingAccountCollision,
}

class AccountTransitionResult {
  const AccountTransitionResult.linked({
    required this.sourceUid,
    required this.provider,
    required this.user,
  }) : status = AccountTransitionStatus.linked;

  const AccountTransitionResult.existingAccountCollision({
    required this.sourceUid,
    required this.provider,
  })  : status = AccountTransitionStatus.existingAccountCollision,
        user = null;

  final AccountTransitionStatus status;
  final String sourceUid;
  final AccountTransitionProvider provider;
  final LanskeUser? user;

  bool get isLinked => status == AccountTransitionStatus.linked;
  bool get requiresOwnershipMigration =>
      status == AccountTransitionStatus.existingAccountCollision;
}
