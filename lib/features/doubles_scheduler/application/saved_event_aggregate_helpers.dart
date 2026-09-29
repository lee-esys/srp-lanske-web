import '../domain/saved_event_models.dart';

SavedEventAggregate replaceSavedEventInAggregate(
  SavedEventAggregate aggregate,
  SavedEvent event,
) {
  return SavedEventAggregate(
    event: event,
    players: aggregate.players,
    share: aggregate.share,
    importRecord: aggregate.importRecord,
    revisions: aggregate.revisions,
    courtSettings: aggregate.courtSettings,
  );
}


SavedEventAggregate mergeDisplayFragment(
  SavedEventAggregate current,
  SavedEventAggregate updated,
) {
  _ensureSameAggregate(current, updated);

  final updatedPlayersById = {
    for (final player in updated.players) player.id: player,
  };
  final currentPlayerIds = current.players.map((player) => player.id).toSet();
  if (currentPlayerIds.length != updatedPlayersById.length ||
      !currentPlayerIds.every(updatedPlayersById.containsKey)) {
    throw StateError('display fragment player set changed');
  }

  return SavedEventAggregate(
    event: current.event.copyWith(
      title: updated.event.title,
      memo: updated.event.memo,
    ),
    players: current.players.map((player) {
      final updatedPlayer = updatedPlayersById[player.id]!;
      return player.copyWith(displayName: updatedPlayer.displayName);
    }).toList(growable: false),
    share: current.share,
    importRecord: current.importRecord,
    revisions: current.revisions.copyWith(
      display: updated.revisions.display,
    ),
    courtSettings: current.courtSettings,
  );
}

SavedEventAggregate mergeCourtSettingsFragment(
  SavedEventAggregate current,
  SavedEventAggregate updated,
) {
  _ensureSameAggregate(current, updated);

  return SavedEventAggregate(
    event: current.event,
    players: current.players,
    share: current.share,
    importRecord: current.importRecord,
    revisions: current.revisions.copyWith(
      courtSettings: updated.revisions.courtSettings,
    ),
    courtSettings: List<SavedEventCourtSetting>.unmodifiable(
      updated.courtSettings,
    ),
  );
}

void _ensureSameAggregate(
  SavedEventAggregate current,
  SavedEventAggregate updated,
) {
  if (current.event.id != updated.event.id ||
      current.event.publicId != updated.event.publicId) {
    throw StateError('cannot merge fragments from different events');
  }
}
