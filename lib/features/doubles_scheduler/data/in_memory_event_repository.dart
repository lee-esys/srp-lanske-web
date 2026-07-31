import 'package:uuid/uuid.dart';

import '../application/event_repository.dart';
import '../domain/public_id.dart';
import '../domain/saved_event_models.dart';
import '../presentation/models/event_draft.dart';

class InMemoryEventRepository implements EventRepository {
  InMemoryEventRepository({
    String Function()? publicIdGenerator,
    DateTime Function()? clock,
  })  : _publicIdGenerator = publicIdGenerator ?? generatePublicId,
        _clock = clock ?? DateTime.now;

  final _uuid = const Uuid();
  final String Function() _publicIdGenerator;
  final DateTime Function() _clock;

  final Map<String, SavedEvent> _eventsById = {};
  final Map<String, String> _eventIdByPublicId = {};
  final Map<String, List<SavedEventPlayer>> _playersByEventId = {};
  final Map<String, SavedEventShare> _sharesByPublicId = {};
  final Map<String, SavedEventImport> _importsByEventId = {};
  final Map<String, List<SavedEventCourtSetting>> _courtSettingsByEventId = {};

  @override
  Future<SavedEventAggregate> createFromDraft(EventDraft draft) async {
    final now = _clock();
    final eventId = _uuid.v4();
    final publicId = _generateUniquePublicId();
    final courtSettings = buildDefaultCourtSettings(draft.courts);

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
        initialDisplayName: player.displayName,
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

    _eventsById[eventId] = event;
    _eventIdByPublicId[publicId] = eventId;
    _playersByEventId[eventId] = players;
    _sharesByPublicId[publicId] = share;
    if (importRecord != null) {
      _importsByEventId[eventId] = importRecord;
    }
    _courtSettingsByEventId[eventId] = courtSettings;

    return _buildAggregate(event);
  }

  @override
  Future<SavedEventAggregate?> findByPublicId(String publicId) async {
    final eventId = _eventIdByPublicId[publicId];
    if (eventId == null) return null;

    final event = _eventsById[eventId];
    final share = _sharesByPublicId[publicId];
    if (event == null || share == null) return null;

    return _buildAggregate(event);
  }

