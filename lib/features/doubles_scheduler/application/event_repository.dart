import '../domain/saved_event_models.dart';
import '../presentation/models/event_draft.dart';

abstract class EventRepository {
  Future<SavedEventAggregate> createFromDraft(EventDraft draft);

  Future<SavedEventAggregate?> findByPublicId(String publicId);

  Future<List<SavedEventPlayer>> listPlayers(String eventId);

  Future<SavedEvent> updateCurrentGeneratedScheduleId({
    required String eventId,
    required String generatedScheduleId,
  });

  Future<SavedEvent> updateAdoptedGeneratedScheduleId({
    required String eventId,
    required String generatedScheduleId,
  });

  Future<SavedEventAggregate> updateCourtSettings({
    required String eventId,
    required List<SavedEventCourtSetting> courtSettings,
  });
}
