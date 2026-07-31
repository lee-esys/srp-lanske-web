import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/saved_event_models.dart';

void main() {
  group('SavedEvent display metadata compatibility', () {
    final createdAt = DateTime.utc(2026, 8, 1, 0);

    test('round trips event memo and initial player display name', () {
      final event = SavedEvent(
        id: 'event-1',
        publicId: 'ABCD1234',
        title: 'イベント',
        memo: '運営メモ',
        courtCount: 1,
        sourceType: EventSourceType.manual,
        sourceUrl: null,
        status: SavedEventStatus.draft,
        createdAt: createdAt,
        updatedAt: createdAt,
      );
      final aggregate = SavedEventAggregate(
        event: event,
        players: [
          SavedEventPlayer(
            id: 'player-1',
            eventId: event.id,
            initialDisplayName: '生成時名',
            displayName: '現在名',
            orderNo: 1,
            status: 'active',
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        ],
        share: SavedEventShare(
          publicId: event.publicId,
          eventId: event.id,
          createdAt: createdAt,
          updatedAt: createdAt,
        ),
      );

      final restored = SavedEventAggregate.fromJson(aggregate.toJson());

      expect(restored.event.memo, '運営メモ');
      expect(restored.players.single.initialDisplayName, '生成時名');
      expect(restored.players.single.displayName, '現在名');
    });

    test('uses legacy values when new display fields are missing', () {
      final aggregate = SavedEventAggregate.fromJson({
        'schemaVersion': savedEventAggregateSchemaVersion,
        'event': {
          'id': 'event-1',
          'publicId': 'ABCD1234',
          'title': 'イベント',
          'courtCount': 1,
          'sourceType': 'manual',
          'sourceUrl': null,
          'status': 'draft',
          'createdAt': createdAt.toIso8601String(),
          'updatedAt': createdAt.toIso8601String(),
        },
        'players': [
          {
            'id': 'player-1',
            'eventId': 'event-1',
            'displayName': '従来の表示名',
            'orderNo': 1,
            'status': 'active',
            'createdAt': createdAt.toIso8601String(),
            'updatedAt': createdAt.toIso8601String(),
          },
        ],
        'share': {
          'publicId': 'ABCD1234',
          'eventId': 'event-1',
          'createdAt': createdAt.toIso8601String(),
          'updatedAt': createdAt.toIso8601String(),
        },
      });

      expect(aggregate.event.memo, isEmpty);
      expect(aggregate.players.single.initialDisplayName, '従来の表示名');
      expect(aggregate.players.single.displayName, '従来の表示名');
    });
  });
}
