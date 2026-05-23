import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

import 'schedule_action_buttons.dart';

class ScheduleOperationPanel extends StatelessWidget {
  const ScheduleOperationPanel({
    super.key,
    required this.courtDisplaySummary,
    required this.canChangeCourtDisplay,
    required this.onChangeCourtDisplay,
    required this.showActionButtons,
    required this.isLoading,
    required this.isAdopting,
    required this.generateButtonLabel,
    required this.canAdopt,
    required this.onGenerate,
    required this.onAdopt,
  });

  final String courtDisplaySummary;
  final bool canChangeCourtDisplay;
  final VoidCallback? onChangeCourtDisplay;

  final bool showActionButtons;
  final bool isLoading;
  final bool isAdopting;
  final String generateButtonLabel;
  final bool canAdopt;
  final VoidCallback? onGenerate;
  final VoidCallback? onAdopt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              l10n.courtDisplaySummary(courtDisplaySummary),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (canChangeCourtDisplay)
              TextButton.icon(
                onPressed: onChangeCourtDisplay,
                icon: const Icon(Icons.tune, size: 18),
                label: Text(l10n.changeCourtDisplayButton),
              ),
          ],
        ),
        if (showActionButtons) ...[
          const SizedBox(height: 8),
          ScheduleActionButtons(
            isLoading: isLoading,
            isAdopting: isAdopting,
            generateButtonLabel: generateButtonLabel,
            canAdopt: canAdopt,
            onGenerate: onGenerate,
            onAdopt: onAdopt,
          ),
        ],
      ],
    );
  }
}
