import 'package:flutter/material.dart';

class ScheduleActionButtons extends StatelessWidget {
  const ScheduleActionButtons({
    super.key,
    required this.isLoading,
    required this.isAdopting,
    required this.generateButtonLabel,
    required this.canAdopt,
    required this.onGenerate,
    required this.onAdopt,
  });

  final bool isLoading;
  final bool isAdopting;
  final String generateButtonLabel;
  final bool canAdopt;
  final VoidCallback? onGenerate;
  final VoidCallback? onAdopt;

  @override
  Widget build(BuildContext context) {
    final buttons = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        FilledButton.icon(
          onPressed: isLoading ? null : onGenerate,
          icon: const Icon(Icons.refresh),
          label: Text(generateButtonLabel),
        ),
        const SizedBox(width: 12),
        FilledButton.icon(
          onPressed: (isLoading || isAdopting || !canAdopt) ? null : onAdopt,
          icon: isAdopting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check),
          label: Text(isAdopting ? '採用中' : 'この対戦表を採用'),
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
