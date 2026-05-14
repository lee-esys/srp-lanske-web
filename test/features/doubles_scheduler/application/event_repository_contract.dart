import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/event_repository.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/participant_draft.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/saved_event_models.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/models/event_draft.dart';

typedef EventRepositoryFactory = EventRepository Function();

void runEventRepositoryContractTests({
  required String name,
  required EventRepositoryFactory createRepository,
}) {
  group(name, () {
    EventDraft buildDraft({
      String url = 'https://example.com/events/1',
      String eventName = 'テストイベント',
      int courts = 1,
    }) {
      return EventDraft(
        url: url,
        courts: courts,
        eventName: eventName,
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
      final repository = createRepository();

      final aggregate = await repository.createFromDraft(buildDraft());

      expect(aggregate.event.id, isNotEmpty);
      expect(aggregate.event.publicId, isNotEmpty);
      expect(aggregate.event.title, 'テストイベント');
      expect(aggregate.event.courtCount, 1);
      expect(aggregate.event.sourceUrl, 'https://example.com/events/1');
      expect(aggregate.event.status, SavedEventStatus.draft);
      expect(aggregate.event.currentGeneratedScheduleId, isNull);
      expect(aggregate.event.adoptedGeneratedScheduleId, isNull);

      expect(aggregate.participants, hasLength(6));
      expect(aggregate.participants[0].displayName, '参加者1');
      expect(aggregate.participants[0].orderNo, 1);
      expect(aggregate.participants[5].displayName, '参加者6');
      expect(aggregate.participants[5].orderNo, 6);

      expect(aggregate.share.publicId, aggregate.event.publicId);
      expect(aggregate.share.eventId, aggregate.event.id);
      expect(aggregate.importRecord, isNotNull);
      expect(aggregate.importRecord!.eventId, aggregate.event.id);
      expect(aggregate.importRecord!.sourceUrl, 'https://example.com/events/1');
    });

    test('creates manual event without import record', () async {
      final repository = createRepository();

      final aggregate = await repository.createFromDraft(
        buildDraft(url: ''),
      );

      expect(aggregate.event.sourceType, EventSourceType.manual);
      expect(aggregate.event.sourceUrl, isNull);
      expect(aggregate.importRecord, isNull);
    });

    test('finds event aggregate by public id', () async {
      final repository = createRepository();

      final created = await repository.createFromDraft(buildDraft());
      final found = await repository.findByPublicId(created.event.publicId);

      expect(found, isNotNull);
      expect(found!.event.id, created.event.id);
      expect(found.event.publicId, created.event.publicId);
      expect(found.event.title, created.event.title);

      expect(found.participants, hasLength(6));
      expect(found.participants[0].displayName, '参加者1');
      expect(found.participants[5].displayName, '参加者6');

      expect(found.share.publicId, created.share.publicId);
      expect(found.share.eventId, created.event.id);
      expect(found.importRecord, isNotNull);
      expect(found.importRecord!.sourceUrl, 'https://example.com/events/1');
    });

    test('returns null when public id does not exist', () async {
      final repository = createRepository();

      final found = await repository.findByPublicId('missing-public-id');

      expect(found, isNull);
    });

    test('lists participants by event id', () async {
      final repository = createRepository();

      final created = await repository.createFromDraft(buildDraft());
      final participants = await repository.listParticipants(created.event.id);

      expect(participants, hasLength(6));
      expect(participants[0].eventId, created.event.id);
      expect(participants[0].displayName, '参加者1');
      expect(participants[0].orderNo, 1);
      expect(participants[5].displayName, '参加者6');
      expect(participants[5].orderNo, 6);
    });

    test('returns empty participants when event id does not exist', () async {
      final repository = createRepository();

      final participants = await repository.listParticipants('missing-event');

      expect(participants, isEmpty);
    });

    test('updates and persists current generated schedule id', () async {
      final repository = createRepository();

      final created = await repository.createFromDraft(buildDraft());

      final updated = await repository.updateCurrentGeneratedScheduleId(
        eventId: created.event.id,
        generatedScheduleId: 'generated-1',
      );

      expect(updated.currentGeneratedScheduleId, 'generated-1');
      expect(updated.adoptedGeneratedScheduleId, isNull);
      expect(updated.status, SavedEventStatus.generated);
      expect(updated.displayGeneratedScheduleId, 'generated-1');
      expect(updated.hasAdoptedSchedule, isFalse);

      final found = await repository.findByPublicId(created.event.publicId);
      expect(found, isNotNull);
      expect(found!.event.currentGeneratedScheduleId, 'generated-1');
      expect(found.event.adoptedGeneratedScheduleId, isNull);
      expect(found.event.status, SavedEventStatus.generated);
    });

    test('overwrites current generated schedule id when regenerated', () async {
      final repository = createRepository();

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
      expect(updated.status, SavedEventStatus.generated);
      expect(updated.displayGeneratedScheduleId, 'generated-2');

      final found = await repository.findByPublicId(created.event.publicId);
      expect(found!.event.currentGeneratedScheduleId, 'generated-2');
      expect(found.event.adoptedGeneratedScheduleId, isNull);
    });

    test('updates and persists adopted generated schedule id', () async {
      final repository = createRepository();

      final created = await repository.createFromDraft(buildDraft());

      final updated = await repository.updateAdoptedGeneratedScheduleId(
        eventId: created.event.id,
        generatedScheduleId: 'generated-1',
      );

      expect(updated.currentGeneratedScheduleId, 'generated-1');
      expect(updated.adoptedGeneratedScheduleId, 'generated-1');
      expect(updated.status, SavedEventStatus.adopted);
      expect(updated.displayGeneratedScheduleId, 'generated-1');
      expect(updated.hasAdoptedSchedule, isTrue);

      final found = await repository.findByPublicId(created.event.publicId);
      expect(found, isNotNull);
      expect(found!.event.currentGeneratedScheduleId, 'generated-1');
      expect(found.event.adoptedGeneratedScheduleId, 'generated-1');
      expect(found.event.status, SavedEventStatus.adopted);
    });

    test('throws when updating current schedule for missing event', () async {
      final repository = createRepository();

      expect(
        () => repository.updateCurrentGeneratedScheduleId(
          eventId: 'missing-event',
          generatedScheduleId: 'generated-1',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('throws when updating adopted schedule for missing event', () async {
      final repository = createRepository();

      expect(
        () => repository.updateAdoptedGeneratedScheduleId(
          eventId: 'missing-event',
          generatedScheduleId: 'generated-1',
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
