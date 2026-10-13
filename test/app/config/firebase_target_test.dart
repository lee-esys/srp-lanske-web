import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/app/config/app_config.dart';

void main() {
  test('production and dev Firebase targets are accepted', () {
    expect(() => validateFirebaseProject('prod'), returnsNormally);
    expect(() => validateFirebaseProject('dev'), returnsNormally);
  });

  test('unknown Firebase target is rejected, never falling back to prod', () {
    expect(() => validateFirebaseProject('local'), throwsStateError);
    expect(() => validateFirebaseProject(''), throwsStateError);
  });
}
