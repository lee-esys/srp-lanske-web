enum LanskePlan {
  free,
  premium,
}

LanskePlan lanskePlanFromStorage(Object? value) {
  if (value == null || value == 'free') {
    return LanskePlan.free;
  }
  if (value == 'premium') {
    return LanskePlan.premium;
  }
  throw StateError('Invalid Lanske plan value: $value');
}

String lanskePlanToStorage(LanskePlan plan) {
  return switch (plan) {
    LanskePlan.free => 'free',
    LanskePlan.premium => 'premium',
  };
}
