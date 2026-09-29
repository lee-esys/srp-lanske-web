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
  final Map<String, SavedEventRevisions> _revisionsByEventId = {};
  final Map<String, List<SavedEventCourtSetting>> _courtSettingsByEventId = {};

  @override
  Future<SavedEventAggregate> createFromDraft(
    EventDraft draft, {
    required String ownerUid,
  }) async {
    final normalizedOwnerUid = _requireNonEmpty(
      ownerUid,
      fieldName: 'ownerUid',
    );
    final now = _clock();
    final eventId = _uuid.v4();
    final publicId = _generateUniquePublicId();
    final courtSettings = buildDefaultCourtSettings(draft.courts);

    final event = SavedEvent(
      id: eventId,
      publicId: publicId,
      ownerUid: normalizedOwnerUid,
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
    _revisionsByEventId[eventId] = const SavedEventRevisions.initial();
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
  Future<List<SavedEventAggregate>> listByOwnerUid(String ownerUid) async {
    final normalizedOwnerUid = _requireNonEmpty(
      ownerUid,
      fieldName: 'ownerUid',
    );
    return _eventsById.values
        .where((event) => event.ownerUid == normalizedOwnerUid)
        .map(_buildAggregate)
        .toList(growable: false);
  }

  @override
  Future<List<SavedEventPlayer>> listPlayers(String publicId) async {
    final eventId = _eventIdByPublicId[publicId];
    return List.unmodifiable(
      eventId == null ? const [] : _playersByEventId[eventId] ?? const [],
    );
  }

  @override
  Future<SavedEvent> updateCurrentGeneratedScheduleId({
    required String publicId,
    required String generatedScheduleId,
  }) async {
    final event = _requireEventByPublicId(publicId);
    if (event.hasAdoptedSchedule) {
      throw StateError('event already adopted: $publicId');
    }
    final eventId = event.id;

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
  Future<SavedEvent> updateCurrentGeneratedScheduleIdIfCurrent({
    required String publicId,
    required String? expectedCurrentGeneratedScheduleId,
    required String generatedScheduleId,
  }) async {
    final event = _requireEventByPublicId(publicId);
    _ensureScheduleStateForGenerate(
      event,
      expectedCurrentGeneratedScheduleId: expectedCurrentGeneratedScheduleId,
    );

    if (event.status == SavedEventStatus.generated &&
        event.currentGeneratedScheduleId == generatedScheduleId) {
      return event;
    }

    final updated = event.copyWith(
      status: SavedEventStatus.generated,
      currentGeneratedScheduleId: generatedScheduleId,
      revision: event.revision + 1,
      updatedAt: _clock(),
    );
    _eventsById[event.id] = updated;
    return updated;
  }

  @override
  Future<SavedEvent> updateAdoptedGeneratedScheduleId({
    required String publicId,
    required String generatedScheduleId,
  }) async {
    final event = _requireEventByPublicId(publicId);
    final eventId = event.id;
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
  Future<SavedEvent> updateAdoptedGeneratedScheduleIdIfCurrent({
    required String publicId,
    required String expectedCurrentGeneratedScheduleId,
  }) async {
    final event = _requireEventByPublicId(publicId);
    _ensureScheduleStateForAdopt(
      event,
      expectedCurrentGeneratedScheduleId: expectedCurrentGeneratedScheduleId,
    );

    final now = _clock();
    final updated = event.copyWith(
      status: SavedEventStatus.adopted,
      currentGeneratedScheduleId: expectedCurrentGeneratedScheduleId,
      adoptedGeneratedScheduleId: expectedCurrentGeneratedScheduleId,
      adoptedAt: now,
      revision: event.revision + 1,
      updatedAt: now,
    );
    _eventsById[event.id] = updated;
    return updated;
  }

  @override
  Future<SavedEventAggregate> updateDisplayInfo({
    required String publicId,
    required int expectedDisplayRevision,
    required String title,
    required String memo,
    required Map<String, String> playerDisplayNamesById,
  }) async {
    _validateExpectedRevision(expectedDisplayRevision);
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

    final revisions = _revisionsByEventId[eventId] ??
        SavedEventRevisions.fromJson(
          null,
          fallbackRevision: event.revision,
        );
    _ensureRevision(
      eventId: event.id,
      expectedRevision: expectedDisplayRevision,
      actualRevision: revisions.display,
    );
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
    _revisionsByEventId[eventId] = revisions.copyWith(
      display: revisions.display + 1,
    );
    return _buildAggregate(updatedEvent);
  }

  @override
  Future<SavedEventAggregate> updateCourtSettings({
    required String publicId,
    required List<SavedEventCourtSetting> courtSettings,
  }) {
    return _updateCourtSettings(
      publicId: publicId,
      expectedCourtSettingsRevision: null,
      courtSettings: courtSettings,
    );
  }

  @override
  Future<SavedEventAggregate> updateCourtSettingsWithRevision({
    required String publicId,
    required int expectedCourtSettingsRevision,
    required List<SavedEventCourtSetting> courtSettings,
  }) {
    _validateExpectedRevision(expectedCourtSettingsRevision);
    return _updateCourtSettings(
      publicId: publicId,
      expectedCourtSettingsRevision: expectedCourtSettingsRevision,
      courtSettings: courtSettings,
    );
  }

  Future<SavedEventAggregate> _updateCourtSettings({
    required String publicId,
    required int? expectedCourtSettingsRevision,
    required List<SavedEventCourtSetting> courtSettings,
  }) async {
    final event = _requireEventByPublicId(publicId);
    final eventId = event.id;

    final currentSettings = _courtSettingsByEventId[eventId] ??
        buildDefaultCourtSettings(event.courtCount);
    if (_courtSettingsEqual(currentSettings, courtSettings)) {
      return _buildAggregate(event);
    }
    final revisions = _revisionsByEventId[eventId] ??
        SavedEventRevisions.fromJson(
          null,
          fallbackRevision: event.revision,
        );
    if (expectedCourtSettingsRevision != null) {
      _ensureRevision(
        eventId: event.id,
        expectedRevision: expectedCourtSettingsRevision,
        actualRevision: revisions.courtSettings,
      );
    }

    final updatedEvent = event.copyWith(
      revision: event.revision + 1,
      updatedAt: _clock(),
    );
    _eventsById[eventId] = updatedEvent;
    _revisionsByEventId[eventId] = revisions.copyWith(
      courtSettings: revisions.courtSettings + 1,
    );
    _courtSettingsByEventId[eventId] = List.unmodifiable(courtSettings);
    return _buildAggregate(updatedEvent);
  }

  @override
  Future<SavedEventAggregate> transferOwner({
    required String publicId,
    required String expectedSourceUid,
    required String targetUid,
  }) async {
    final sourceUid = _requireNonEmpty(
      expectedSourceUid,
      fieldName: 'expectedSourceUid',
    );
    final nextOwnerUid = _requireNonEmpty(targetUid, fieldName: 'targetUid');
    if (sourceUid == nextOwnerUid) {
      throw ArgumentError.value(
        targetUid,
        'targetUid',
        'must differ from expectedSourceUid',
      );
    }

    final event = _requireEventByPublicId(publicId);
    if (event.ownerUid == nextOwnerUid) {
      return _buildAggregate(event);
    }
    if (event.ownerUid != sourceUid) {
      throw StateError(
        'event owner mismatch: expected $sourceUid, '
        'actual ${event.ownerUid ?? 'null'}',
      );
    }

    final updatedEvent = event.copyWith(
      ownerUid: nextOwnerUid,
      revision: event.revision + 1,
      updatedAt: _clock(),
    );
    _eventsById[event.id] = updatedEvent;
    return _buildAggregate(updatedEvent);
  }

  SavedEvent _requireEvent(String eventId) {
    final event = _eventsById[eventId];
    if (event == null) {
      throw StateError('event not found: $eventId');
    }
    return event;
  }

  SavedEvent _requireEventByPublicId(String publicId) {
    final eventId = _eventIdByPublicId[publicId];
    if (eventId == null) {
      throw StateError('event not found: $publicId');
    }
    return _requireEvent(eventId);
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
      revisions: _revisionsByEventId[event.id] ??
          SavedEventRevisions.fromJson(
            null,
            fallbackRevision: event.revision,
          ),
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

  void _ensureRevision({
    required String eventId,
    required int expectedRevision,
    required int actualRevision,
  }) {
    if (actualRevision != expectedRevision) {
      throw EventRevisionConflictException(
        eventId: eventId,
        expectedRevision: expectedRevision,
        actualRevision: actualRevision,
      );
    }
  }

  void _ensureScheduleStateForGenerate(
    SavedEvent event, {
    required String? expectedCurrentGeneratedScheduleId,
  }) {
    if (event.hasAdoptedSchedule ||
        event.currentGeneratedScheduleId !=
            expectedCurrentGeneratedScheduleId) {
      _throwScheduleStateConflict(
        event,
        expectedCurrentGeneratedScheduleId: expectedCurrentGeneratedScheduleId,
      );
    }
  }

  void _ensureScheduleStateForAdopt(
    SavedEvent event, {
    required String expectedCurrentGeneratedScheduleId,
  }) {
    if (event.hasAdoptedSchedule ||
        event.currentGeneratedScheduleId !=
            expectedCurrentGeneratedScheduleId) {
      _throwScheduleStateConflict(
        event,
        expectedCurrentGeneratedScheduleId: expectedCurrentGeneratedScheduleId,
      );
    }
  }

  Never _throwScheduleStateConflict(
    SavedEvent event, {
    required String? expectedCurrentGeneratedScheduleId,
  }) {
    throw ScheduleStateConflictException(
      eventId: event.id,
      expectedCurrentGeneratedScheduleId: expectedCurrentGeneratedScheduleId,
      actualCurrentGeneratedScheduleId: event.currentGeneratedScheduleId,
      actualAdoptedGeneratedScheduleId: event.adoptedGeneratedScheduleId,
      actualStatus: event.status,
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
