import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/data/json_event_repository.dart';
import 'package:srp_lanske/features/doubles_scheduler/data/saved_event_json_store.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/participant_draft.dart';
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
        participants: [
          ParticipantDraft.create(displayName: '参加者1'),
          ParticipantDraft.create(displayName: '参加者2'),
          ParticipantDraft.create(displayName: '参加者3'),
          ParticipantDraft.create(displayName: '参加者4'),
          ParticipantDraft.create(displayName: '参加者5'),
          ParticipantDraft.create(displayName: '参加者6'),
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

      final first = await repository.createFromDraft(buildDraft());
      final second = await repository.createFromDraft(buildDraft());

      expect(first.event.publicId, 'AAAAAAAA');
      expect(second.event.publicId, 'BBBBBBBB');
      expect(index, 3);
    });

    test('throws when public id generation keeps colliding', () async {
      final repository = JsonEventRepository(
        store: FakeSavedEventJsonStore(),
        publicIdGenerator: () => 'AAAAAAAA',
      );

      await repository.createFromDraft(buildDraft());

      expect(
        () => repository.createFromDraft(buildDraft()),
        throwsA(isA<StateError>()),
      );
    });
  });
}

class FakeSavedEventJsonStore implements SavedEventJsonStore {
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

  Map<String, dynamic> _copy(Map<String, dynamic> data) {
    return jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
  }
}
