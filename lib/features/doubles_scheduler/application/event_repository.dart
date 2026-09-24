import '../domain/saved_event_models.dart';
import '../presentation/models/event_draft.dart';

abstract class EventRepository {
  Future<SavedEventAggregate> createFromDraft(
    EventDraft draft, {
    required String ownerUid,
  });

  Future<SavedEventAggregate?> findByPublicId(String publicId);

  Future<List<SavedEventAggregate>> listByOwnerUid(String ownerUid);

  Future<List<SavedEventPlayer>> listPlayers(String eventId);

  Future<SavedEvent> updateCurrentGeneratedScheduleId({
    required String eventId,
    required String generatedScheduleId,
  });

  Future<SavedEvent> updateAdoptedGeneratedScheduleId({
    required String eventId,
    required String generatedScheduleId,
  });

  Future<SavedEventAggregate> updateDisplayInfo({
    required String publicId,
    required int expectedDisplayRevision,
    required String title,
    required String memo,
    required Map<String, String> playerDisplayNamesById,
  }) {
    throw UnimplementedError('updateDisplayInfo is not implemented');
  }

  Future<SavedEventAggregate> updateCourtSettings({
    required String eventId,
    required List<SavedEventCourtSetting> courtSettings,
  });

  Future<SavedEventAggregate> updateCourtSettingsWithRevision({
    required String eventId,
    required int expectedCourtSettingsRevision,
    required List<SavedEventCourtSetting> courtSettings,
  }) {
    throw UnimplementedError(
      'updateCourtSettingsWithRevision is not implemented',
    );
  }
}

class EventRevisionConflictException implements Exception {
  const EventRevisionConflictException({
    required this.eventId,
    required this.expectedRevision,
    required this.actualRevision,
  });

  final String eventId;
  final int expectedRevision;
  final int actualRevision;

  @override
  String toString() {
    return 'EventRevisionConflictException('
        'eventId: $eventId, '
        'expectedRevision: $expectedRevision, '
        'actualRevision: $actualRevision'
        ')';
  }
}
