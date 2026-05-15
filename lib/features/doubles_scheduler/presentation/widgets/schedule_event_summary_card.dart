import 'package:flutter/material.dart';

class ScheduleEventSummaryCard extends StatelessWidget {
  const ScheduleEventSummaryCard({
    super.key,
    required this.courtCount,
    required this.participantCount,
    required this.statusLabel,
    this.onCopyShareUrl,
    this.onRefresh,
    this.canRefresh = true,
  });

  final int courtCount;
  final int participantCount;
  final String statusLabel;
  final VoidCallback? onCopyShareUrl;
  final VoidCallback? onRefresh;
  final bool canRefresh;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text('面数: $courtCount'),
            Text('参加者: $participantCount人'),
            Chip(
              label: Text(statusLabel),
              visualDensity: VisualDensity.compact,
            ),
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
