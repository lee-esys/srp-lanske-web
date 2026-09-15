import 'package:flutter/widgets.dart';

import '../application/tennisbear_admin_profile_link_review_service.dart';

class ExternalIdentityAdminReviewScope extends InheritedWidget {
  const ExternalIdentityAdminReviewScope({
    super.key,
    required this.service,
    required super.child,
  });

  final TennisBearAdminProfileLinkReviewService service;

  static TennisBearAdminProfileLinkReviewService of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<ExternalIdentityAdminReviewScope>();
    if (scope == null) {
      throw FlutterError(
        'ExternalIdentityAdminReviewScope was not found in the widget tree.',
      );
    }
    return scope.service;
  }

  @override
  bool updateShouldNotify(ExternalIdentityAdminReviewScope oldWidget) {
    return !identical(service, oldWidget.service);
  }
}
