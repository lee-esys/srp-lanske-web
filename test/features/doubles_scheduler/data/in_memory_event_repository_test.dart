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
  });
}
