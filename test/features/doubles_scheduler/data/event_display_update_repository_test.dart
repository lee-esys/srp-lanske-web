import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/event_repository.dart';
import 'package:srp_lanske/features/doubles_scheduler/data/in_memory_event_repository.dart';
import 'package:srp_lanske/features/doubles_scheduler/data/json_event_repository.dart';
import 'package:srp_lanske/features/doubles_scheduler/data/saved_event_json_store.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/player_draft.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/saved_event_models.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/models/event_draft.dart';

void main() {
  final repositoryFactories = <String, EventRepository Function()>{
    'InMemoryEventRepository': InMemoryEventRepository.new,
    'JsonEventRepository': () => JsonEventRepository(
          store: _FakeSavedEventJsonStore(),
        ),
  };

  for (final entry in repositoryFactories.entries) {
    group('${entry.key} display update', () {
      test('stores initial display names when an event is created', () async {
        final repository = entry.value();

        final created = await repository.createFromDraft(_buildDraft());

        expect(created.event.memo, isEmpty);
        expect(created.players[0].initialDisplayName, '参加者1');
        expect(created.players[0].displayName, '参加者1');
        expect(created.players[5].initialDisplayName, '参加者6');
        expect(created.players[5].displayName, '参加者6');
      });

      test('updates display fields without changing schedule data', () async {
        final repository = entry.value();
        final created = await repository.createFromDraft(_buildDraft());

        await repository.updateCurrentGeneratedScheduleId(
          eventId: created.event.id,
          generatedScheduleId: 'generated-1',
        );
        await repository.updateCourtSettings(
          eventId: created.event.id,
          courtSettings: [
            SavedEventCourtSetting(courtNumber: 1, displayLabel: 'A'),
          ],
        );
        final beforeUpdate =
            await repository.findByPublicId(created.event.publicId);
        final names = <String, String>{
          for (final player in beforeUpdate!.players)
            player.id: '${player.displayName}・更新',
        };

        final updated = await repository.updateDisplayInfo(
          publicId: created.event.publicId,
          expectedRevision: beforeUpdate.event.revision,
          title: ' 更新後イベント ',
          memo: ' 運営メモ ',
          playerDisplayNamesById: names,
        );

        expect(updated.event.title, '更新後イベント');
        expect(updated.event.memo, '運営メモ');
        expect(updated.event.revision, beforeUpdate.event.revision + 1);
        expect(updated.event.currentGeneratedScheduleId, 'generated-1');
        expect(updated.courtSettings.single.displayLabel, 'A');
        expect(updated.players[0].initialDisplayName, '参加者1');
        expect(updated.players[0].displayName, '参加者1・更新');

        final restored =
            await repository.findByPublicId(created.event.publicId);
        expect(restored, isNotNull);
        expect(restored!.event.title, '更新後イベント');
        expect(restored.event.memo, '運営メモ');
        expect(restored.event.currentGeneratedScheduleId, 'generated-1');
        expect(restored.courtSettings.single.displayLabel, 'A');
        expect(restored.players[0].initialDisplayName, '参加者1');
        expect(restored.players[0].displayName, '参加者1・更新');
      });

      test('rejects a changed save when the revision is stale', () async {
        final repository = entry.value();
        final created = await repository.createFromDraft(_buildDraft());
        final initialNames = <String, String>{
          for (final player in created.players) player.id: player.displayName,
        };

        final first = await repository.updateDisplayInfo(
          publicId: created.event.publicId,
          expectedRevision: created.event.revision,
          title: '先に保存されたイベント',
          memo: '',
          playerDisplayNamesById: initialNames,
        );

        await expectLater(
          repository.updateDisplayInfo(
            publicId: created.event.publicId,
            expectedRevision: created.event.revision,
            title: '古い画面からの変更',
            memo: '',
            playerDisplayNamesById: initialNames,
          ),
          throwsA(
            isA<EventRevisionConflictException>()
                .having(
                  (error) => error.expectedRevision,
                  'expectedRevision',
                  created.event.revision,
                )
                .having(
                  (error) => error.actualRevision,
                  'actualRevision',
                  first.event.revision,
                ),
          ),
        );

        final restored =
            await repository.findByPublicId(created.event.publicId);
        expect(restored!.event.title, '先に保存されたイベント');
        expect(restored.event.revision, first.event.revision);
      });

      test('accepts a stale revision when the saved values are identical',
          () async {
        final repository = entry.value();
        final created = await repository.createFromDraft(_buildDraft());
        final names = <String, String>{
          for (final player in created.players)
            player.id: '${player.displayName}・更新',
        };

        final first = await repository.updateDisplayInfo(
          publicId: created.event.publicId,
          expectedRevision: created.event.revision,
          title: '更新後イベント',
          memo: 'メモ',
          playerDisplayNamesById: names,
        );

        final noOp = await repository.updateDisplayInfo(
          publicId: created.event.publicId,
          expectedRevision: created.event.revision,
          title: '更新後イベント',
          memo: 'メモ',
          playerDisplayNamesById: names,
        );

        expect(noOp.event.revision, first.event.revision);
        expect(noOp.event.updatedAt, first.event.updatedAt);
      });

      test('requires exactly the current player ids', () async {
        final repository = entry.value();
        final created = await repository.createFromDraft(_buildDraft());

        await expectLater(
          repository.updateDisplayInfo(
            publicId: created.event.publicId,
            expectedRevision: created.event.revision,
            title: created.event.title,
            memo: '',
            playerDisplayNamesById: {
              created.players.first.id: '参加者1',
            },
          ),
          throwsArgumentError,
        );
      });
    });
  }
}

EventDraft _buildDraft() {
  return EventDraft(
    url: 'https://example.com/events/1',
    courts: 1,
    eventName: 'テストイベント',
    players: [
      PlayerDraft.create(displayName: '参加者1'),
      PlayerDraft.create(displayName: '参加者2'),
      PlayerDraft.create(displayName: '参加者3'),
      PlayerDraft.create(displayName: '参加者4'),
      PlayerDraft.create(displayName: '参加者5'),
      PlayerDraft.create(displayName: '参加者6'),
    ],
  );
}

class _FakeSavedEventJsonStore extends SavedEventJsonStore {
  final Map<String, Map<String, dynamic>> _dataByPublicId = {};

  @override
  Future<void> saveByPublicId({
    required String publicId,
    required Map<String, dynamic> data,
  }) async {
    _dataByPublicId[publicId] = _copy(data);
  }

  @override
  Future<Map<String, dynamic>?> findByPublicId(String publicId) async {
    final data = _dataByPublicId[publicId];
    return data == null ? null : _copy(data);
  }

  @override
  Future<Map<String, dynamic>?> findByEventId(String eventId) async {
    for (final data in _dataByPublicId.values) {
      final event = data['event'];
      if (event is Map && event['id'] == eventId) {
        return _copy(data);
      }
    }

    return null;
  }

  Map<String, dynamic> _copy(Map<String, dynamic> data) {
    return jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
  }
}
