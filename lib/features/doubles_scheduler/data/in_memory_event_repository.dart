import 'package:uuid/uuid.dart';

import '../application/event_repository.dart';
import '../domain/public_id.dart';
import '../domain/saved_event_models.dart';
import '../presentation/models/event_draft.dart';

class InMemoryEventRepository implements EventRepository {
  InMemoryEventRepository({
    String Function()? publicIdGenerator,
  }) : _publicIdGenerator = publicIdGenerator ?? generatePublicId;

  final _uuid = const Uuid();
  final String Function() _publicIdGenerator;

  final Map<String, SavedEvent> _eventsById = {};
  final Map<String, String> _eventIdByPublicId = {};
  final Map<String, List<SavedEventParticipant>> _participantsByEventId = {};
  final Map<String, SavedEventShare> _sharesByPublicId = {};
  final Map<String, SavedEventImport> _importsByEventId = {};

  @override
  Future<SavedEventAggregate> createFromDraft(EventDraft draft) async {
    final now = DateTime.now();
    final eventId = _uuid.v4();
    final publicId = _generateUniquePublicId();

    final event = SavedEvent(
      id: eventId,
      publicId: publicId,
      title: draft.eventName,
      courtCount: draft.courts,
      sourceType:
          draft.url.isEmpty ? EventSourceType.manual : EventSourceType.unknown,
      sourceUrl: draft.url.isEmpty ? null : draft.url,
      status: SavedEventStatus.draft,
      createdAt: now,
      updatedAt: now,
    );

    final participants = draft.participants.asMap().entries.map((entry) {
      final index = entry.key;
      final participant = entry.value;

      return SavedEventParticipant(
        id: participant.id,
        eventId: eventId,
        displayName: participant.displayName,
        orderNo: index + 1,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      );
    }).toList(growable: false);

    final share = SavedEventShare(
      publicId: publicId,
      eventId: eventId,
      createdAt: now,
      updatedAt: now,
    );

    final importRecord = draft.url.isEmpty
        ? null
        : SavedEventImport(
            id: _uuid.v4(),
            eventId: eventId,
            sourceType: EventSourceType.unknown,
            sourceUrl: draft.url,
            createdAt: now,
          );

    _eventsById[eventId] = event;
    _eventIdByPublicId[publicId] = eventId;
    _participantsByEventId[eventId] = participants;
    _sharesByPublicId[publicId] = share;
    if (importRecord != null) {
      _importsByEventId[eventId] = importRecord;
    }

    return SavedEventAggregate(
      event: event,
      participants: participants,
      share: share,
      importRecord: importRecord,
    );
  }

  @override
  Future<SavedEventAggregate?> findByPublicId(String publicId) async {
    final eventId = _eventIdByPublicId[publicId];
    if (eventId == null) return null;

    final event = _eventsById[eventId];
    final share = _sharesByPublicId[publicId];
    if (event == null || share == null) return null;

    return SavedEventAggregate(
      event: event,
      participants: _participantsByEventId[eventId] ?? const [],
      share: share,
      importRecord: _importsByEventId[eventId],
    );
  }

  @override
  Future<List<SavedEventParticipant>> listParticipants(String eventId) async {
    return List.unmodifiable(_participantsByEventId[eventId] ?? const []);
  }

  @override
  Future<SavedEvent> updateCurrentGeneratedScheduleId({
    required String eventId,
    required String generatedScheduleId,
  }) async {
    final event = _eventsById[eventId];
    if (event == null) {
      throw StateError('event not found: $eventId');
    }

    final updated = event.copyWith(
      status: SavedEventStatus.generated,
      currentGeneratedScheduleId: generatedScheduleId,
      updatedAt: DateTime.now(),
    );

    _eventsById[eventId] = updated;
    return updated;
  }

  @override
  Future<SavedEvent> updateAdoptedGeneratedScheduleId({
    required String eventId,
    required String generatedScheduleId,
  }) async {
    final event = _eventsById[eventId];
    if (event == null) {
      throw StateError('event not found: $eventId');
    }

    final updated = event.copyWith(
      status: SavedEventStatus.adopted,
      currentGeneratedScheduleId: generatedScheduleId,
      adoptedGeneratedScheduleId: generatedScheduleId,
      updatedAt: DateTime.now(),
    );

    _eventsById[eventId] = updated;
    return updated;
  }

  String _generateUniquePublicId() {
    for (var attempt = 0; attempt < 10; attempt += 1) {
      final candidate = _publicIdGenerator();

      if (!isValidPublicId(candidate)) {
        throw StateError('invalid public_id generated: $candidate');
      }

      if (!_eventIdByPublicId.containsKey(candidate)) {
        return candidate;
      }
    }

    throw StateError('failed to generate unique public_id');
  }
}
