import 'package:flutter/foundation.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';

abstract final class DoublesProgressUiStore {
  static final ValueNotifier<String?> progressText = ValueNotifier<String?>(
    null,
  );

  static void setSummary(ScheduleProgressSummary? summary) {
    progressText.value = summary == null
        ? '- / -'
        : '${summary.completedMatchCount} / ${summary.totalMatchCount}';
  }
}
