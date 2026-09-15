import 'package:flutter/material.dart';

import '../application/admin_role_reader.dart';
import 'admin_role_scope.dart';

class AdminRoleVisibility extends StatefulWidget {
  const AdminRoleVisibility({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  State<AdminRoleVisibility> createState() => _AdminRoleVisibilityState();
}

class _AdminRoleVisibilityState extends State<AdminRoleVisibility> {
  AdminRoleReader? _reader;
  Future<bool>? _isAdminFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reader = AdminRoleScope.of(context);
    if (!identical(_reader, reader)) {
      _reader = reader;
      _isAdminFuture = reader.isCurrentUserAdmin();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdminFuture,
      builder: (context, snapshot) {
        if (snapshot.data != true) {
          return const SizedBox.shrink();
        }
        return widget.child;
      },
    );
  }
}
