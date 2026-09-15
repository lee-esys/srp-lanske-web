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
    final reader = maybeOf(context);
    if (reader == null) {
      throw FlutterError('AdminRoleScope was not found in the widget tree.');
    }
    return reader;
  }

  static AdminRoleReader? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<AdminRoleScope>()
        ?.reader;
  }

  @override
  bool updateShouldNotify(AdminRoleScope oldWidget) {
    return !identical(reader, oldWidget.reader);
  }
}
