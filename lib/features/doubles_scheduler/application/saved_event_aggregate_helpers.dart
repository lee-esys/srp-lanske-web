import '../domain/saved_event_models.dart';

SavedEventAggregate replaceSavedEventInAggregate(
  SavedEventAggregate aggregate,
  SavedEvent event,
) {
  return SavedEventAggregate(
    event: event,
    participants: aggregate.participants,
    share: aggregate.share,
    importRecord: aggregate.importRecord,
  );
}
