import 'package:flutter/material.dart';

class ScheduleEventSummaryCard extends StatelessWidget {
  const ScheduleEventSummaryCard({
    super.key,
    required this.statusLabel,
    this.onCopyShareUrl,
    this.onRefresh,
    this.canRefresh = true,
  });

  final String statusLabel;
  final VoidCallback? onCopyShareUrl;
  final VoidCallback? onRefresh;
  final bool canRefresh;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            // Chip(
            //   label: Text(statusLabel, style: TextStyle(fontSize: 14)),
            //   visualDensity: VisualDensity.compact,
            // ),
            if (onCopyShareUrl != null)
              OutlinedButton.icon(
                onPressed: onCopyShareUrl,
                icon: const Icon(Icons.copy),
                label: const Text('共有URLをコピー'),
              ),
            if (onRefresh != null)
              FilledButton.tonalIcon(
                onPressed: canRefresh ? onRefresh : null,
                icon: const Icon(Icons.sync),
                label: const Text('最新の情報に更新'),
              ),
          ],
        ),
      ),
    );
  }
}
