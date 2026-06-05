import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/saved_event_models.dart';

void main() {
  group('SavedEvent models JSON', () {
    final createdAt = DateTime.utc(2026, 5, 14, 4, 30);
    final updatedAt = DateTime.utc(2026, 5, 14, 4, 45);
    final adoptedAt = DateTime.utc(2026, 5, 14, 4, 50);
    final expiresAt = DateTime.utc(2026, 5, 24, 4, 30);

    SavedEventAggregate buildAggregate({
      SavedEventStatus status = SavedEventStatus.adopted,
      String? currentGeneratedScheduleId = 'generated-current',
      String? adoptedGeneratedScheduleId = 'generated-adopted',
      DateTime? adoptedAtValue,
      SavedEventImport? importRecord,
    }) {
      final event = SavedEvent(
        id: 'event-1',
        publicId: 'ABCD1234',
        title: 'テストイベント',
        eventDate: DateTime.utc(2026, 5, 20),
        startTime: '13:00',
        endTime: '15:00',
        location: 'テストコート',
        courtCount: 2,
        sourceType: EventSourceType.tennisbear,
        sourceUrl: 'https://example.com/events/1',
        status: status,
        currentGeneratedScheduleId: currentGeneratedScheduleId,
        adoptedGeneratedScheduleId: adoptedGeneratedScheduleId,
        adoptedAt: adoptedAtValue,
        visibility: 'unlisted',
        visibleUntilRoundNo: 10,
        expiresAt: expiresAt,
        revision: 3,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      final players = [
        SavedEventPlayer(
          id: 'player-1',
          eventId: event.id,
          displayName: '参加者1',
          orderNo: 1,
          status: 'active',
          sourceText: '参加者1 Lv5',
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
        SavedEventPlayer(
          id: 'player-2',
          eventId: event.id,
          displayName: '参加者2',
          orderNo: 2,
          status: 'active',
          createdAt: createdAt,
          updatedAt: updatedAt,
        ),
      ];

      final share = SavedEventShare(
        publicId: event.publicId,
        eventId: event.id,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

      return SavedEventAggregate(
        event: event,
        players: players,
        share: share,
        importRecord: importRecord ??
            SavedEventImport(
              id: 'import-1',
              eventId: event.id,
              sourceType: EventSourceType.tennisbear,
              sourceUrl: 'https://example.com/events/1',
              pastedText: '貼り付けテキスト',
              parsedEventJson: {
                'title': '取り込みイベント',
                'courtCount': 2,
              },
              parsedPlayersJson: [
                {'displayName': '参加者1'},
                {'displayName': '参加者2'},
              ],
              confirmedAt: updatedAt,
              createdAt: createdAt,
            ),
      );
    }

    test('round trips SavedEventAggregate through JSON', () {
      final aggregate = buildAggregate(adoptedAtValue: adoptedAt);

      final json = aggregate.toJson();
      final restored = SavedEventAggregate.fromJson(json);

      expect(json['schemaVersion'], savedEventAggregateSchemaVersion);

      expect(restored.event.id, 'event-1');
      expect(restored.event.publicId, 'ABCD1234');
      expect(restored.event.title, 'テストイベント');
      expect(restored.event.eventDate, DateTime.utc(2026, 5, 20));
      expect(restored.event.startTime, '13:00');
      expect(restored.event.endTime, '15:00');
      expect(restored.event.location, 'テストコート');
      expect(restored.event.courtCount, 2);
      expect(restored.event.sourceType, EventSourceType.tennisbear);
      expect(restored.event.sourceUrl, 'https://example.com/events/1');
      expect(restored.event.status, SavedEventStatus.adopted);
      expect(restored.event.adoptedAt, adoptedAt);
      expect(restored.event.visibility, 'unlisted');
      expect(restored.event.visibleUntilRoundNo, 10);
      expect(restored.event.expiresAt, expiresAt);
      expect(restored.event.revision, 3);
      expect(restored.event.createdAt, createdAt);
      expect(restored.event.updatedAt, updatedAt);

      expect(restored.players, hasLength(2));
      expect(restored.players[0].id, 'player-1');
      expect(restored.players[0].eventId, 'event-1');
      expect(restored.players[0].displayName, '参加者1');
      expect(restored.players[0].orderNo, 1);
      expect(restored.players[0].status, 'active');
      expect(restored.players[0].sourceText, '参加者1 Lv5');

      expect(restored.players[1].id, 'player-2');
      expect(restored.players[1].displayName, '参加者2');
      expect(restored.players[1].orderNo, 2);
      expect(restored.players[1].sourceText, isNull);

      expect(restored.share.publicId, 'ABCD1234');
      expect(restored.share.eventId, 'event-1');
      expect(restored.share.createdAt, createdAt);
      expect(restored.share.updatedAt, updatedAt);

      expect(restored.importRecord, isNotNull);
      expect(restored.importRecord!.id, 'import-1');
      expect(restored.importRecord!.eventId, 'event-1');
      expect(restored.importRecord!.sourceType, EventSourceType.tennisbear);
      expect(restored.importRecord!.sourceUrl, 'https://example.com/events/1');
      expect(restored.importRecord!.pastedText, '貼り付けテキスト');
      expect(restored.importRecord!.parsedEventJson?['title'], '取り込みイベント');
      expect(restored.importRecord!.parsedEventJson?['courtCount'], 2);
      expect(restored.importRecord!.parsedPlayersJson, hasLength(2));
      expect(
        restored.importRecord!.parsedPlayersJson?[0]['displayName'],
        '参加者1',
      );
      expect(restored.importRecord!.confirmedAt, updatedAt);
      expect(restored.importRecord!.createdAt, createdAt);
    });

    test('restores legacy participant keys through JSON', () {
      final aggregate = buildAggregate();
      final json = aggregate.toJson();

      json['participants'] = json.remove('players');
      final importRecord = json['importRecord'] as Map<String, dynamic>;
      importRecord['parsedParticipantsJson'] =
          importRecord.remove('parsedPlayersJson');

      final restored = SavedEventAggregate.fromJson(json);

      expect(restored.players, hasLength(2));
      expect(restored.players[0].displayName, '参加者1');
      expect(restored.importRecord!.parsedPlayersJson, hasLength(2));
    });

    test('restores legacy event JSON with web state defaults', () {
      final aggregate = buildAggregate();
      final json = aggregate.toJson();
      final eventJson = json['event'] as Map<String, dynamic>;

      eventJson.remove('adoptedAt');
      eventJson.remove('visibility');
      eventJson.remove('visibleUntilRoundNo');
      eventJson.remove('expiresAt');
      eventJson.remove('revision');

      final restored = SavedEventAggregate.fromJson(json);

      expect(restored.event.adoptedAt, isNull);
      expect(restored.event.visibility, savedEventDefaultVisibility);
      expect(restored.event.visibleUntilRoundNo, isNull);
      expect(restored.event.expiresAt, defaultSavedEventExpiresAt(createdAt));
      expect(restored.event.revision, 1);
    });

    test('round trips generated schedule refs through JSON', () {
      final aggregate = buildAggregate(
        status: SavedEventStatus.generated,
        currentGeneratedScheduleId: 'generated-1',
        adoptedGeneratedScheduleId: null,
      );

      final restored = SavedEventAggregate.fromJson(aggregate.toJson());

      expect(restored.event.status, SavedEventStatus.generated);
      expect(restored.event.currentGeneratedScheduleId, 'generated-1');
      expect(restored.event.adoptedGeneratedScheduleId, isNull);
      expect(restored.event.displayGeneratedScheduleId, 'generated-1');
      expect(restored.event.hasAdoptedSchedule, isFalse);
    });

    test('round trips adopted generated schedule ref through JSON', () {
      final aggregate = buildAggregate(
        status: SavedEventStatus.adopted,
        currentGeneratedScheduleId: 'generated-1',
        adoptedGeneratedScheduleId: 'generated-1',
        adoptedAtValue: adoptedAt,
      );

      final restored = SavedEventAggregate.fromJson(aggregate.toJson());

      expect(restored.event.status, SavedEventStatus.adopted);
      expect(restored.event.currentGeneratedScheduleId, 'generated-1');
      expect(restored.event.adoptedGeneratedScheduleId, 'generated-1');
      expect(restored.event.adoptedAt, adoptedAt);
      expect(restored.event.displayGeneratedScheduleId, 'generated-1');
      expect(restored.event.hasAdoptedSchedule, isTrue);
    });

    test('restores aggregate when importRecord is null', () {
      final aggregate = buildAggregate(importRecord: null);

      final json = aggregate.toJson();
      json['importRecord'] = null;

      final restored = SavedEventAggregate.fromJson(json);

      expect(restored.event.id, 'event-1');
      expect(restored.players, hasLength(2));
      expect(restored.share.publicId, 'ABCD1234');
      expect(restored.importRecord, isNull);
    });

    test('throws FormatException when required aggregate fields are missing',
        () {
      expect(
        () => SavedEventAggregate.fromJson({
          'schemaVersion': savedEventAggregateSchemaVersion,
          'players': const [],
          'share': {
            'publicId': 'ABCD1234',
            'eventId': 'event-1',
            'createdAt': createdAt.toIso8601String(),
            'updatedAt': updatedAt.toIso8601String(),
          },
        }),
        throwsA(isA<FormatException>()),
      );

      expect(
        () => SavedEventAggregate.fromJson({
          'schemaVersion': savedEventAggregateSchemaVersion,
          'event': {
            'id': 'event-1',
            'publicId': 'ABCD1234',
            'title': 'テストイベント',
            'courtCount': 2,
            'sourceType': 'manual',
            'status': 'draft',
            'createdAt': createdAt.toIso8601String(),
            'updatedAt': updatedAt.toIso8601String(),
          },
          'share': {
            'publicId': 'ABCD1234',
            'eventId': 'event-1',
            'createdAt': createdAt.toIso8601String(),
            'updatedAt': updatedAt.toIso8601String(),
          },
        }),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
