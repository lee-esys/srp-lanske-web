import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/event_repository.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/player_draft.dart';
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

      expect(aggregate.players, hasLength(6));
      expect(aggregate.players[0].displayName, '参加者1');
      expect(aggregate.players[0].orderNo, 1);
      expect(aggregate.players[5].displayName, '参加者6');
      expect(aggregate.players[5].orderNo, 6);

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

      expect(found.players, hasLength(6));
      expect(found.players[0].displayName, '参加者1');
      expect(found.players[5].displayName, '参加者6');

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

    test('lists players by event id', () async {
      final repository = createRepository();

      final created = await repository.createFromDraft(buildDraft());
      final players = await repository.listPlayers(created.event.id);

      expect(players, hasLength(6));
      expect(players[0].eventId, created.event.id);
      expect(players[0].displayName, '参加者1');
      expect(players[0].orderNo, 1);
      expect(players[5].displayName, '参加者6');
      expect(players[5].orderNo, 6);
    });

    test('returns empty players when event id does not exist', () async {
      final repository = createRepository();

      final players = await repository.listPlayers('missing-event');

      expect(players, isEmpty);
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

    test('creates default court settings from draft court count', () async {
      final repository = createRepository();

      final aggregate = await repository.createFromDraft(
        buildDraft(courts: 2),
      );

      expect(aggregate.courtSettings, hasLength(2));
      expect(aggregate.courtSettings[0].courtNumber, 1);
      expect(aggregate.courtSettings[0].displayLabel, '1');
      expect(aggregate.courtSettings[1].courtNumber, 2);
      expect(aggregate.courtSettings[1].displayLabel, '2');

      final found = await repository.findByPublicId(aggregate.event.publicId);
      expect(found, isNotNull);
      expect(found!.courtSettings, hasLength(2));
      expect(found.courtSettings[0].displayLabel, '1');
      expect(found.courtSettings[1].displayLabel, '2');
    });

    test('updates and persists court settings', () async {
      final repository = createRepository();

      final created = await repository.createFromDraft(
        buildDraft(courts: 2),
      );

      final updated = await repository.updateCourtSettings(
        eventId: created.event.id,
        courtSettings: [
          SavedEventCourtSetting(
            courtNumber: 1,
            displayLabel: 'A',
          ),
          SavedEventCourtSetting(
            courtNumber: 2,
            displayLabel: 'B',
          ),
        ],
      );

      expect(updated.courtSettings, hasLength(2));
      expect(updated.courtSettings[0].courtNumber, 1);
      expect(updated.courtSettings[0].displayLabel, 'A');
      expect(updated.courtSettings[1].courtNumber, 2);
      expect(updated.courtSettings[1].displayLabel, 'B');

      final found = await repository.findByPublicId(created.event.publicId);
      expect(found, isNotNull);
      expect(found!.courtSettings, hasLength(2));
      expect(found.courtSettings[0].displayLabel, 'A');
      expect(found.courtSettings[1].displayLabel, 'B');
    });

    test('keeps court settings when schedule ids are updated', () async {
      final repository = createRepository();

      final created = await repository.createFromDraft(
        buildDraft(courts: 2),
      );

      await repository.updateCourtSettings(
        eventId: created.event.id,
        courtSettings: [
          SavedEventCourtSetting(
            courtNumber: 1,
            displayLabel: '前',
          ),
          SavedEventCourtSetting(
            courtNumber: 2,
            displayLabel: '奥',
          ),
        ],
      );

      await repository.updateCurrentGeneratedScheduleId(
        eventId: created.event.id,
        generatedScheduleId: 'generated-1',
      );

      final generated = await repository.findByPublicId(created.event.publicId);
      expect(generated, isNotNull);
      expect(generated!.courtSettings[0].displayLabel, '前');
      expect(generated.courtSettings[1].displayLabel, '奥');

      await repository.updateAdoptedGeneratedScheduleId(
        eventId: created.event.id,
        generatedScheduleId: 'generated-1',
      );

      final adopted = await repository.findByPublicId(created.event.publicId);
      expect(adopted, isNotNull);
      expect(adopted!.courtSettings[0].displayLabel, '前');
      expect(adopted.courtSettings[1].displayLabel, '奥');
    });

    test('throws when updating court settings for adopted event', () async {
      final repository = createRepository();

      final created = await repository.createFromDraft(
        buildDraft(courts: 2),
      );

      await repository.updateAdoptedGeneratedScheduleId(
        eventId: created.event.id,
        generatedScheduleId: 'generated-1',
      );

      expect(
        () => repository.updateCourtSettings(
          eventId: created.event.id,
          courtSettings: [
            SavedEventCourtSetting(
              courtNumber: 1,
              displayLabel: 'A',
            ),
            SavedEventCourtSetting(
              courtNumber: 2,
              displayLabel: 'B',
            ),
          ],
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('throws when updating court settings for missing event', () async {
      final repository = createRepository();

      expect(
        () => repository.updateCourtSettings(
          eventId: 'missing-event',
          courtSettings: [
            SavedEventCourtSetting(
              courtNumber: 1,
              displayLabel: 'A',
            ),
          ],
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
