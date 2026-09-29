import '../domain/saved_event_models.dart';
import '../presentation/models/event_draft.dart';

abstract class EventRepository {
  Future<SavedEventAggregate> createFromDraft(
    EventDraft draft, {
    required String ownerUid,
  });

  Future<SavedEventAggregate?> findByPublicId(String publicId);

  Future<List<SavedEventAggregate>> listByOwnerUid(String ownerUid) {
    throw UnimplementedError('listByOwnerUid is not implemented');
  }

  Future<List<SavedEventPlayer>> listPlayers(String publicId);

  Future<SavedEvent> updateCurrentGeneratedScheduleId({
    required String publicId,
    required String generatedScheduleId,
  });

  Future<SavedEvent> updateCurrentGeneratedScheduleIdIfCurrent({
    required String publicId,
    required String? expectedCurrentGeneratedScheduleId,
    required String generatedScheduleId,
  }) {
    throw UnimplementedError(
      'updateCurrentGeneratedScheduleIdIfCurrent is not implemented',
    );
  }

  Future<SavedEvent> updateAdoptedGeneratedScheduleId({
    required String publicId,
    required String generatedScheduleId,
  });

  Future<SavedEvent> updateAdoptedGeneratedScheduleIdIfCurrent({
    required String publicId,
    required String expectedCurrentGeneratedScheduleId,
  }) {
    throw UnimplementedError(
      'updateAdoptedGeneratedScheduleIdIfCurrent is not implemented',
    );
  }

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
    required String publicId,
    required List<SavedEventCourtSetting> courtSettings,
  });

  Future<SavedEventAggregate> updateCourtSettingsWithRevision({
    required String publicId,
    required int expectedCourtSettingsRevision,
    required List<SavedEventCourtSetting> courtSettings,
  }) {
    throw UnimplementedError(
      'updateCourtSettingsWithRevision is not implemented',
    );
  }

  Future<SavedEventAggregate> transferOwner({
    required String publicId,
    required String expectedSourceUid,
    required String targetUid,
  }) {
    throw UnimplementedError('transferOwner is not implemented');
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


class ScheduleStateConflictException implements Exception {
  const ScheduleStateConflictException({
    required this.eventId,
    required this.expectedCurrentGeneratedScheduleId,
    required this.actualCurrentGeneratedScheduleId,
    required this.actualAdoptedGeneratedScheduleId,
    required this.actualStatus,
  });

  final String eventId;
  final String? expectedCurrentGeneratedScheduleId;
  final String? actualCurrentGeneratedScheduleId;
  final String? actualAdoptedGeneratedScheduleId;
  final SavedEventStatus actualStatus;

  bool get isAlreadyAdopted {
    return actualStatus == SavedEventStatus.adopted ||
        actualAdoptedGeneratedScheduleId != null;
  }

  @override
  String toString() {
    return 'ScheduleStateConflictException('
        'eventId: $eventId, '
        'expectedCurrentGeneratedScheduleId: '
        '$expectedCurrentGeneratedScheduleId, '
        'actualCurrentGeneratedScheduleId: $actualCurrentGeneratedScheduleId, '
        'actualAdoptedGeneratedScheduleId: $actualAdoptedGeneratedScheduleId, '
        'actualStatus: ${actualStatus.name}'
        ')';
  }
}
