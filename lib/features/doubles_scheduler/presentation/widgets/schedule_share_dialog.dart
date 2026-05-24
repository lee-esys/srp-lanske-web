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
      titlePadding: const EdgeInsets.fromLTRB(24, 16, 8, 0),
      title: Row(
        children: [
          const Expanded(child: Text('URLを共有')),
          IconButton(
            tooltip: '閉じる',
            onPressed: () => Navigator.pop(context),
            iconSize: 36,
            constraints: const BoxConstraints.tightFor(
              width: 56,
              height: 56,
            ),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.cancel_presentation),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const ScheduleShareQrPlaceholder(),
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
