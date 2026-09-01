import '../domain/lanske_user.dart';

abstract interface class LanskeUserRepository {
  Future<LanskeUser> ensureUser(String uid);
}
