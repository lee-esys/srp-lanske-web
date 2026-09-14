abstract interface class AdminRoleReader {
  Future<bool> isCurrentUserAdmin({bool forceRefresh = false});
}

bool hasAdminRoleClaim(Map<String, dynamic>? claims) {
  return claims?['admin'] == true;
}
