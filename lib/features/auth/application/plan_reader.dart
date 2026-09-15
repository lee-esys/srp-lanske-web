import '../domain/lanske_plan.dart';

abstract interface class PlanReader {
  Future<LanskePlan?> readCurrentPlan();
}
