import 'package:flutter/material.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';

class DoublesMatchVisualStyle {
  const DoublesMatchVisualStyle({
    required this.cardBackgroundColor,
    required this.cardBorderColor,
    required this.statusBackgroundColor,
    required this.statusForegroundColor,
    required this.statusBorderColor,
  });

  final Color cardBackgroundColor;
  final Color cardBorderColor;
  final Color statusBackgroundColor;
  final Color statusForegroundColor;
  final Color statusBorderColor;
}

DoublesMatchVisualStyle resolveDoublesMatchVisualStyle(
  ColorScheme colorScheme,
  ScheduleMatchStatus status,
) {
  return switch (status) {
    ScheduleMatchStatus.scheduled => DoublesMatchVisualStyle(
        cardBackgroundColor: Colors.transparent,
        cardBorderColor: colorScheme.outlineVariant,
        statusBackgroundColor: colorScheme.surface,
        statusForegroundColor: colorScheme.onSurfaceVariant,
        statusBorderColor: colorScheme.outlineVariant,
      ),
    ScheduleMatchStatus.inProgress => DoublesMatchVisualStyle(
        cardBackgroundColor: Color.alphaBlend(
          colorScheme.error.withValues(alpha: 0.10),
          colorScheme.surface,
        ),
        cardBorderColor: colorScheme.error.withValues(alpha: 0.78),
        statusBackgroundColor: colorScheme.errorContainer,
        statusForegroundColor: colorScheme.onErrorContainer,
        statusBorderColor: colorScheme.error,
      ),
    ScheduleMatchStatus.completed => DoublesMatchVisualStyle(
        cardBackgroundColor: colorScheme.surfaceContainerHighest,
        cardBorderColor: colorScheme.outline,
        statusBackgroundColor: Color.alphaBlend(
          colorScheme.onSurface.withValues(alpha: 0.14),
          colorScheme.surfaceContainerHighest,
        ),
        statusForegroundColor: colorScheme.onSurface,
        statusBorderColor: colorScheme.outline,
      ),
  };
}

Color resolveDoublesRoundCardColor(
  ColorScheme colorScheme, {
  required bool isCompleted,
  required bool isEvenRound,
}) {
  if (isCompleted) {
    return colorScheme.surfaceContainer;
  }

  return isEvenRound
      ? colorScheme.surface.withValues(alpha: 0.92)
      : colorScheme.primaryContainer.withValues(alpha: 0.92);
}

bool isDoublesRoundCompleted({
  required int? roundNo,
  required Iterable<int> courtNumbers,
  required Map<String, ScheduleMatchProgress> progressByKey,
}) {
  if (roundNo == null) return false;

  final numbers = courtNumbers.toList(growable: false);
  if (numbers.isEmpty) return false;

  return numbers.every((courtNo) {
    final key = ScheduleMatchKey(roundNo: roundNo, courtNo: courtNo).value;
    return progressByKey[key]?.status == ScheduleMatchStatus.completed;
  });
}
