import 'package:flutter/material.dart';

class ScheduleEventSummaryCard extends StatelessWidget {
  const ScheduleEventSummaryCard({
    super.key,
    this.onCopyShareUrl,
    this.onRefresh,
    this.canRefresh = true,
  });

  final VoidCallback? onCopyShareUrl;
  final VoidCallback? onRefresh;
  final bool canRefresh;

  @override
  Widget build(BuildContext context) {
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
                if (onCopyShareUrl != null)
                  OutlinedButton.icon(
                    onPressed: onCopyShareUrl,
                    icon: const Icon(Icons.copy),
                    label: const Text('URLをコピー'),
                  ),
                if (onRefresh != null)
                  FilledButton.tonalIcon(
                    onPressed: canRefresh ? onRefresh : null,
                    icon: const Icon(Icons.sync),
                    label: const Text('最新の情報に更新'),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'URLを共有して対戦表をみんなで確認しましょう٩( ᐛ )و',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
