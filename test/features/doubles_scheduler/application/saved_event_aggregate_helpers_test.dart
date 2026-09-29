import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/saved_event_aggregate_helpers.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/saved_event_models.dart';

void main() {
  test('mergeDisplayFragment only applies display-owned fields', () {
    final current = _aggregate(
      eventId: 'event-1',
      publicId: 'ABCD1234',
      title: 'Current',
      memo: 'current memo',
      eventRevision: 5,
      displayRevision: 2,
      courtRevision: 3,
      status: SavedEventStatus.generated,
      currentGeneratedScheduleId: 'generated-current',
      playerName: 'Current player',
      courtLabel: '1',
    );
    final updated = _aggregate(
      eventId: 'event-1',
      publicId: 'ABCD1234',
      title: 'Updated',
      memo: 'updated memo',
      eventRevision: 9,
      displayRevision: 7,
      courtRevision: 8,
      status: SavedEventStatus.adopted,
      currentGeneratedScheduleId: 'generated-latest',
      adoptedGeneratedScheduleId: 'generated-latest',
      playerName: 'Updated player',
      courtLabel: 'A',
    );

    final merged = mergeDisplayFragment(current, updated);

    expect(merged.event.title, 'Updated');
    expect(merged.event.memo, 'updated memo');
    expect(merged.players.single.displayName, 'Updated player');
    expect(merged.revisions.display, 7);

    expect(merged.event.revision, 5);
    expect(merged.event.status, SavedEventStatus.generated);
    expect(merged.event.currentGeneratedScheduleId, 'generated-current');
    expect(merged.event.adoptedGeneratedScheduleId, isNull);
    expect(merged.revisions.courtSettings, 3);
    expect(merged.courtSettings.single.displayLabel, '1');
  });

  test('mergeScheduleStateFragment only applies schedule-owned fields', () {
    final current = _aggregate(
      eventId: 'event-1',
      publicId: 'ABCD1234',
      title: 'Current',
      memo: 'current memo',
      eventRevision: 5,
      displayRevision: 2,
      courtRevision: 3,
      status: SavedEventStatus.generated,
      currentGeneratedScheduleId: 'generated-current',
      playerName: 'Current player',
      courtLabel: '1',
    );
    final updated = _aggregate(
      eventId: 'event-1',
      publicId: 'ABCD1234',
      title: 'Remote title',
      memo: 'remote memo',
      eventRevision: 9,
      displayRevision: 7,
      courtRevision: 8,
      status: SavedEventStatus.adopted,
      currentGeneratedScheduleId: 'generated-latest',
      adoptedGeneratedScheduleId: 'generated-latest',
      playerName: 'Remote player',
      courtLabel: 'A',
    );

    final merged = mergeScheduleStateFragment(current, updated.event);

    expect(merged.event.status, SavedEventStatus.adopted);
    expect(merged.event.currentGeneratedScheduleId, 'generated-latest');
    expect(merged.event.adoptedGeneratedScheduleId, 'generated-latest');
    expect(merged.event.adoptedAt, updated.event.adoptedAt);

    expect(merged.event.title, 'Current');
    expect(merged.event.memo, 'current memo');
    expect(merged.event.revision, 5);
    expect(merged.players.single.displayName, 'Current player');
    expect(merged.revisions.display, 2);
    expect(merged.revisions.courtSettings, 3);
    expect(merged.courtSettings.single.displayLabel, '1');
  });

  test('mergeCourtSettingsFragment only applies court-owned fields', () {
    final current = _aggregate(
      eventId: 'event-1',
      publicId: 'ABCD1234',
      title: 'Current',
      memo: 'current memo',
      eventRevision: 5,
      displayRevision: 2,
      courtRevision: 3,
      status: SavedEventStatus.generated,
      currentGeneratedScheduleId: 'generated-current',
      playerName: 'Current player',
      courtLabel: '1',
    );
    final updated = _aggregate(
      eventId: 'event-1',
      publicId: 'ABCD1234',
      title: 'Other title',
      memo: 'other memo',
      eventRevision: 9,
      displayRevision: 7,
      courtRevision: 8,
      status: SavedEventStatus.adopted,
      currentGeneratedScheduleId: 'generated-latest',
      adoptedGeneratedScheduleId: 'generated-latest',
      playerName: 'Other player',
      courtLabel: 'A',
    );

    final merged = mergeCourtSettingsFragment(current, updated);

    expect(merged.courtSettings.single.displayLabel, 'A');
    expect(merged.revisions.courtSettings, 8);

    expect(identical(merged.event, current.event), isTrue);
    expect(merged.event.revision, 5);
    expect(merged.players.single.displayName, 'Current player');
    expect(merged.revisions.display, 2);
  });

  test('rejects fragments from a different event', () {
    final current = _aggregate(
      eventId: 'event-1',
      publicId: 'ABCD1234',
      title: 'Current',
      memo: '',
      eventRevision: 1,
      displayRevision: 1,
      courtRevision: 1,
      status: SavedEventStatus.generated,
      currentGeneratedScheduleId: 'generated-1',
      playerName: 'Player',
      courtLabel: '1',
    );
    final other = _aggregate(
      eventId: 'event-2',
      publicId: 'WXYZ9876',
      title: 'Other',
      memo: '',
      eventRevision: 1,
      displayRevision: 1,
      courtRevision: 1,
      status: SavedEventStatus.generated,
      currentGeneratedScheduleId: 'generated-2',
      playerName: 'Player',
      courtLabel: '1',
    );

    expect(
      () => mergeScheduleStateFragment(current, other.event),
      throwsStateError,
    );
    expect(
      () => mergeDisplayFragment(current, other),
      throwsStateError,
    );
    expect(
      () => mergeCourtSettingsFragment(current, other),
      throwsStateError,
    );
  });
}

SavedEventAggregate _aggregate({
  required String eventId,
  required String publicId,
  required String title,
  required String memo,
  required int eventRevision,
  required int displayRevision,
  required int courtRevision,
  required SavedEventStatus status,
  required String currentGeneratedScheduleId,
  String? adoptedGeneratedScheduleId,
  required String playerName,
  required String courtLabel,
}) {
  final now = DateTime.utc(2026, 9, 29, 1);
  final event = SavedEvent(
    id: eventId,
    publicId: publicId,
    title: title,
    memo: memo,
    courtCount: 1,
    sourceType: EventSourceType.manual,
    sourceUrl: null,
    status: status,
    currentGeneratedScheduleId: currentGeneratedScheduleId,
    adoptedGeneratedScheduleId: adoptedGeneratedScheduleId,
    adoptedAt: adoptedGeneratedScheduleId == null ? null : now,
    revision: eventRevision,
    createdAt: now,
    updatedAt: now,
  );

  return SavedEventAggregate(
    event: event,
    players: <SavedEventPlayer>[
      SavedEventPlayer(
        id: 'player-1',
        eventId: eventId,
        displayName: playerName,
        orderNo: 1,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      ),
    ],
    share: SavedEventShare(
      publicId: publicId,
      eventId: eventId,
      createdAt: now,
      updatedAt: now,
    ),
    revisions: SavedEventRevisions(
      display: displayRevision,
      courtSettings: courtRevision,
    ),
    courtSettings: <SavedEventCourtSetting>[
      SavedEventCourtSetting(courtNumber: 1, displayLabel: courtLabel),
    ],
  );
}
