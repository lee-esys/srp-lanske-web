import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

class ScheduleEventSummaryCard extends StatelessWidget {
  const ScheduleEventSummaryCard({
    super.key,
    this.onShareUrl,
    this.onRefresh,
    this.canRefresh = true,
  });

  final VoidCallback? onShareUrl;
  final VoidCallback? onRefresh;
  final bool canRefresh;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (onShareUrl != null)
                  OutlinedButton.icon(
                    onPressed: onShareUrl,
                    icon: const Icon(Icons.share),
                    label: Text(l10n.shareUrlButton),
                  ),
                if (onRefresh != null)
                  FilledButton.tonalIcon(
                    onPressed: canRefresh ? onRefresh : null,
                    icon: const Icon(Icons.sync),
                    label: Text(l10n.refreshLatestButton),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.shareUrlDescription,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
