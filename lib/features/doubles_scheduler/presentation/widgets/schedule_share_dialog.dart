import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

class ScheduleShareDialog extends StatelessWidget {
  const ScheduleShareDialog({
    super.key,
    required this.shareUrl,
    required this.onCopyShareUrl,
  });

  final String shareUrl;
  final VoidCallback onCopyShareUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.shareUrlDialogTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ScheduleShareQrPlaceholder(shareUrl: shareUrl),
          const SizedBox(height: 12),
          Text(
            l10n.shareQrDescription,
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
          child: Text(l10n.closeButton),
        ),
      ],
    );
  }
}

class ScheduleShareQrPlaceholder extends StatelessWidget {
  const ScheduleShareQrPlaceholder({
    super.key,
    required this.shareUrl,
  });

  final String shareUrl;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      label: l10n.shareQrPlaceholderSemanticLabel,
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
                l10n.shareQrPlaceholderLabel,
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
