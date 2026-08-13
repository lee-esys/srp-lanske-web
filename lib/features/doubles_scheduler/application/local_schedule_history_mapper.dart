import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';

import '../data/local_schedule_history_item.dart';
import '../domain/saved_event_models.dart';

LocalScheduleHistoryItem buildLocalScheduleHistoryItem(
  SavedEventAggregate aggregate, {
  required DateTime now,
  ScheduleProgressSummary? progressSummary,
  int? totalMatchCount,
}) {
  final generatedScheduleId = aggregate.event.displayGeneratedScheduleId;
  final matchingSummary = progressSummary != null &&
          generatedScheduleId != null &&
          progressSummary.generatedScheduleId == generatedScheduleId
      ? progressSummary
      : null;
  final knownTotalMatchCount = matchingSummary?.totalMatchCount ??
      ((totalMatchCount ?? 0) > 0 ? totalMatchCount : null);
  final completedMatchCount = matchingSummary?.completedMatchCount ??
      (knownTotalMatchCount == null ? null : 0);

  return LocalScheduleHistoryItem(
    publicId: aggregate.event.publicId,
    title: aggregate.event.title,
    courtCount: aggregate.event.courtCount,
    playerCount: aggregate.players.length,
    createdAt: aggregate.event.createdAt,
    firstSavedAt: now,
    lastOpenedAt: now,
    generatedScheduleId: generatedScheduleId,
    isAdopted: aggregate.event.hasAdoptedSchedule,
    completedMatchCount: completedMatchCount,
    totalMatchCount: knownTotalMatchCount,
  );
}
