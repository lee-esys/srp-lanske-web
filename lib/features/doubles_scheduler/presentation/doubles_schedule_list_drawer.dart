import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

import '../data/local_schedule_history_item.dart';
import 'widgets/schedule_history_list_view.dart';

class DoublesScheduleListDrawer extends StatelessWidget {
  const DoublesScheduleListDrawer({
    super.key,
    required this.onOpenSchedule,
    this.reloadToken = 0,
  });

  final ValueChanged<LocalScheduleHistoryItem> onOpenSchedule;
  final int reloadToken;

  static double widthFor(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return (screenWidth * 0.75).clamp(0.0, 300.0).toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Drawer(
      width: widthFor(context),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              leading: const Icon(Icons.list_alt_outlined),
              title: Text(
                l10n.matchTableList,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              trailing: IconButton(
                tooltip: l10n.closeButton,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ScheduleHistoryListView(
                padding: const EdgeInsets.all(12),
                reloadToken: reloadToken,
                onOpenSchedule: onOpenSchedule,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
