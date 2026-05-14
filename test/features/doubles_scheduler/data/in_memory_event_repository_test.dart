import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/data/in_memory_event_repository.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/participant_draft.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/saved_event_models.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/models/event_draft.dart';

void main() {
  group('InMemoryEventRepository', () {
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

    test('creates event aggregate from draft', () async {
      final repository = InMemoryEventRepository();

      final aggregate = await repository.createFromDraft(buildDraft());

      expect(aggregate.event.id, isNotEmpty);
      expect(aggregate.event.publicId, isNotEmpty);
      expect(aggregate.event.title, 'テストイベント');
      expect(aggregate.event.courtCount, 1);
      expect(aggregate.event.sourceUrl, 'https://example.com/events/1');
      expect(aggregate.event.status, SavedEventStatus.draft);

      expect(aggregate.participants, hasLength(6));
      expect(aggregate.participants[0].displayName, '参加者1');
      expect(aggregate.participants[0].orderNo, 1);
      expect(aggregate.participants[5].displayName, '参加者6');
      expect(aggregate.participants[5].orderNo, 6);

      expect(aggregate.share.publicId, aggregate.event.publicId);
      expect(aggregate.share.eventId, aggregate.event.id);
      expect(aggregate.importRecord, isNotNull);
    });

    test('finds event aggregate by public id', () async {
      final repository = InMemoryEventRepository();

      final created = await repository.createFromDraft(buildDraft());
      final found = await repository.findByPublicId(created.event.publicId);

      expect(found, isNotNull);
      expect(found!.event.id, created.event.id);
      expect(found.event.publicId, created.event.publicId);
      expect(found.event.title, created.event.title);
      expect(found.participants, hasLength(6));
      expect(found.share.publicId, created.share.publicId);
    });

    test('returns null when public id does not exist', () async {
      final repository = InMemoryEventRepository();

      final found = await repository.findByPublicId('missing-public-id');

      expect(found, isNull);
    });

    test('updates current generated schedule id', () async {
      final repository = InMemoryEventRepository();

      final created = await repository.createFromDraft(buildDraft());

      final updated = await repository.updateCurrentGeneratedScheduleId(
        eventId: created.event.id,
        generatedScheduleId: 'generated-1',
      );

      expect(updated.currentGeneratedScheduleId, 'generated-1');
      expect(updated.adoptedGeneratedScheduleId, isNull);
      expect(updated.status, SavedEventStatus.generated);

      final found = await repository.findByPublicId(created.event.publicId);
      expect(found!.event.currentGeneratedScheduleId, 'generated-1');
    });

    test('updates adopted generated schedule id', () async {
      final repository = InMemoryEventRepository();

      final created = await repository.createFromDraft(buildDraft());

      final updated = await repository.updateAdoptedGeneratedScheduleId(
        eventId: created.event.id,
        generatedScheduleId: 'generated-1',
      );

      expect(updated.currentGeneratedScheduleId, 'generated-1');
      expect(updated.adoptedGeneratedScheduleId, 'generated-1');
      expect(updated.status, SavedEventStatus.adopted);

      final found = await repository.findByPublicId(created.event.publicId);
      expect(found!.event.adoptedGeneratedScheduleId, 'generated-1');
    });

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

    test('overwrites current generated schedule id when regenerated', () async {
      final repository = InMemoryEventRepository();

      final created = await repository.createFromDraft(buildDraft());

      await repository.updateCurrentGeneratedScheduleId(
        eventId: created.event.id,
        generatedScheduleId: 'generated-1',
      );

      final updated = await repository.updateCurrentGeneratedScheduleId(
        eventId: created.event.id,
        generatedScheduleId: 'generated-2',
      );

      expect(updated.currentGeneratedScheduleId, 'generated-2');
      expect(updated.adoptedGeneratedScheduleId, isNull);
      expect(updated.displayGeneratedScheduleId, 'generated-2');
      expect(updated.status, SavedEventStatus.generated);
    });

    test('uses adopted generated schedule id as display target', () async {
      final repository = InMemoryEventRepository();

      final created = await repository.createFromDraft(buildDraft());

      final generated = await repository.updateCurrentGeneratedScheduleId(
        eventId: created.event.id,
        generatedScheduleId: 'generated-1',
      );

      expect(generated.displayGeneratedScheduleId, 'generated-1');
      expect(generated.hasAdoptedSchedule, isFalse);

      final adopted = await repository.updateAdoptedGeneratedScheduleId(
        eventId: created.event.id,
        generatedScheduleId: 'generated-1',
      );

      expect(adopted.currentGeneratedScheduleId, 'generated-1');
      expect(adopted.adoptedGeneratedScheduleId, 'generated-1');
      expect(adopted.displayGeneratedScheduleId, 'generated-1');
      expect(adopted.hasAdoptedSchedule, isTrue);
      expect(adopted.status, SavedEventStatus.adopted);
    });
  });
}
