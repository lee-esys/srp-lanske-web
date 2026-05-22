import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

class EventSetupActionButtons extends StatelessWidget {
  const EventSetupActionButtons({
    super.key,
    required this.isLoadingEvent,
    required this.onReset,
    required this.onSubmit,
  });

  final bool isLoadingEvent;
  final VoidCallback onReset;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FilledButton.tonal(
          onPressed: isLoadingEvent ? null : onReset,
          style: FilledButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            l10n.resetInputsButton,
            style: const TextStyle(fontSize: 16),
          ),
        ),
        const SizedBox(width: 12),
        FilledButton(
          onPressed: isLoadingEvent ? null : onSubmit,
          style: FilledButton.styleFrom(
            minimumSize: Size.zero,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: Text(
            l10n.generateScheduleButton,
            style: const TextStyle(fontSize: 22),
          ),
        ),
      ],
    );
  }
}
