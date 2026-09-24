import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/data/json_event_repository.dart';
import 'package:srp_lanske/features/doubles_scheduler/data/saved_event_json_store.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/player_draft.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/saved_event_models.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/models/event_draft.dart';

import '../application/event_repository_contract.dart';

void main() {
  runEventRepositoryContractTests(
    name: 'JsonEventRepository',
    createRepository: () => JsonEventRepository(
      store: FakeSavedEventJsonStore(),
    ),
  );

  group('JsonEventRepository public id generation', () {
    EventDraft buildDraft() {
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

    test('retries when generated public id collides', () async {
      final candidates = ['AAAAAAAA', 'AAAAAAAA', 'BBBBBBBB'];
      var index = 0;

      final repository = JsonEventRepository(
        store: FakeSavedEventJsonStore(),
        publicIdGenerator: () => candidates[index++],
      );

      final first = await repository.createFromDraft(buildDraft(), ownerUid: 'owner-1');
      final second = await repository.createFromDraft(buildDraft(), ownerUid: 'owner-1');

      expect(first.event.publicId, 'AAAAAAAA');
      expect(second.event.publicId, 'BBBBBBBB');
      expect(index, 3);
    });

    test('throws when public id generation keeps colliding', () async {
      final repository = JsonEventRepository(
        store: FakeSavedEventJsonStore(),
        publicIdGenerator: () => 'AAAAAAAA',
      );

      await repository.createFromDraft(buildDraft(), ownerUid: 'owner-1');

      expect(
        () => repository.createFromDraft(buildDraft(), ownerUid: 'owner-1'),
        throwsA(isA<StateError>()),
      );
    });
    test('promotes legacy revision metadata on the next update', () async {
      final store = FakeSavedEventJsonStore();
      final repository = JsonEventRepository(
        store: store,
        publicIdGenerator: () => 'CCCCCCCC',
      );
      final created = await repository.createFromDraft(
        buildDraft(),
        ownerUid: 'owner-1',
      );

      final legacy = await store.findByPublicId(created.event.publicId);
      expect(legacy, isNotNull);
      final legacyEvent = legacy!['event'] as Map<String, dynamic>;
      legacy['schemaVersion'] = 1;
      legacy.remove('revisions');
      legacyEvent.remove('ownerUid');
      await store.saveByPublicId(
        publicId: created.event.publicId,
        data: legacy,
      );

      await repository.updateCurrentGeneratedScheduleId(
        eventId: created.event.id,
        generatedScheduleId: 'generated-1',
      );

      final promoted = await store.findByPublicId(created.event.publicId);
      expect(promoted?['schemaVersion'], savedEventAggregateSchemaVersion);
      final promotedEvent = promoted?['event'] as Map<String, dynamic>;
      final revisions = promoted?['revisions'] as Map<String, dynamic>;
      expect(promotedEvent['ownerUid'], isNull);
      expect(promotedEvent['revision'], 2);
      expect(revisions['display'], 1);
      expect(revisions['courtSettings'], 1);
    });

  });
}

class FakeSavedEventJsonStore extends SavedEventJsonStore {
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
    if (data == null) return null;

    return _copy(data);
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

  @override
  Future<List<Map<String, dynamic>>> listByOwnerUid(String ownerUid) async {
    return _dataByPublicId.values
        .where((data) {
          final event = data['event'];
          return event is Map && event['ownerUid'] == ownerUid;
        })
        .map(_copy)
        .toList(growable: false);
  }

  Map<String, dynamic> _copy(Map<String, dynamic> data) {
    return jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
  }
}
