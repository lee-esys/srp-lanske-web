import '../domain/entitlement.dart';
import 'admin_role_reader.dart';
import 'entitlement_resolver.dart';
import 'plan_reader.dart';

class RolePlanEntitlementResolver implements EntitlementResolver {
  RolePlanEntitlementResolver({
    required AdminRoleReader adminRoleReader,
    required PlanReader planReader,
    required Map<EntitlementFeature, EntitlementRule> rules,
  })  : _adminRoleReader = adminRoleReader,
        _planReader = planReader,
        _rules = Map<EntitlementFeature, EntitlementRule>.unmodifiable(rules);

  final AdminRoleReader _adminRoleReader;
  final PlanReader _planReader;
  final Map<EntitlementFeature, EntitlementRule> _rules;

  @override
  Future<Entitlement> resolve(EntitlementFeature feature) async {
    final rule = _rules[feature];
    if (rule == null) {
      return const Entitlement.unavailable();
    }

    final plan = await _planReader.readCurrentPlan();
    final isAdmin = await _adminRoleReader.isCurrentUserAdmin();

    return rule(
      EntitlementContext(
        plan: plan,
        isAdmin: isAdmin,
      ),
    );
  }
}
