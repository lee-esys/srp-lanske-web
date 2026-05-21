import 'package:uuid/uuid.dart';

import '../application/event_repository.dart';
import '../domain/public_id.dart';
import '../domain/saved_event_models.dart';
import '../presentation/models/event_draft.dart';
import 'saved_event_json_store.dart';

class JsonEventRepository implements EventRepository {
  JsonEventRepository({
    required SavedEventJsonStore store,
    String Function()? publicIdGenerator,
  })  : _store = store,
        _publicIdGenerator = publicIdGenerator ?? generatePublicId;

  final SavedEventJsonStore _store;
  final String Function() _publicIdGenerator;
  final _uuid = const Uuid();

  @override
  Future<SavedEventAggregate> createFromDraft(EventDraft draft) async {
    final now = DateTime.now();
    final eventId = _uuid.v4();
    final publicId = await _generateUniquePublicId();

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

    final players = draft.players.asMap().entries.map((entry) {
      final index = entry.key;
      final player = entry.value;

      return SavedEventPlayer(
        id: player.id,
        eventId: eventId,
        displayName: player.displayName,
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

    final aggregate = SavedEventAggregate(
      event: event,
      players: players,
      share: share,
      importRecord: importRecord,
    );

    await _saveAggregate(aggregate);

    return aggregate;
  }

  @override
  Future<SavedEventAggregate?> findByPublicId(String publicId) async {
    final data = await _store.findByPublicId(publicId);
    if (data == null) return null;

    return SavedEventAggregate.fromJson(data);
  }

  @override
  Future<List<SavedEventPlayer>> listPlayers(String eventId) async {
    final aggregate = await _findByEventId(eventId);
    return List.unmodifiable(aggregate?.players ?? const []);
  }

  @override
  Future<SavedEvent> updateCurrentGeneratedScheduleId({
    required String eventId,
    required String generatedScheduleId,
  }) async {
    final aggregate = await _findByEventId(eventId);
    if (aggregate == null) {
      throw StateError('event not found: $eventId');
    }

    final event = aggregate.event;
    if (event.hasAdoptedSchedule) {
      throw StateError('event already adopted: $eventId');
    }

    final updatedEvent = event.copyWith(
      status: SavedEventStatus.generated,
      currentGeneratedScheduleId: generatedScheduleId,
      updatedAt: DateTime.now(),
    );

    await _saveAggregate(_replaceEvent(aggregate, updatedEvent));

    return updatedEvent;
  }

  @override
  Future<SavedEvent> updateAdoptedGeneratedScheduleId({
    required String eventId,
    required String generatedScheduleId,
  }) async {
    final aggregate = await _findByEventId(eventId);
    if (aggregate == null) {
      throw StateError('event not found: $eventId');
    }

    final updatedEvent = aggregate.event.copyWith(
      status: SavedEventStatus.adopted,
      currentGeneratedScheduleId: generatedScheduleId,
      adoptedGeneratedScheduleId: generatedScheduleId,
      updatedAt: DateTime.now(),
    );

    await _saveAggregate(_replaceEvent(aggregate, updatedEvent));

    return updatedEvent;
  }

  Future<SavedEventAggregate?> _findByEventId(String eventId) async {
    final data = await _store.findByEventId(eventId);
    if (data == null) return null;

    return SavedEventAggregate.fromJson(data);
  }

  Future<void> _saveAggregate(SavedEventAggregate aggregate) async {
    await _store.saveByPublicId(
      publicId: aggregate.event.publicId,
      data: aggregate.toJson(),
    );
  }

  SavedEventAggregate _replaceEvent(
    SavedEventAggregate aggregate,
    SavedEvent event,
  ) {
    return SavedEventAggregate(
      event: event,
      players: aggregate.players,
      share: aggregate.share,
      importRecord: aggregate.importRecord,
    );
  }

  Future<String> _generateUniquePublicId() async {
    for (var attempt = 0; attempt < 10; attempt += 1) {
      final candidate = _publicIdGenerator();

      if (!isValidPublicId(candidate)) {
        throw StateError('invalid public_id generated: $candidate');
      }

      final existing = await _store.findByPublicId(candidate);
      if (existing == null) {
        return candidate;
      }
    }

    throw StateError('failed to generate unique public_id');
  }
}
