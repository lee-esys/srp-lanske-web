import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/auth/application/account_auth_repository.dart';
import 'package:srp_lanske/features/auth/application/current_account_plan_reader.dart';
import 'package:srp_lanske/features/auth/application/lanske_user_repository.dart';
import 'package:srp_lanske/features/auth/domain/auth_session.dart';
import 'package:srp_lanske/features/auth/domain/lanske_plan.dart';
import 'package:srp_lanske/features/auth/domain/lanske_user.dart';

void main() {
  test('returns no plan for a signed-out session', () async {
    final users = FakeLanskeUserRepository();
    final reader = CurrentAccountPlanReader(
      authRepository: FakeAccountAuthRepository(
        const AuthSession.signedOut(),
      ),
      userRepository: users,
    );

    expect(await reader.readCurrentPlan(), isNull);
    expect(users.ensuredUids, isEmpty);
  });

  test('returns no plan for an anonymous session', () async {
    final users = FakeLanskeUserRepository();
    final reader = CurrentAccountPlanReader(
      authRepository: FakeAccountAuthRepository(
        const AuthSession.anonymous('anonymous-uid'),
      ),
      userRepository: users,
    );

    expect(await reader.readCurrentPlan(), isNull);
    expect(users.ensuredUids, isEmpty);
  });

  test('returns the current registered account plan', () async {
    final users = FakeLanskeUserRepository(plan: LanskePlan.premium);
    final reader = CurrentAccountPlanReader(
      authRepository: FakeAccountAuthRepository(
        const AuthSession.account('account-uid'),
      ),
      userRepository: users,
    );

    expect(await reader.readCurrentPlan(), LanskePlan.premium);
    expect(users.ensuredUids, ['account-uid']);
  });
}

class FakeAccountAuthRepository implements AccountAuthRepository {
  FakeAccountAuthRepository(this.currentSession);

  @override
  final AuthSession currentSession;

  @override
  Future<AuthSession> createAccountWithEmailPassword({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuthSession> linkAnonymousWithEmailPassword({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuthSession> linkAnonymousWithGoogle() => throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      throw UnimplementedError();

  @override
  Future<AuthSession> signInWithEmailPassword({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuthSession> signInWithGoogle() => throw UnimplementedError();
}

class FakeLanskeUserRepository implements LanskeUserRepository {
  FakeLanskeUserRepository({
    this.plan = LanskePlan.free,
  });

  final LanskePlan plan;
  final List<String> ensuredUids = [];

  @override
  Future<LanskeUser> ensureUser(String uid) async {
    ensuredUids.add(uid);
    return LanskeUser(
      uid: uid,
      schemaVersion: LanskeUser.currentSchemaVersion,
      createdAt: DateTime.utc(2026, 9, 15),
      plan: plan,
    );
  }
}
