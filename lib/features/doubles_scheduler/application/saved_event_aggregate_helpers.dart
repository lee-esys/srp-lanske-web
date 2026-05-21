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
  );
}
