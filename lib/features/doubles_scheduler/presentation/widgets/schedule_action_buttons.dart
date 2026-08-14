import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

class ScheduleActionButtons extends StatelessWidget {
  const ScheduleActionButtons({
    super.key,
    required this.isLoading,
    required this.isAdopting,
    required this.canAdopt,
    required this.onAdopt,
  });

  final bool isLoading;
  final bool isAdopting;
  final bool canAdopt;
  final VoidCallback? onAdopt;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return FilledButton.icon(
      onPressed: (isLoading || isAdopting || !canAdopt) ? null : onAdopt,
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
    );
  }
}
