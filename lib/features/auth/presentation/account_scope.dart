import 'package:flutter/widgets.dart';

import '../application/account_service.dart';
import '../application/anonymous_event_ownership_transfer_service.dart';

class AccountScope extends InheritedWidget {
  const AccountScope({
    super.key,
    required this.service,
    required this.ownershipTransferService,
    required super.child,
  });

  final AccountService service;
  final AnonymousEventOwnershipTransferService ownershipTransferService;

  static AccountService of(BuildContext context) {
    return _scopeOf(context).service;
  }

  static AnonymousEventOwnershipTransferService ownershipTransferOf(
    BuildContext context,
  ) {
    return _scopeOf(context).ownershipTransferService;
  }

  static AccountScope _scopeOf(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AccountScope>();
    if (scope == null) {
      throw FlutterError('AccountScope was not found in the widget tree.');
    }
    return scope;
  }

  @override
  bool updateShouldNotify(AccountScope oldWidget) {
    return !identical(service, oldWidget.service) ||
        !identical(
          ownershipTransferService,
          oldWidget.ownershipTransferService,
        );
  }
}
