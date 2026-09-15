import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/auth/domain/lanske_plan.dart';

void main() {
  group('lanskePlanFromStorage', () {
    test('defaults a missing plan to free for existing accounts', () {
      expect(lanskePlanFromStorage(null), LanskePlan.free);
    });

    test('reads free and premium plans', () {
      expect(lanskePlanFromStorage('free'), LanskePlan.free);
      expect(lanskePlanFromStorage('premium'), LanskePlan.premium);
    });

    test('rejects unknown stored values instead of widening access', () {
      expect(
        () => lanskePlanFromStorage('enterprise'),
        throwsA(isA<StateError>()),
      );
    });
  });

  test('stores plans with stable values', () {
    expect(lanskePlanToStorage(LanskePlan.free), 'free');
    expect(lanskePlanToStorage(LanskePlan.premium), 'premium');
  });
}
