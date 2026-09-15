import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/auth/application/admin_role_reader.dart';
import 'package:srp_lanske/features/auth/application/entitlement_resolver.dart';
import 'package:srp_lanske/features/auth/application/plan_reader.dart';
import 'package:srp_lanske/features/auth/application/role_plan_entitlement_resolver.dart';
import 'package:srp_lanske/features/auth/domain/entitlement.dart';
import 'package:srp_lanske/features/auth/domain/lanske_plan.dart';

void main() {
  const limitedFeature = EntitlementFeature('limited-feature');
  const premiumFeature = EntitlementFeature('premium-feature');
  const unknownFeature = EntitlementFeature('unknown-feature');

  test('unknown feature fails closed without reading role or plan', () async {
    final admin = FakeAdminRoleReader();
    final plan = FakePlanReader();
    final resolver = RolePlanEntitlementResolver(
      adminRoleReader: admin,
      planReader: plan,
      rules: const <EntitlementFeature, EntitlementRule>{},
    );

    expect(
      await resolver.resolve(unknownFeature),
      const Entitlement.unavailable(),
    );
    expect(admin.calls, 0);
    expect(plan.calls, 0);
  });

  test('rule can derive a finite limit from plan', () async {
    final resolver = RolePlanEntitlementResolver(
      adminRoleReader: FakeAdminRoleReader(),
      planReader: FakePlanReader(plan: LanskePlan.free),
      rules: <EntitlementFeature, EntitlementRule>{
        limitedFeature: (context) {
          return switch (context.plan) {
            LanskePlan.premium => const Entitlement.available(usageLimit: 100),
            LanskePlan.free => const Entitlement.available(usageLimit: 10),
            null => const Entitlement.unavailable(),
          };
        },
      },
    );

    expect(
      await resolver.resolve(limitedFeature),
      const Entitlement.available(usageLimit: 10),
    );
  });

  test('rule can grant an admin-specific unlimited entitlement', () async {
    final resolver = RolePlanEntitlementResolver(
      adminRoleReader: FakeAdminRoleReader(isAdmin: true),
      planReader: FakePlanReader(plan: LanskePlan.free),
      rules: <EntitlementFeature, EntitlementRule>{
        limitedFeature: (context) {
          if (context.isAdmin) {
            return const Entitlement.available();
          }
          return const Entitlement.available(usageLimit: 10);
        },
      },
    );

    expect(
      await resolver.resolve(limitedFeature),
      const Entitlement.available(),
    );
  });

  test('admin role does not imply premium entitlement', () async {
    final resolver = RolePlanEntitlementResolver(
      adminRoleReader: FakeAdminRoleReader(isAdmin: true),
      planReader: FakePlanReader(plan: LanskePlan.free),
      rules: <EntitlementFeature, EntitlementRule>{
        premiumFeature: (context) => context.plan == LanskePlan.premium
            ? const Entitlement.available()
            : const Entitlement.unavailable(),
      },
    );

    expect(
      await resolver.resolve(premiumFeature),
      const Entitlement.unavailable(),
    );
  });

  test('rule can deny users without a registered account plan', () async {
    final resolver = RolePlanEntitlementResolver(
      adminRoleReader: FakeAdminRoleReader(),
      planReader: FakePlanReader(),
      rules: <EntitlementFeature, EntitlementRule>{
        premiumFeature: (context) => context.plan == LanskePlan.premium
            ? const Entitlement.available()
            : const Entitlement.unavailable(),
      },
    );

    expect(
      await resolver.resolve(premiumFeature),
      const Entitlement.unavailable(),
    );
  });

  test('resolver passes both plan and role to the rule', () async {
    EntitlementContext? received;
    final resolver = RolePlanEntitlementResolver(
      adminRoleReader: FakeAdminRoleReader(isAdmin: true),
      planReader: FakePlanReader(plan: LanskePlan.premium),
      rules: <EntitlementFeature, EntitlementRule>{
        limitedFeature: (context) {
          received = context;
          return const Entitlement.available();
        },
      },
    );

    await resolver.resolve(limitedFeature);

    expect(received?.plan, LanskePlan.premium);
    expect(received?.isAdmin, isTrue);
  });
}

class FakeAdminRoleReader implements AdminRoleReader {
  FakeAdminRoleReader({
    this.isAdmin = false,
  });

  final bool isAdmin;
  int calls = 0;

  @override
  Future<bool> isCurrentUserAdmin({bool forceRefresh = false}) async {
    calls += 1;
    return isAdmin;
  }
}

class FakePlanReader implements PlanReader {
  FakePlanReader({
    this.plan,
  });

  final LanskePlan? plan;
  int calls = 0;

  @override
  Future<LanskePlan?> readCurrentPlan() async {
    calls += 1;
    return plan;
  }
}
