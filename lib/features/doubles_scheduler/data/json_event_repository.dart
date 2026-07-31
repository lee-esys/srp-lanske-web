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
    DateTime Function()? clock,
  })  : _store = store,
        _publicIdGenerator = publicIdGenerator ?? generatePublicId,
        _clock = clock ?? DateTime.now;

  final SavedEventJsonStore _store;
  final String Function() _publicIdGenerator;
  final DateTime Function() _clock;
  final _uuid = const Uuid();

  @override
  Future<SavedEventAggregate> createFromDraft(EventDraft draft) async {
    final now = _clock();
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

    final aggregate = SavedEventAggregate(
      event: event,
      players: players,
      share: share,
      importRecord: importRecord,
      courtSettings: buildDefaultCourtSettings(draft.courts),
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

    final updatedData = await _store.updateByPublicId(
      publicId: aggregate.event.publicId,
      update: (currentData) {
        final current = SavedEventAggregate.fromJson(currentData);
        _ensureEventId(current, eventId);
        if (current.event.hasAdoptedSchedule) {
          throw StateError('event already adopted: $eventId');
        }

        final now = _clock();
        return _buildEventFieldsUpdate(
          currentData,
          <String, dynamic>{
            'status': SavedEventStatus.generated.name,
            'currentGeneratedScheduleId': generatedScheduleId,
            'revision': current.event.revision + 1,
            'updatedAt': _dateTimeToJson(now),
          },
        );
      },
    );

    if (updatedData == null) {
      throw StateError('event not found: $eventId');
    }

    return SavedEventAggregate.fromJson(updatedData).event;
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

    final updatedData = await _store.updateByPublicId(
      publicId: aggregate.event.publicId,
      update: (currentData) {
        final current = SavedEventAggregate.fromJson(currentData);
        _ensureEventId(current, eventId);

        final now = _clock();
        return _buildEventFieldsUpdate(
          currentData,
          <String, dynamic>{
            'status': SavedEventStatus.adopted.name,
            'currentGeneratedScheduleId': generatedScheduleId,
            'adoptedGeneratedScheduleId': generatedScheduleId,
            'adoptedAt': _dateTimeToJson(now),
            'revision': current.event.revision + 1,
            'updatedAt': _dateTimeToJson(now),
          },
        );
      },
    );

    if (updatedData == null) {
      throw StateError('event not found: $eventId');
    }

    return SavedEventAggregate.fromJson(updatedData).event;
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

    final updatedData = await _store.updateByPublicId(
      publicId: publicId,
      update: (currentData) {
        final current = SavedEventAggregate.fromJson(currentData);
        _ensurePlayerIdsMatch(current.players, normalizedNames.keys.toSet());

        final displayIsUnchanged = current.event.title == normalizedTitle &&
            current.event.memo == normalizedMemo &&
            current.players.every(
              (player) =>
                  player.displayName == normalizedNames[player.id],
            );
        if (displayIsUnchanged) {
          return SavedEventJsonUpdate.noOp(currentData);
        }

        if (current.event.revision != expectedRevision) {
          throw EventRevisionConflictException(
            eventId: current.event.id,
            expectedRevision: expectedRevision,
            actualRevision: current.event.revision,
          );
        }

        final now = _clock();
        final nowJson = _dateTimeToJson(now);
        final rawPlayers = _asObjectList(
          currentData['players'] ?? currentData['participants'],
          fieldName: 'players',
        );
        final updatedPlayers = rawPlayers.map((rawPlayer) {
          final playerId = rawPlayer['id']?.toString() ?? '';
          final currentDisplayName = rawPlayer['displayName']?.toString() ?? '';
          final nextDisplayName = normalizedNames[playerId];
          if (nextDisplayName == null) {
            throw StateError('player not found in update input: $playerId');
          }

          return <String, dynamic>{
            ...rawPlayer,
            'initialDisplayName':
                rawPlayer['initialDisplayName']?.toString() ??
                    currentDisplayName,
            'displayName': nextDisplayName,
            'updatedAt': currentDisplayName == nextDisplayName
                ? rawPlayer['updatedAt']
                : nowJson,
          };
        }).toList(growable: false);

        final eventUpdate = _buildEventFieldsUpdate(
          currentData,
          <String, dynamic>{
            'title': normalizedTitle,
            'memo': normalizedMemo,
            'revision': current.event.revision + 1,
            'updatedAt': nowJson,
          },
        );

        return SavedEventJsonUpdate(
          data: <String, dynamic>{
            ...eventUpdate.data,
            'players': updatedPlayers,
          },
          fields: <String, dynamic>{
            ...eventUpdate.fields,
            'players': updatedPlayers,
          },
        );
      },
    );

    if (updatedData == null) {
      throw StateError('event not found: $publicId');
    }

    return SavedEventAggregate.fromJson(updatedData);
  }

  @override
  Future<SavedEventAggregate> updateCourtSettings({
    required String eventId,
    required List<SavedEventCourtSetting> courtSettings,
  }) async {
    final aggregate = await _findByEventId(eventId);
    if (aggregate == null) {
      throw StateError('event not found: $eventId');
    }

    final updatedData = await _store.updateByPublicId(
      publicId: aggregate.event.publicId,
      update: (currentData) {
        final current = SavedEventAggregate.fromJson(currentData);
        _ensureEventId(current, eventId);
        if (current.event.hasAdoptedSchedule) {
          throw StateError('event already adopted: $eventId');
        }

        if (_courtSettingsEqual(current.courtSettings, courtSettings)) {
          return SavedEventJsonUpdate.noOp(currentData);
        }

        final now = _clock();
        final eventUpdate = _buildEventFieldsUpdate(
          currentData,
          <String, dynamic>{
            'revision': current.event.revision + 1,
            'updatedAt': _dateTimeToJson(now),
          },
        );
        final nextCourtSettings = courtSettings
            .map((setting) => setting.toJson())
            .toList(growable: false);

        return SavedEventJsonUpdate(
          data: <String, dynamic>{
            ...eventUpdate.data,
            'courtSettings': nextCourtSettings,
          },
          fields: <String, dynamic>{
            ...eventUpdate.fields,
            'courtSettings': nextCourtSettings,
          },
        );
      },
    );

    if (updatedData == null) {
      throw StateError('event not found: $eventId');
    }

    return SavedEventAggregate.fromJson(updatedData);
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

  SavedEventJsonUpdate _buildEventFieldsUpdate(
    Map<String, dynamic> currentData,
    Map<String, dynamic> eventFields,
  ) {
    final currentEvent = _asObjectMap(
      currentData['event'],
      fieldName: 'event',
    );
    final nextEvent = <String, dynamic>{
      ...currentEvent,
      ...eventFields,
    };

    return SavedEventJsonUpdate(
      data: <String, dynamic>{
        ...currentData,
        'event': nextEvent,
      },
      fields: <String, dynamic>{
        for (final entry in eventFields.entries)
          'event.${entry.key}': entry.value,
      },
    );
  }

  void _ensureEventId(SavedEventAggregate aggregate, String eventId) {
    if (aggregate.event.id != eventId) {
      throw StateError('event id mismatch: $eventId');
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

  Map<String, dynamic> _asObjectMap(
    Object? value, {
    required String fieldName,
  }) {
    if (value is! Map) {
      throw FormatException('$fieldName must be an object');
    }

    return value.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }

  List<Map<String, dynamic>> _asObjectList(
    Object? value, {
    required String fieldName,
  }) {
    if (value is! List) {
      throw FormatException('$fieldName must be a list');
    }

    return value.map((item) {
      return _asObjectMap(item, fieldName: '$fieldName item');
    }).toList(growable: false);
  }

  String _dateTimeToJson(DateTime value) {
    return value.toUtc().toIso8601String();
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
