import '../domain/lanske_plan.dart';
import 'account_auth_repository.dart';
import 'lanske_user_repository.dart';
import 'plan_reader.dart';

class CurrentAccountPlanReader implements PlanReader {
  CurrentAccountPlanReader({
    required AccountAuthRepository authRepository,
    required LanskeUserRepository userRepository,
  })  : _authRepository = authRepository,
        _userRepository = userRepository;

  final AccountAuthRepository _authRepository;
  final LanskeUserRepository _userRepository;

  @override
  Future<LanskePlan?> readCurrentPlan() async {
    final session = _authRepository.currentSession;
    final uid = session.uid;
    if (!session.isAccount || uid == null) {
      return null;
    }

    final user = await _userRepository.ensureUser(uid);
    return user.plan;
  }
}