  @override
  Future<List<SavedEventPlayer>> listPlayers(String eventId) async {
    return List.unmodifiable(_playersByEventId[eventId] ?? const []);
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

    if (event.hasAdoptedSchedule) {
      throw StateError('event already adopted: $eventId');
    }

    final updated = event.copyWith(
      status: SavedEventStatus.generated,
      currentGeneratedScheduleId: generatedScheduleId,
      revision: event.revision + 1,
      updatedAt: _clock(),
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

    final now = _clock();
    final updated = event.copyWith(
      status: SavedEventStatus.adopted,
      currentGeneratedScheduleId: generatedScheduleId,
      adoptedGeneratedScheduleId: generatedScheduleId,
      adoptedAt: now,
      revision: event.revision + 1,
      updatedAt: now,
    );

    _eventsById[eventId] = updated;
    return updated;
  }

  @override
  Future<SavedEventAggregate> updateDisplayInfo({
    required String publicId,
    required int expectedRevision,
    required String title,
    required String memo,
    required Map<String, String> playerDisplayNamesById,
  }) async {
    if (expectedRevision < 1) {
      throw ArgumentError.value(
        expectedRevision,
        'expectedRevision',
        'must be greater than or equal to 1',
      );
    }

    final eventId = _eventIdByPublicId[publicId];
    final event = eventId == null ? null : _eventsById[eventId];
    if (eventId == null || event == null) {
      throw StateError('event not found: $publicId');
    }

    final normalizedTitle = title.trim();
    if (normalizedTitle.isEmpty) {
      throw ArgumentError.value(title, 'title', 'must not be empty');
    }

    final normalizedMemo = memo.trim();
    final normalizedNames = <String, String>{};
    for (final entry in playerDisplayNamesById.entries) {
      final playerId = entry.key.trim();
      final displayName = entry.value.trim();
      if (playerId.isEmpty) {
        throw ArgumentError.value(entry.key, 'playerId', 'must not be empty');
      }
      if (displayName.isEmpty) {
        throw ArgumentError.value(
          entry.value,
          'playerDisplayNamesById[$playerId]',
          'must not be empty',
        );
      }
      normalizedNames[playerId] = displayName;
    }

    final players = _playersByEventId[eventId] ?? const <SavedEventPlayer>[];
    _ensurePlayerIdsMatch(players, normalizedNames.keys.toSet());

    final displayIsUnchanged = event.title == normalizedTitle &&
        event.memo == normalizedMemo &&
        players.every(
          (player) => player.displayName == normalizedNames[player.id],
        );
    if (displayIsUnchanged) {
      return _buildAggregate(event);
    }

    if (event.revision != expectedRevision) {
      throw EventRevisionConflictException(
        eventId: event.id,
        expectedRevision: expectedRevision,
        actualRevision: event.revision,
      );
    }

    final now = _clock();
    final updatedEvent = event.copyWith(
      title: normalizedTitle,
      memo: normalizedMemo,
      revision: event.revision + 1,
      updatedAt: now,
    );
    final updatedPlayers = players.map((player) {
      final nextDisplayName = normalizedNames[player.id]!;
      if (nextDisplayName == player.displayName) {
        return player;
      }

      return player.copyWith(
        displayName: nextDisplayName,
        updatedAt: now,
      );
    }).toList(growable: false);

    _eventsById[eventId] = updatedEvent;
    _playersByEventId[eventId] = updatedPlayers;

    return _buildAggregate(updatedEvent);
  }

  @override
  Future<SavedEventAggregate> updateCourtSettings({
    required String eventId,
    required List<SavedEventCourtSetting> courtSettings,
  }) async {
    final event = _eventsById[eventId];
    if (event == null) {
      throw StateError('event not found: $eventId');
    }

    if (event.hasAdoptedSchedule) {
      throw StateError('event already adopted: $eventId');
    }

    final currentSettings = _courtSettingsByEventId[eventId] ??
        buildDefaultCourtSettings(event.courtCount);
    if (_courtSettingsEqual(currentSettings, courtSettings)) {
      return _buildAggregate(event);
    }

    final updatedEvent = event.copyWith(
      revision: event.revision + 1,
      updatedAt: _clock(),
    );

    _eventsById[eventId] = updatedEvent;
    _courtSettingsByEventId[eventId] = List.unmodifiable(courtSettings);

    return _buildAggregate(updatedEvent);
  }

  SavedEventAggregate _buildAggregate(SavedEvent event) {
    final share = _sharesByPublicId[event.publicId];
    if (share == null) {
      throw StateError('share not found: ${event.publicId}');
    }

    return SavedEventAggregate(
      event: event,
      players: _playersByEventId[event.id] ?? const [],
      share: share,
      importRecord: _importsByEventId[event.id],
      courtSettings: _courtSettingsByEventId[event.id] ??
          buildDefaultCourtSettings(event.courtCount),
    );
  }

  void _ensurePlayerIdsMatch(
    List<SavedEventPlayer> players,
    Set<String> inputPlayerIds,
  ) {
    final currentPlayerIds = players.map((player) => player.id).toSet();
    if (currentPlayerIds.length != inputPlayerIds.length ||
        !currentPlayerIds.containsAll(inputPlayerIds)) {
      throw ArgumentError.value(
        inputPlayerIds,
        'playerDisplayNamesById',
        'must contain exactly the current event player ids',
      );
    }
  }

  bool _courtSettingsEqual(
    List<SavedEventCourtSetting> left,
    List<SavedEventCourtSetting> right,
  ) {
    if (left.length != right.length) return false;

    for (var index = 0; index < left.length; index += 1) {
      if (left[index].courtNumber != right[index].courtNumber ||
          left[index].displayLabel != right[index].displayLabel) {
        return false;
      }
    }

    return true;
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
