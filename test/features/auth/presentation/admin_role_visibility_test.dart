import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/auth/application/admin_role_reader.dart';
import 'package:srp_lanske/features/auth/presentation/admin_role_scope.dart';
import 'package:srp_lanske/features/auth/presentation/admin_role_visibility.dart';

void main() {
  testWidgets('shows child only for admin role', (tester) async {
    await tester.pumpWidget(
      _testApp(
        AdminRoleScope(
          reader: _FakeAdminRoleReader(true),
          child: const AdminRoleVisibility(
            child: Text('admin action'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('admin action'), findsOneWidget);
  });

  testWidgets('hides child for non-admin role', (tester) async {
    await tester.pumpWidget(
      _testApp(
        AdminRoleScope(
          reader: _FakeAdminRoleReader(false),
          child: const AdminRoleVisibility(
            child: Text('admin action'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('admin action'), findsNothing);
  });

  testWidgets('fails closed when AdminRoleScope is absent', (tester) async {
    await tester.pumpWidget(
      _testApp(
        const AdminRoleVisibility(
          child: Text('admin action'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('admin action'), findsNothing);
  });
}

Widget _testApp(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

class _FakeAdminRoleReader implements AdminRoleReader {
  _FakeAdminRoleReader(this.isAdmin);

  final bool isAdmin;

  @override
  Future<bool> isCurrentUserAdmin({bool forceRefresh = false}) async {
    return isAdmin;
  }
}
