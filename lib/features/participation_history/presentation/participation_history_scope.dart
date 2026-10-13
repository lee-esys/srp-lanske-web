import 'package:flutter/widgets.dart';

import '../application/participation_history_service.dart';

class ParticipationHistoryScope extends InheritedWidget {
  const ParticipationHistoryScope({
    super.key,
    required this.service,
    required super.child,
  });

  final ParticipationHistoryService service;

  static ParticipationHistoryService of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<ParticipationHistoryScope>();
    assert(scope != null, 'ParticipationHistoryScope is missing.');
    return scope!.service;
  }

  @override
  bool updateShouldNotify(ParticipationHistoryScope oldWidget) =>
      service != oldWidget.service;
}
