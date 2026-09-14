import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/auth/application/admin_role_reader.dart';

void main() {
  test('admin claim is granted only by boolean true', () {
    expect(hasAdminRoleClaim({'admin': true}), isTrue);
    expect(hasAdminRoleClaim({'admin': false}), isFalse);
    expect(hasAdminRoleClaim({'admin': 'true'}), isFalse);
    expect(hasAdminRoleClaim({'admin': 1}), isFalse);
    expect(hasAdminRoleClaim(const {}), isFalse);
    expect(hasAdminRoleClaim(null), isFalse);
  });
}
