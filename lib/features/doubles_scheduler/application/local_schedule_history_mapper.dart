import '../data/local_schedule_history_item.dart';
import '../domain/saved_event_models.dart';

LocalScheduleHistoryItem buildLocalScheduleHistoryItem(
  SavedEventAggregate aggregate, {
  required DateTime now,
}) {
  return LocalScheduleHistoryItem(
    publicId: aggregate.event.publicId,
    title: aggregate.event.title,
    courtCount: aggregate.event.courtCount,
    playerCount: aggregate.players.length,
    createdAt: aggregate.event.createdAt,
    firstSavedAt: now,
    lastOpenedAt: now,
  );
}
