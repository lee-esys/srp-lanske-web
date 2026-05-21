import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/data/in_memory_event_repository.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/player_draft.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/models/event_draft.dart';

import '../application/event_repository_contract.dart';

void main() {
  runEventRepositoryContractTests(
    name: 'InMemoryEventRepository',
    createRepository: InMemoryEventRepository.new,
  );

  group('InMemoryEventRepository public id generation', () {
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

    test('creates public id with eight uppercase alphanumeric chars', () async {
      final repository = InMemoryEventRepository();

      final aggregate = await repository.createFromDraft(buildDraft());

      expect(aggregate.event.publicId, hasLength(8));
      expect(
        RegExp(r'^[0-9A-Z]{8}$').hasMatch(aggregate.event.publicId),
        isTrue,
      );
      expect(aggregate.share.publicId, aggregate.event.publicId);
    });

    test('retries when generated public id collides', () async {
      final candidates = ['AAAAAAAA', 'AAAAAAAA', 'BBBBBBBB'];
      var index = 0;

      final repository = InMemoryEventRepository(
        publicIdGenerator: () => candidates[index++],
      );

      final first = await repository.createFromDraft(buildDraft());
      final second = await repository.createFromDraft(buildDraft());

      expect(first.event.publicId, 'AAAAAAAA');
      expect(second.event.publicId, 'BBBBBBBB');
      expect(index, 3);
    });

    test('throws when public id generation keeps colliding', () async {
      final repository = InMemoryEventRepository(
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
