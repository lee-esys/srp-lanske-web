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
  final factories = <String, EventRepository Function()>{
    'InMemoryEventRepository': InMemoryEventRepository.new,
    'JsonEventRepository': () => JsonEventRepository(
          store: _FakeSavedEventJsonStore(),
        ),
  };

  for (final entry in factories.entries) {
    group('${entry.key} revision-aware court update', () {
      test('rejects a changed save when the revision is stale', () async {
        final repository = entry.value();
        final created = await repository.createFromDraft(_draft());

        final displayNames = <String, String>{
          for (final player in created.players) player.id: player.displayName,
        };
        final updatedDisplay = await repository.updateDisplayInfo(
          publicId: created.event.publicId,
          expectedRevision: created.event.revision,
          title: '更新後',
          memo: '',
          playerDisplayNamesById: displayNames,
        );

        await expectLater(
          repository.updateCourtSettingsWithRevision(
            eventId: created.event.id,
            expectedRevision: created.event.revision,
            courtSettings: [
              SavedEventCourtSetting(courtNumber: 1, displayLabel: 'A'),
            ],
          ),
          throwsA(
            isA<EventRevisionConflictException>().having(
              (error) => error.actualRevision,
              'actualRevision',
              updatedDisplay.event.revision,
            ),
          ),
        );
      });

      test('treats identical values as a no-op before conflict checking',
          () async {
        final repository = entry.value();
        final created = await repository.createFromDraft(_draft());
        final first = await repository.updateCourtSettingsWithRevision(
          eventId: created.event.id,
          expectedRevision: created.event.revision,
          courtSettings: [
            SavedEventCourtSetting(courtNumber: 1, displayLabel: 'A'),
          ],
        );

        final noOp = await repository.updateCourtSettingsWithRevision(
          eventId: created.event.id,
          expectedRevision: created.event.revision,
          courtSettings: [
            SavedEventCourtSetting(courtNumber: 1, displayLabel: 'A'),
          ],
        );

        expect(noOp.event.revision, first.event.revision);
        expect(noOp.courtSettings.single.displayLabel, 'A');
      });

      test('allows a revision-aware update after the schedule is adopted',
          () async {
        final repository = entry.value();
        final created = await repository.createFromDraft(_draft());
        final adoptedEvent = await repository.updateAdoptedGeneratedScheduleId(
          eventId: created.event.id,
          generatedScheduleId: 'generated-1',
        );

        final updated = await repository.updateCourtSettingsWithRevision(
          eventId: created.event.id,
          expectedRevision: adoptedEvent.revision,
          courtSettings: [
            SavedEventCourtSetting(courtNumber: 1, displayLabel: '左'),
          ],
        );

        expect(updated.event.hasAdoptedSchedule, isTrue);
        expect(updated.event.revision, adoptedEvent.revision + 1);
        expect(updated.courtSettings.single.displayLabel, '左');
      });
    });
  }
}

EventDraft _draft() {
  return EventDraft(
    url: '',
    courts: 1,
    eventName: 'イベント',
    players: [
      for (var index = 1; index <= 6; index += 1)
        PlayerDraft.create(displayName: '参加者$index'),
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
