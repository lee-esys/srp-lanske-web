import 'package:flutter/material.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/doubles_progress_ui_store.dart';
import 'package:srp_lanske/l10n/l10n.dart';

class ScheduleEventSummaryCard extends StatelessWidget {
  const ScheduleEventSummaryCard({
    super.key,
    this.onShareUrl,
    this.onRefresh,
    this.canRefresh = true,
    this.isRefreshing = false,
    this.progressText,
  });

  final VoidCallback? onShareUrl;
  final VoidCallback? onRefresh;
  final bool canRefresh;
  final bool isRefreshing;
  final String? progressText;

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
                    onPressed: canRefresh && !isRefreshing ? onRefresh : null,
                    icon: isRefreshing
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.sync),
                    label: Text(l10n.refreshLatestButton),
                  ),
                ValueListenableBuilder<String?>(
                  valueListenable: DoublesProgressUiStore.progressText,
                  builder: (context, latestProgressText, child) {
                    final displayProgressText =
                        latestProgressText ?? progressText;
                    if (displayProgressText == null) {
                      return const SizedBox.shrink();
                    }

                    return Chip(
                      avatar: const Icon(Icons.sports_score, size: 18),
                      label: Text(displayProgressText),
                    );
                  },
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
