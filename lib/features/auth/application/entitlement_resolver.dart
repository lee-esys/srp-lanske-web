import '../domain/entitlement.dart';

abstract interface class EntitlementResolver {
  Future<Entitlement> resolve(EntitlementFeature feature);
}

typedef EntitlementRule = Entitlement Function(EntitlementContext context);
