import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';

enum DoublesProgressNavigationUiKind {
  inProgress,
  nextMatch,
  completed,
}

class DoublesProgressNavigationUiState {
  const DoublesProgressNavigationUiState({
    required this.kind,
    required this.roundNo,
    required this.courtLabel,
    required this.side1PlayerNames,
    required this.side2PlayerNames,
    required this.inProgressMatchCount,
    required this.targetKey,
    required this.onNavigate,
  });

  const DoublesProgressNavigationUiState.completed()
      : kind = DoublesProgressNavigationUiKind.completed,
        roundNo = null,
        courtLabel = null,
        side1PlayerNames = const [],
        side2PlayerNames = const [],
        inProgressMatchCount = 0,
        targetKey = null,
        onNavigate = null;

  final DoublesProgressNavigationUiKind kind;
  final int? roundNo;
  final String? courtLabel;
  final List<String> side1PlayerNames;
  final List<String> side2PlayerNames;
  final int inProgressMatchCount;
  final String? targetKey;
  final Future<void> Function()? onNavigate;

  bool get canNavigate => targetKey != null && onNavigate != null;
}

abstract final class DoublesProgressUiStore {
  static final ValueNotifier<String?> progressText = ValueNotifier<String?>(
    null,
  );

  static final ValueNotifier<DoublesProgressNavigationUiState?> navigation =
      ValueNotifier<DoublesProgressNavigationUiState?>(null);

  static final ValueNotifier<Future<void> Function()?> completedNavigation =
      ValueNotifier<Future<void> Function()?>(null);

  static void clearOverride() {
    _setValueSafely(progressText, null);
    _setValueSafely(navigation, null);
    _setValueSafely(completedNavigation, null);
  }

  static void setSummary(
    ScheduleProgressSummary? summary, {
    int? totalMatchCount,
  }) {
    if (summary != null) {
      _setValueSafely(
        progressText,
        '${summary.completedMatchCount} / ${summary.totalMatchCount}',
      );
      return;
    }

    _setValueSafely(
      progressText,
      totalMatchCount != null && totalMatchCount > 0
          ? '0 / $totalMatchCount'
          : '- / -',
    );
  }

  static void setNavigation(DoublesProgressNavigationUiState? value) {
    _setValueSafely(navigation, value);
  }

  static void setCompletedNavigation(Future<void> Function()? value) {
    _setValueSafely(completedNavigation, value);
  }

  static void _setValueSafely<T>(ValueNotifier<T> notifier, T value) {
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        notifier.value = value;
      });
      return;
    }

    notifier.value = value;
  }
}
