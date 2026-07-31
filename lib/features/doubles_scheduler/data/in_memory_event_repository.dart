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
      final player = entry.value;
      return SavedEventPlayer(
        id: player.id,
        eventId: eventId,
        initialDisplayName: player.displayName,
        displayName: player.displayName,
        orderNo: entry.key + 1,
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
    final event = eventId == null ? null : _eventsById[eventId];
    return event == null ? null : _buildAggregate(event);
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
    final event = _requireEvent(eventId);
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
    final event = _requireEvent(eventId);
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
    _validateExpectedRevision(expectedRevision);
    final eventId = _eventIdByPublicId[publicId];
    if (eventId == null) {
      throw StateError('event not found: $publicId');
    }
    final event = _requireEvent(eventId);
    final normalizedTitle = _requireNonEmpty(title, fieldName: 'title');
    final normalizedMemo = memo.trim();
    final normalizedNames = _normalizePlayerNames(playerDisplayNamesById);
    final players = _playersByEventId[eventId] ?? const <SavedEventPlayer>[];
    _ensurePlayerIdsMatch(players, normalizedNames.keys.toSet());

    final isUnchanged = event.title == normalizedTitle &&
        event.memo == normalizedMemo &&
        players.every(
          (player) => player.displayName == normalizedNames[player.id],
        );
    if (isUnchanged) {
      return _buildAggregate(event);
    }

    _ensureRevision(event, expectedRevision);
    final now = _clock();
    final updatedEvent = event.copyWith(
      title: normalizedTitle,
      memo: normalizedMemo,
      revision: event.revision + 1,
      updatedAt: now,
    );
    final updatedPlayers = players.map((player) {
      final nextDisplayName = normalizedNames[player.id]!;
      return nextDisplayName == player.displayName
          ? player
          : player.copyWith(
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
  }) {
    return _updateCourtSettings(
      eventId: eventId,
      expectedRevision: null,
      courtSettings: courtSettings,
    );
  }

  @override
  Future<SavedEventAggregate> updateCourtSettingsWithRevision({
    required String eventId,
    required int expectedRevision,
    required List<SavedEventCourtSetting> courtSettings,
  }) {
    _validateExpectedRevision(expectedRevision);
    return _updateCourtSettings(
      eventId: eventId,
      expectedRevision: expectedRevision,
      courtSettings: courtSettings,
    );
  }

  Future<SavedEventAggregate> _updateCourtSettings({
    required String eventId,
    required int? expectedRevision,
    required List<SavedEventCourtSetting> courtSettings,
  }) async {
    final event = _requireEvent(eventId);
    if (event.hasAdoptedSchedule) {
      throw StateError('event already adopted: $eventId');
    }

    final currentSettings = _courtSettingsByEventId[eventId] ??
        buildDefaultCourtSettings(event.courtCount);
    if (_courtSettingsEqual(currentSettings, courtSettings)) {
      return _buildAggregate(event);
    }
    if (expectedRevision != null) {
      _ensureRevision(event, expectedRevision);
    }

    final updatedEvent = event.copyWith(
      revision: event.revision + 1,
      updatedAt: _clock(),
    );
    _eventsById[eventId] = updatedEvent;
    _courtSettingsByEventId[eventId] = List.unmodifiable(courtSettings);
    return _buildAggregate(updatedEvent);
  }

  SavedEvent _requireEvent(String eventId) {
    final event = _eventsById[eventId];
    if (event == null) {
      throw StateError('event not found: $eventId');
    }
    return event;
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

  void _validateExpectedRevision(int expectedRevision) {
    if (expectedRevision < 1) {
      throw ArgumentError.value(
        expectedRevision,
        'expectedRevision',
        'must be greater than or equal to 1',
      );
    }
  }

  String _requireNonEmpty(String value, {required String fieldName}) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      throw ArgumentError.value(value, fieldName, 'must not be empty');
    }
    return normalized;
  }

  Map<String, String> _normalizePlayerNames(
    Map<String, String> playerDisplayNamesById,
  ) {
    final normalized = <String, String>{};
    for (final entry in playerDisplayNamesById.entries) {
      final playerId = _requireNonEmpty(entry.key, fieldName: 'playerId');
      normalized[playerId] = _requireNonEmpty(
        entry.value,
        fieldName: 'playerDisplayNamesById[$playerId]',
      );
    }
    return normalized;
  }

  void _ensureRevision(SavedEvent event, int expectedRevision) {
    if (event.revision != expectedRevision) {
      throw EventRevisionConflictException(
        eventId: event.id,
        expectedRevision: expectedRevision,
        actualRevision: event.revision,
      );
    }
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
