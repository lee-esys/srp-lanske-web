import 'package:flutter/widgets.dart';

import '../application/tennisbear_profile_link_service.dart';

class ExternalIdentityLinkScope extends InheritedWidget {
  const ExternalIdentityLinkScope({
    super.key,
    required this.service,
    required super.child,
  });

  final TennisBearProfileLinkService service;

  static TennisBearProfileLinkService of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ExternalIdentityLinkScope>();
    assert(scope != null, 'ExternalIdentityLinkScope is missing.');
    return scope!.service;
  }

  @override
  bool updateShouldNotify(ExternalIdentityLinkScope oldWidget) {
    return service != oldWidget.service;
  }
}
