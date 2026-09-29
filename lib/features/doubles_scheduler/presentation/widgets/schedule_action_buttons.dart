import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

class ScheduleActionButtons extends StatelessWidget {
  const ScheduleActionButtons({
    super.key,
    required this.isGenerating,
    required this.isAdopting,
    required this.generateButtonLabel,
    required this.canAdopt,
    required this.onGenerate,
    required this.onAdopt,
  });

  final bool isGenerating;
  final bool isAdopting;
  final String generateButtonLabel;
  final bool canAdopt;
  final VoidCallback? onGenerate;
  final VoidCallback? onAdopt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final buttons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.tonalIcon(
          onPressed: isGenerating ? null : onGenerate,
          icon: isGenerating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          label: Text(
            isGenerating ? l10n.processingButton : generateButtonLabel,
          ),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: (isGenerating || isAdopting || !canAdopt) ? null : onAdopt,
          icon: isAdopting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(
            isAdopting ? l10n.processingButton : l10n.adoptScheduleButton,
          ),
        ),
      ],
    );

    return Wrap(
      spacing: 12,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        buttons,
      ],
    );
  }
}
