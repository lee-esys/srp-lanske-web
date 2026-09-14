import 'package:flutter/widgets.dart';

import '../application/admin_role_reader.dart';

class AdminRoleScope extends InheritedWidget {
  const AdminRoleScope({
    super.key,
    required this.reader,
    required super.child,
  });

  final AdminRoleReader reader;

  static AdminRoleReader of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AdminRoleScope>();
    if (scope == null) {
      throw FlutterError('AdminRoleScope was not found in the widget tree.');
    }
    return scope.reader;
  }

  @override
  bool updateShouldNotify(AdminRoleScope oldWidget) {
    return !identical(reader, oldWidget.reader);
  }
}
