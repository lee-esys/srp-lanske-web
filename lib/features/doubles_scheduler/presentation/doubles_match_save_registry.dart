import 'package:srp_lanske/features/doubles_scheduler/application/doubles_match_progress_service.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';

typedef DoublesMatchSaveCallback =
    Future<DoublesMatchProgressSaveResult> Function({
  required ScheduleMatchProgress current,
  required DoublesMatchProgressInput input,
});

class DoublesMatchSaveRegistration {
  const DoublesMatchSaveRegistration._({
    required this.generatedScheduleId,
    required this.onSave,
  });

  final String generatedScheduleId;
  final DoublesMatchSaveCallback onSave;
}

abstract final class DoublesMatchSaveRegistry {
  static final Map<String, DoublesMatchSaveRegistration> _registrations = {};

  static DoublesMatchSaveRegistration register({
    required String generatedScheduleId,
    required DoublesMatchSaveCallback onSave,
  }) {
    final registration = DoublesMatchSaveRegistration._(
      generatedScheduleId: generatedScheduleId,
      onSave: onSave,
    );
    _registrations[generatedScheduleId] = registration;
    return registration;
  }

  static void unregister(DoublesMatchSaveRegistration? registration) {
    if (registration == null) {
      return;
    }

    final current = _registrations[registration.generatedScheduleId];
    if (identical(current, registration)) {
      _registrations.remove(registration.generatedScheduleId);
    }
  }

  static DoublesMatchSaveCallback? find(String generatedScheduleId) {
    return _registrations[generatedScheduleId]?.onSave;
  }
}
