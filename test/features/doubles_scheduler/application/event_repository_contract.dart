import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/event_repository.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/player_draft.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/player_source_metadata.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/saved_event_models.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/models/event_draft.dart';

typedef EventRepositoryFactory = EventRepository Function();

Future<SavedEventAggregate> _createOwnedEvent(
  EventRepository repository,
  EventDraft draft, {
  String ownerUid = 'owner-1',
}) {
  return repository.createFromDraft(
    draft,
    ownerUid: ownerUid,
  );
}

void runEventRepositoryContractTests({
  required String name,
  required EventRepositoryFactory createRepository,
}) {
  group(name, () {
    EventDraft buildDraft({
      String url = 'https://example.com/events/1',
      String eventName = 'テストイベント',
      int courts = 1,
      EventSourceType sourceType = EventSourceType.unknown,
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
        sourceType: sourceType,
      );
    }

    test('creates event aggregate from draft', () async {
      final repository = createRepository();

      final aggregate = await _createOwnedEvent(repository, buildDraft());

      expect(aggregate.event.id, isNotEmpty);
      expect(aggregate.event.publicId, isNotEmpty);
      expect(aggregate.event.title, 'テストイベント');
      expect(aggregate.event.courtCount, 1);
      expect(aggregate.event.sourceUrl, 'https://example.com/events/1');
      expect(aggregate.event.status, SavedEventStatus.draft);
      expect(aggregate.event.ownerUid, 'owner-1');
      expect(aggregate.event.currentGeneratedScheduleId, isNull);
      expect(aggregate.event.adoptedGeneratedScheduleId, isNull);
      expect(aggregate.event.adoptedAt, isNull);
      expect(aggregate.event.visibility, savedEventDefaultVisibility);
      expect(aggregate.event.visibleUntilRoundNo, isNull);
      expect(
        aggregate.event.expiresAt,
        defaultSavedEventExpiresAt(aggregate.event.createdAt),
      );
      expect(aggregate.event.revision, 1);

      expect(aggregate.players, hasLength(6));
      expect(aggregate.players[0].displayName, '参加者1');
      expect(aggregate.players[0].orderNo, 1);
      expect(aggregate.players[0].externalIdentity, isNull);
      expect(aggregate.players[0].sourceProfileSnapshot, isNull);
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

      final aggregate = await _createOwnedEvent(
        repository,
        buildDraft(url: ''),
      );

      expect(aggregate.event.sourceType, EventSourceType.manual);
      expect(aggregate.event.sourceUrl, isNull);
      expect(aggregate.importRecord, isNull);
    });

    test('persists explicit TennisBear source provenance', () async {
      final repository = createRepository();
      const sourceUrl = 'https://www.tennisbear.net/event/1645753/info';

      final aggregate = await _createOwnedEvent(
        repository,
        buildDraft(
          url: sourceUrl,
          sourceType: EventSourceType.tennisbear,
        ),
      );

      expect(aggregate.event.sourceType, EventSourceType.tennisbear);
      expect(aggregate.event.sourceUrl, sourceUrl);
      expect(aggregate.importRecord, isNotNull);
      expect(
        aggregate.importRecord!.sourceType,
        EventSourceType.tennisbear,
      );
      expect(aggregate.importRecord!.sourceUrl, sourceUrl);
    });

    test('persists imported player identity and snapshot across display edits',
        () async {
      final repository = createRepository();
      final observedAt = DateTime.utc(2026, 10, 1, 5, 30);
      final draft = EventDraft(
        url: 'https://www.tennisbear.net/event/1645753/info',
        courts: 1,
        eventName: 'TennisBear event',
        players: [
          PlayerDraft.create(
            displayName: 'イベント内表示名',
            sourceText: 'い',
            externalIdentity: const PlayerExternalIdentity(
              sourceType: 'tennisbear',
              sourceUserId: '4380',
              profileUrl: 'https://www.tennisbear.net/user/4380/info',
            ),
            sourceProfileSnapshot: PlayerSourceProfileSnapshot(
              sourceDisplayName: 'い',
              imageUrl: 'https://example.com/4380.jpg',
              levelId: 6,
              levelName: '中上級',
              gender: '男性',
              ageGroup: '40代',
              pickleballLevelName: '未設定',
              sourceStatus: 'APPROVE',
              isGuest: false,
              observedAt: observedAt,
            ),
          ),
          PlayerDraft.create(displayName: '参加者2'),
          PlayerDraft.create(displayName: '参加者3'),
          PlayerDraft.create(displayName: '参加者4'),
        ],
        sourceType: EventSourceType.tennisbear,
      );

      final created = await _createOwnedEvent(repository, draft);
      final importedPlayer = created.players.first;

      expect(importedPlayer.displayName, 'イベント内表示名');
      expect(importedPlayer.initialDisplayName, 'イベント内表示名');
      expect(importedPlayer.externalIdentity, isNotNull);
      expect(importedPlayer.externalIdentity!.sourceType, 'tennisbear');
      expect(importedPlayer.externalIdentity!.sourceUserId, '4380');
      expect(
        importedPlayer.externalIdentity!.profileUrl,
        'https://www.tennisbear.net/user/4380/info',
      );
      expect(importedPlayer.sourceProfileSnapshot, isNotNull);
      expect(importedPlayer.sourceProfileSnapshot!.sourceDisplayName, 'い');
      expect(importedPlayer.sourceProfileSnapshot!.levelId, 6);
      expect(importedPlayer.sourceProfileSnapshot!.levelName, '中上級');
      expect(importedPlayer.sourceProfileSnapshot!.observedAt, observedAt);

      final names = <String, String>{
        for (final player in created.players)
          player.id:
              player.id == importedPlayer.id ? '表示名変更後' : player.displayName,
      };
      await repository.updateDisplayInfo(
        publicId: created.event.publicId,
        expectedDisplayRevision: created.revisions.display,
        title: created.event.title,
        memo: created.event.memo,
        playerDisplayNamesById: names,
      );

      final restored = await repository.findByPublicId(created.event.publicId);
      expect(restored, isNotNull);
      final restoredPlayer = restored!.players.first;
      expect(restoredPlayer.displayName, '表示名変更後');
      expect(restoredPlayer.initialDisplayName, 'イベント内表示名');
      expect(restoredPlayer.externalIdentity!.sourceUserId, '4380');
      expect(restoredPlayer.sourceProfileSnapshot!.sourceDisplayName, 'い');
      expect(restoredPlayer.sourceProfileSnapshot!.observedAt, observedAt);
    });

    test('does not persist a URL for manual source type', () async {
      final repository = createRepository();

      final aggregate = await _createOwnedEvent(
        repository,
        buildDraft(
          url: 'https://www.tennisbear.net/event/1645753/info',
          sourceType: EventSourceType.manual,
        ),
      );

      expect(aggregate.event.sourceType, EventSourceType.manual);
      expect(aggregate.event.sourceUrl, isNull);
      expect(aggregate.importRecord, isNull);
    });

    test('lists only events owned by the requested uid', () async {
      final repository = createRepository();

      final first = await _createOwnedEvent(
        repository,
        buildDraft(eventName: 'owner-1 first'),
        ownerUid: 'owner-1',
      );
      final second = await _createOwnedEvent(
        repository,
        buildDraft(eventName: 'owner-2 event'),
        ownerUid: 'owner-2',
      );
      final third = await _createOwnedEvent(
        repository,
        buildDraft(eventName: 'owner-1 second'),
        ownerUid: 'owner-1',
      );

      final owned = await repository.listByOwnerUid('owner-1');

      expect(
          owned.map((aggregate) => aggregate.event.id),
          containsAll([
            first.event.id,
            third.event.id,
          ]));
      expect(
        owned.any((aggregate) => aggregate.event.id == second.event.id),
        isFalse,
      );
      expect(
        owned.every((aggregate) => aggregate.event.ownerUid == 'owner-1'),
        isTrue,
      );
    });

    test('finds event aggregate by public id', () async {
      final repository = createRepository();

      final created = await _createOwnedEvent(repository, buildDraft());
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

    test('lists players by public id', () async {
      final repository = createRepository();

      final created = await _createOwnedEvent(repository, buildDraft());
      final players = await repository.listPlayers(created.event.publicId);

      expect(players, hasLength(6));
      expect(players[0].eventId, created.event.id);
      expect(players[0].displayName, '参加者1');
      expect(players[0].orderNo, 1);
      expect(players[5].displayName, '参加者6');
      expect(players[5].orderNo, 6);
    });

    test('returns empty players when public id does not exist', () async {
      final repository = createRepository();

      final players = await repository.listPlayers('missing-event');

      expect(players, isEmpty);
    });

    test('updates and persists current generated schedule id', () async {
      final repository = createRepository();

      final created = await _createOwnedEvent(repository, buildDraft());

      final updated = await repository.updateCurrentGeneratedScheduleId(
        publicId: created.event.publicId,
        generatedScheduleId: 'generated-1',
      );

      expect(updated.currentGeneratedScheduleId, 'generated-1');
      expect(updated.adoptedGeneratedScheduleId, isNull);
      expect(updated.status, SavedEventStatus.generated);
      expect(updated.displayGeneratedScheduleId, 'generated-1');
      expect(updated.hasAdoptedSchedule, isFalse);
      expect(updated.revision, created.event.revision + 1);

      final found = await repository.findByPublicId(created.event.publicId);
      expect(found, isNotNull);
      expect(found!.event.currentGeneratedScheduleId, 'generated-1');
      expect(found.event.adoptedGeneratedScheduleId, isNull);
      expect(found.event.status, SavedEventStatus.generated);
      expect(found.event.revision, 2);
    });

    test('overwrites current generated schedule id when regenerated', () async {
      final repository = createRepository();

      final created = await _createOwnedEvent(repository, buildDraft());

      await repository.updateCurrentGeneratedScheduleId(
        publicId: created.event.publicId,
        generatedScheduleId: 'generated-1',
      );

      final updated = await repository.updateCurrentGeneratedScheduleId(
        publicId: created.event.publicId,
        generatedScheduleId: 'generated-2',
      );

      expect(updated.currentGeneratedScheduleId, 'generated-2');
      expect(updated.adoptedGeneratedScheduleId, isNull);
      expect(updated.status, SavedEventStatus.generated);
      expect(updated.displayGeneratedScheduleId, 'generated-2');
      expect(updated.revision, 3);

      final found = await repository.findByPublicId(created.event.publicId);
      expect(found!.event.currentGeneratedScheduleId, 'generated-2');
      expect(found.event.adoptedGeneratedScheduleId, isNull);
      expect(found.event.revision, 3);
    });

    test('compare-and-set generates from the expected current schedule',
        () async {
      final repository = createRepository();
      final created = await _createOwnedEvent(repository, buildDraft());

      final first = await repository.updateCurrentGeneratedScheduleIdIfCurrent(
        publicId: created.event.publicId,
        expectedCurrentGeneratedScheduleId: null,
        generatedScheduleId: 'generated-1',
      );
      final second = await repository.updateCurrentGeneratedScheduleIdIfCurrent(
        publicId: created.event.publicId,
        expectedCurrentGeneratedScheduleId: 'generated-1',
        generatedScheduleId: 'generated-2',
      );

      expect(first.currentGeneratedScheduleId, 'generated-1');
      expect(second.currentGeneratedScheduleId, 'generated-2');
      expect(second.hasAdoptedSchedule, isFalse);
    });

    test('compare-and-set keeps the same generated schedule as a no-op',
        () async {
      final repository = createRepository();
      final created = await _createOwnedEvent(repository, buildDraft());

      final first = await repository.updateCurrentGeneratedScheduleIdIfCurrent(
        publicId: created.event.publicId,
        expectedCurrentGeneratedScheduleId: null,
        generatedScheduleId: 'generated-1',
      );
      final second = await repository.updateCurrentGeneratedScheduleIdIfCurrent(
        publicId: created.event.publicId,
        expectedCurrentGeneratedScheduleId: 'generated-1',
        generatedScheduleId: 'generated-1',
      );

      expect(second.currentGeneratedScheduleId, 'generated-1');
      expect(second.revision, first.revision);
    });

    test('compare-and-set rejects stale regenerated schedule state', () async {
      final repository = createRepository();
      final created = await _createOwnedEvent(repository, buildDraft());

      await repository.updateCurrentGeneratedScheduleIdIfCurrent(
        publicId: created.event.publicId,
        expectedCurrentGeneratedScheduleId: null,
        generatedScheduleId: 'generated-1',
      );
      await repository.updateCurrentGeneratedScheduleIdIfCurrent(
        publicId: created.event.publicId,
        expectedCurrentGeneratedScheduleId: 'generated-1',
        generatedScheduleId: 'generated-2',
      );

      await expectLater(
        repository.updateCurrentGeneratedScheduleIdIfCurrent(
          publicId: created.event.publicId,
          expectedCurrentGeneratedScheduleId: 'generated-1',
          generatedScheduleId: 'generated-stale',
        ),
        throwsA(
          isA<ScheduleStateConflictException>()
              .having(
                (error) => error.expectedCurrentGeneratedScheduleId,
                'expected current schedule',
                'generated-1',
              )
              .having(
                (error) => error.actualCurrentGeneratedScheduleId,
                'actual current schedule',
                'generated-2',
              ),
        ),
      );
    });

    test('compare-and-set rejects regeneration after adoption', () async {
      final repository = createRepository();
      final created = await _createOwnedEvent(repository, buildDraft());

      await repository.updateCurrentGeneratedScheduleIdIfCurrent(
        publicId: created.event.publicId,
        expectedCurrentGeneratedScheduleId: null,
        generatedScheduleId: 'generated-1',
      );
      await repository.updateAdoptedGeneratedScheduleIdIfCurrent(
        publicId: created.event.publicId,
        expectedCurrentGeneratedScheduleId: 'generated-1',
      );

      await expectLater(
        repository.updateCurrentGeneratedScheduleIdIfCurrent(
          publicId: created.event.publicId,
          expectedCurrentGeneratedScheduleId: 'generated-1',
          generatedScheduleId: 'generated-2',
        ),
        throwsA(
          isA<ScheduleStateConflictException>().having(
            (error) => error.isAlreadyAdopted,
            'already adopted',
            isTrue,
          ),
        ),
      );
    });

    test('compare-and-set adopts only the expected current schedule', () async {
      final repository = createRepository();
      final created = await _createOwnedEvent(repository, buildDraft());

      await repository.updateCurrentGeneratedScheduleIdIfCurrent(
        publicId: created.event.publicId,
        expectedCurrentGeneratedScheduleId: null,
        generatedScheduleId: 'generated-1',
      );

      await expectLater(
        repository.updateAdoptedGeneratedScheduleIdIfCurrent(
          publicId: created.event.publicId,
          expectedCurrentGeneratedScheduleId: 'generated-stale',
        ),
        throwsA(isA<ScheduleStateConflictException>()),
      );

      final adopted =
          await repository.updateAdoptedGeneratedScheduleIdIfCurrent(
        publicId: created.event.publicId,
        expectedCurrentGeneratedScheduleId: 'generated-1',
      );

      expect(adopted.currentGeneratedScheduleId, 'generated-1');
      expect(adopted.adoptedGeneratedScheduleId, 'generated-1');
      expect(adopted.hasAdoptedSchedule, isTrue);

      await expectLater(
        repository.updateAdoptedGeneratedScheduleIdIfCurrent(
          publicId: created.event.publicId,
          expectedCurrentGeneratedScheduleId: 'generated-1',
        ),
        throwsA(
          isA<ScheduleStateConflictException>().having(
            (error) => error.isAlreadyAdopted,
            'already adopted',
            isTrue,
          ),
        ),
      );
    });

    test('updates and persists adopted generated schedule id', () async {
      final repository = createRepository();

      final created = await _createOwnedEvent(repository, buildDraft());

      final updated = await repository.updateAdoptedGeneratedScheduleId(
        publicId: created.event.publicId,
        generatedScheduleId: 'generated-1',
      );

      expect(updated.currentGeneratedScheduleId, 'generated-1');
      expect(updated.adoptedGeneratedScheduleId, 'generated-1');
      expect(updated.adoptedAt, isNotNull);
      expect(updated.status, SavedEventStatus.adopted);
      expect(updated.displayGeneratedScheduleId, 'generated-1');
      expect(updated.hasAdoptedSchedule, isTrue);
      expect(updated.revision, created.event.revision + 1);

      final found = await repository.findByPublicId(created.event.publicId);
      expect(found, isNotNull);
      expect(found!.event.currentGeneratedScheduleId, 'generated-1');
      expect(found.event.adoptedGeneratedScheduleId, 'generated-1');
      expect(found.event.adoptedAt, isNotNull);
      expect(found.event.status, SavedEventStatus.adopted);
      expect(found.event.revision, 2);
    });

    test('throws when updating current schedule for missing event', () async {
      final repository = createRepository();

      expect(
        () => repository.updateCurrentGeneratedScheduleId(
          publicId: 'missing-event',
          generatedScheduleId: 'generated-1',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('throws when updating adopted schedule for missing event', () async {
      final repository = createRepository();

      expect(
        () => repository.updateAdoptedGeneratedScheduleId(
          publicId: 'missing-event',
          generatedScheduleId: 'generated-1',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('creates default court settings from draft court count', () async {
      final repository = createRepository();

      final aggregate = await _createOwnedEvent(
        repository,
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

      final created = await _createOwnedEvent(
        repository,
        buildDraft(courts: 2),
      );

      final updated = await repository.updateCourtSettings(
        publicId: created.event.publicId,
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
      expect(updated.event.revision, created.event.revision + 1);

      final found = await repository.findByPublicId(created.event.publicId);
      expect(found, isNotNull);
      expect(found!.courtSettings, hasLength(2));
      expect(found.courtSettings[0].displayLabel, 'A');
      expect(found.courtSettings[1].displayLabel, 'B');
      expect(found.event.revision, 2);
    });

    test('keeps court settings when schedule ids are updated', () async {
      final repository = createRepository();

      final created = await _createOwnedEvent(
        repository,
        buildDraft(courts: 2),
      );

      await repository.updateCourtSettings(
        publicId: created.event.publicId,
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
        publicId: created.event.publicId,
        generatedScheduleId: 'generated-1',
      );

      final generated = await repository.findByPublicId(created.event.publicId);
      expect(generated, isNotNull);
      expect(generated!.courtSettings[0].displayLabel, '前');
      expect(generated.courtSettings[1].displayLabel, '奥');

      await repository.updateAdoptedGeneratedScheduleId(
        publicId: created.event.publicId,
        generatedScheduleId: 'generated-1',
      );

      final adopted = await repository.findByPublicId(created.event.publicId);
      expect(adopted, isNotNull);
      expect(adopted!.courtSettings[0].displayLabel, '前');
      expect(adopted.courtSettings[1].displayLabel, '奥');
    });

    test('updates and persists court settings for adopted event', () async {
      final repository = createRepository();

      final created = await _createOwnedEvent(
        repository,
        buildDraft(courts: 2),
      );

      final adoptedEvent = await repository.updateAdoptedGeneratedScheduleId(
        publicId: created.event.publicId,
        generatedScheduleId: 'generated-1',
      );

      final updated = await repository.updateCourtSettings(
        publicId: created.event.publicId,
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

      expect(updated.event.hasAdoptedSchedule, isTrue);
      expect(updated.event.adoptedGeneratedScheduleId, 'generated-1');
      expect(updated.event.revision, adoptedEvent.revision + 1);
      expect(updated.courtSettings[0].displayLabel, 'A');
      expect(updated.courtSettings[1].displayLabel, 'B');

      final found = await repository.findByPublicId(created.event.publicId);
      expect(found, isNotNull);
      expect(found!.event.hasAdoptedSchedule, isTrue);
      expect(found.event.adoptedGeneratedScheduleId, 'generated-1');
      expect(found.event.revision, updated.event.revision);
      expect(found.courtSettings[0].displayLabel, 'A');
      expect(found.courtSettings[1].displayLabel, 'B');
    });

    test('transfers event owner without changing event content', () async {
      final repository = createRepository();

      final created = await _createOwnedEvent(
        repository,
        buildDraft(eventName: 'owner transfer'),
        ownerUid: 'source-owner',
      );

      final transferred = await repository.transferOwner(
        publicId: created.event.publicId,
        expectedSourceUid: 'source-owner',
        targetUid: 'target-owner',
      );

      expect(transferred.event.ownerUid, 'target-owner');
      expect(transferred.event.title, created.event.title);
      expect(transferred.players, hasLength(created.players.length));
      expect(
          transferred.courtSettings, hasLength(created.courtSettings.length));
      expect(transferred.event.revision, created.event.revision + 1);

      final found = await repository.findByPublicId(created.event.publicId);
      expect(found, isNotNull);
      expect(found!.event.ownerUid, 'target-owner');
      expect(found.event.title, created.event.title);
    });

    test('owner transfer is idempotent for the target owner', () async {
      final repository = createRepository();

      final created = await _createOwnedEvent(
        repository,
        buildDraft(),
        ownerUid: 'source-owner',
      );
      final first = await repository.transferOwner(
        publicId: created.event.publicId,
        expectedSourceUid: 'source-owner',
        targetUid: 'target-owner',
      );
      final second = await repository.transferOwner(
        publicId: created.event.publicId,
        expectedSourceUid: 'source-owner',
        targetUid: 'target-owner',
      );

      expect(second.event.ownerUid, 'target-owner');
      expect(second.event.revision, first.event.revision);
    });

    test('owner transfer rejects a mismatched source owner', () async {
      final repository = createRepository();

      final created = await _createOwnedEvent(
        repository,
        buildDraft(),
        ownerUid: 'actual-owner',
      );

      await expectLater(
        repository.transferOwner(
          publicId: created.event.publicId,
          expectedSourceUid: 'other-owner',
          targetUid: 'target-owner',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('throws when updating court settings for missing event', () async {
      final repository = createRepository();

      expect(
        () => repository.updateCourtSettings(
          publicId: 'missing-event',
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
