import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/auth/domain/entitlement.dart';

void main() {
  test('feature keys compare by key', () {
    expect(
      const EntitlementFeature('feature-a'),
      const EntitlementFeature('feature-a'),
    );
    expect(
      const EntitlementFeature('feature-a'),
      isNot(const EntitlementFeature('feature-b')),
    );
  });

  test('unavailable entitlement has no usage limit', () {
    const entitlement = Entitlement.unavailable();

    expect(entitlement.available, isFalse);
    expect(entitlement.usageLimit, isNull);
  });

  test('available entitlement can be unlimited', () {
    const entitlement = Entitlement.available();

    expect(entitlement.available, isTrue);
    expect(entitlement.usageLimit, isNull);
  });

  test('available entitlement can expose a finite usage limit', () {
    const entitlement = Entitlement.available(usageLimit: 10);

    expect(entitlement.available, isTrue);
    expect(entitlement.usageLimit, 10);
  });
}
