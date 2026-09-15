import 'lanske_plan.dart';

final class EntitlementFeature {
  const EntitlementFeature(this.key) : assert(key != '');

  final String key;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is EntitlementFeature && other.key == key;
  }

  @override
  int get hashCode => key.hashCode;

  @override
  String toString() => 'EntitlementFeature($key)';
}

final class Entitlement {
  const Entitlement.unavailable()
      : available = false,
        usageLimit = null;

  const Entitlement.available({
    this.usageLimit,
  })  : assert(usageLimit == null || usageLimit >= 0),
        available = true;

  final bool available;

  /// Maximum usage allowed for the feature.
  ///
  /// This value is meaningful only when [available] is true. A null value
  /// means that the entitlement itself does not impose a usage limit.
  final int? usageLimit;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Entitlement &&
            other.available == available &&
            other.usageLimit == usageLimit;
  }

  @override
  int get hashCode => Object.hash(available, usageLimit);

  @override
  String toString() {
    return 'Entitlement(available: $available, usageLimit: $usageLimit)';
  }
}

final class EntitlementContext {
  const EntitlementContext({
    required this.plan,
    required this.isAdmin,
  });

  final LanskePlan? plan;
  final bool isAdmin;
}
