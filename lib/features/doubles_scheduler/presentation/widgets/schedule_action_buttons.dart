import 'package:flutter/material.dart';

class ScheduleActionButtons extends StatelessWidget {
  const ScheduleActionButtons({
    super.key,
    required this.hasAdoptedSchedule,
    required this.isLoading,
    required this.isAdopting,
    required this.generateButtonLabel,
    required this.canReload,
    required this.canAdopt,
    required this.onGenerate,
    required this.onReload,
    required this.onAdopt,
  });

  final bool hasAdoptedSchedule;
  final bool isLoading;
  final bool isAdopting;
  final String generateButtonLabel;
  final bool canReload;
  final bool canAdopt;
  final VoidCallback? onGenerate;
  final VoidCallback? onReload;
  final VoidCallback? onAdopt;

  @override
  Widget build(BuildContext context) {
    if (hasAdoptedSchedule) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Chip(
            avatar: Icon(Icons.check),
            label: Text('採用済み'),
          ),
          FilledButton.tonalIcon(
            onPressed: isLoading ? null : onReload,
            icon: const Icon(Icons.sync),
            label: const Text('最新の情報に更新'),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          onPressed: isLoading ? null : onGenerate,
          icon: const Icon(Icons.refresh),
          label: Text(generateButtonLabel),
        ),
        FilledButton.tonalIcon(
          onPressed: (isLoading || !canReload) ? null : onReload,
          icon: const Icon(Icons.sync),
          label: const Text('最新の情報に更新'),
        ),
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
  }
}
