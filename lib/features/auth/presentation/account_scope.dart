import 'package:flutter/widgets.dart';

import '../application/account_service.dart';

class AccountScope extends InheritedWidget {
  const AccountScope({
    super.key,
    required this.service,
    required super.child,
  });

  final AccountService service;

  static AccountService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AccountScope>();
    if (scope == null) {
      throw FlutterError('AccountScope was not found in the widget tree.');
    }
    return scope.service;
  }

  @override
  bool updateShouldNotify(AccountScope oldWidget) {
    return !identical(service, oldWidget.service);
  }
}
