import 'package:flutter/material.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/doubles_progress_visuals.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';

class DoublesMatchCardContent extends StatelessWidget {
  const DoublesMatchCardContent({
    super.key,
    required this.hasAdoptedSchedule,
    required this.courtLabel,
    required this.showCourtLabel,
    required this.side1,
    required this.side2,
    required this.progress,
    required this.status,
    required this.visualStyle,
    required this.statusLabel,
    required this.winnerLabel,
    required this.loserLabel,
    required this.drawLabel,
  });

  final bool hasAdoptedSchedule;
  final String courtLabel;
  final bool showCourtLabel;
  final Widget side1;
  final Widget side2;
  final ScheduleMatchProgress? progress;
  final ScheduleMatchStatus status;
  final DoublesMatchVisualStyle visualStyle;
  final String statusLabel;
  final String winnerLabel;
  final String loserLabel;
  final String drawLabel;

  @override
  Widget build(BuildContext context) {
    final scores =
        progress?.result?.type == ScheduleMatchResultSummary.simpleScoreType &&
                (progress?.result?.sideScores.length ?? 0) >= 2
            ? progress!.result!.sideScores
            : const <int>[];
    final outcomeScores =
        status == ScheduleMatchStatus.completed ? scores : const <int>[];
    final side1Outcome = resolveDoublesMatchSideOutcome(
      outcomeScores,
      sideIndex: 0,
    );
    final side2Outcome = resolveDoublesMatchSideOutcome(
      outcomeScores,
      sideIndex: 1,
    );
    final isDraw = side1Outcome == DoublesMatchSideOutcome.draw;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasAdoptedSchedule) ...[
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Chip(
                key: ValueKey('match-status-${status.value}'),
                visualDensity: VisualDensity.compact,
                backgroundColor: visualStyle.statusBackgroundColor,
                side: BorderSide(color: visualStyle.statusBorderColor),
                labelStyle: TextStyle(
                  color: visualStyle.statusForegroundColor,
                  fontWeight: FontWeight.w600,
                ),
                label: Text(statusLabel),
              ),
              if (scores.length >= 2) ...[
                const SizedBox(width: 8),
                Text(
                  '${scores[0]} - ${scores[1]}',
                  key: const ValueKey('match-score'),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ],
              if (progress?.note.trim().isNotEmpty ?? false) ...[
                const SizedBox(width: 6),
                const Icon(Icons.note_alt_outlined, size: 18),
              ],
            ],
          ),
          const SizedBox(height: 6),
        ],
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (showCourtLabel) ...[
              Text(
                courtLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 8),
            ],
            _OutcomeTeamFrame(
              outcome: side1Outcome,
              winnerLabel: winnerLabel,
              loserLabel: loserLabel,
              child: side1,
            ),
            const SizedBox(width: 6),
            if (isDraw) _DrawBadge(label: drawLabel) else const Text('vs'),
            const SizedBox(width: 6),
            _OutcomeTeamFrame(
              outcome: side2Outcome,
              winnerLabel: winnerLabel,
              loserLabel: loserLabel,
              child: side2,
            ),
          ],
        ),
      ],
    );
  }
}

enum DoublesMatchSideOutcome {
  none,
  winner,
  loser,
  draw,
}

DoublesMatchSideOutcome resolveDoublesMatchSideOutcome(
  List<int> scores, {
  required int sideIndex,
}) {
  if (scores.length < 2) {
    return DoublesMatchSideOutcome.none;
  }
  if (scores[0] == scores[1]) {
    return DoublesMatchSideOutcome.draw;
  }

  final sideWon =
      sideIndex == 0 ? scores[0] > scores[1] : scores[1] > scores[0];
  return sideWon
      ? DoublesMatchSideOutcome.winner
      : DoublesMatchSideOutcome.loser;
}

class DoublesMatchInputHint extends StatelessWidget {
  const DoublesMatchInputHint({
    super.key,
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall;

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(Icons.info_outline, size: 16),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                message,
                key: const ValueKey('doubles-match-input-hint'),
                style: textStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OutcomeTeamFrame extends StatelessWidget {
  const _OutcomeTeamFrame({
    required this.outcome,
    required this.winnerLabel,
    required this.loserLabel,
    required this.child,
  });

  final DoublesMatchSideOutcome outcome;
  final String winnerLabel;
  final String loserLabel;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor = switch (outcome) {
      DoublesMatchSideOutcome.none => Colors.transparent,
      DoublesMatchSideOutcome.winner => colorScheme.tertiaryContainer,
      DoublesMatchSideOutcome.loser => colorScheme.surfaceContainerHighest,
      DoublesMatchSideOutcome.draw => colorScheme.secondaryContainer,
    };
    final borderColor = switch (outcome) {
      DoublesMatchSideOutcome.none => Colors.transparent,
      DoublesMatchSideOutcome.winner => colorScheme.tertiary,
      DoublesMatchSideOutcome.loser => colorScheme.outline,
      DoublesMatchSideOutcome.draw => colorScheme.secondary,
    };
    final label = switch (outcome) {
      DoublesMatchSideOutcome.winner => winnerLabel,
      DoublesMatchSideOutcome.loser => loserLabel,
      DoublesMatchSideOutcome.none => null,
      DoublesMatchSideOutcome.draw => null,
    };
    final labelForegroundColor = switch (outcome) {
      DoublesMatchSideOutcome.winner => colorScheme.onTertiaryContainer,
      DoublesMatchSideOutcome.loser => colorScheme.onSurfaceVariant,
      DoublesMatchSideOutcome.none => colorScheme.onSurface,
      DoublesMatchSideOutcome.draw => colorScheme.onSurface,
    };

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(5, 4, 5, 3),
          decoration: BoxDecoration(
            color: backgroundColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: child,
        ),
        if (label != null)
          Positioned(
            top: -8,
            right: 6,
            child: Container(
              key: ValueKey('match-outcome-$label'),
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: labelForegroundColor,
                  fontSize: 9,
                  height: 1.1,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DrawBadge extends StatelessWidget {
  const _DrawBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      key: const ValueKey('match-outcome-draw'),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        border: Border.all(color: colorScheme.secondary),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colorScheme.onSecondaryContainer,
          fontSize: 9,
          height: 1.1,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
