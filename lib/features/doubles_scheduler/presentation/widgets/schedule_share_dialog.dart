import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

class ScheduleShareDialog extends StatelessWidget {
  const ScheduleShareDialog({
    super.key,
    required this.onCopyShareUrl,
  });

  final VoidCallback onCopyShareUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: const Text('URLを共有'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const ScheduleShareQrPlaceholder(),
          const SizedBox(height: 12),
          Text(
            l10n.shareUrlDescription,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onCopyShareUrl,
              icon: const Icon(Icons.copy),
              label: Text(l10n.copyUrlButton),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('閉じる'),
        ),
      ],
    );
  }
}

class ScheduleShareQrPlaceholder extends StatelessWidget {
  const ScheduleShareQrPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: 'QRコード表示枠',
      child: Container(
        width: 220,
        height: 220,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.qr_code_2,
              size: 80,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'QRコードをここに表示します',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
