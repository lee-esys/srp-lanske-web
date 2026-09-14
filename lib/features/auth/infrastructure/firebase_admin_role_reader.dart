import 'package:firebase_auth/firebase_auth.dart' as firebase;

import '../application/admin_role_reader.dart';

class FirebaseAdminRoleReader implements AdminRoleReader {
  FirebaseAdminRoleReader(this._auth);

  final firebase.FirebaseAuth _auth;

  @override
  Future<bool> isCurrentUserAdmin({bool forceRefresh = false}) async {
    final user = _auth.currentUser;
    if (user == null || user.isAnonymous) {
      return false;
    }

    final tokenResult = await user.getIdTokenResult(forceRefresh);
    return hasAdminRoleClaim(tokenResult.claims);
  }
}
