import 'dart:async';

import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

import '../data/local_schedule_history_item.dart';
import 'widgets/schedule_history_list_view.dart';

class DoublesScheduleListDrawer extends StatefulWidget {
  const DoublesScheduleListDrawer({
    super.key,
    required this.onOpenSchedule,
    this.reloadToken = 0,
  });

  final ValueChanged<LocalScheduleHistoryItem> onOpenSchedule;
  final int reloadToken;

  static double widthFor(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return screenWidth * 0.85;
  }

  @override
  State<DoublesScheduleListDrawer> createState() =>
      _DoublesScheduleListDrawerState();
}

class _DoublesScheduleListDrawerState extends State<DoublesScheduleListDrawer> {
  final _historyController = ScheduleHistoryListController();

  @override
  void dispose() {
    unawaited(_historyController.flushSelection());
    super.dispose();
  }

  Future<void> _closeDrawer() async {
    await _historyController.flushSelection();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvokedWithResult: (_, __) {
        unawaited(_historyController.flushSelection());
      },
      child: Drawer(
        width: DoublesScheduleListDrawer.widthFor(context),
        child: SafeArea(
          child: DoublesScheduleListPanel(
            reloadToken: widget.reloadToken,
            historyController: _historyController,
            onBack: _closeDrawer,
            onOpenSchedule: widget.onOpenSchedule,
          ),
        ),
      ),
    );
  }
}

class DoublesScheduleListPanel extends StatelessWidget {
  const DoublesScheduleListPanel({
    super.key,
    required this.onBack,
    required this.onOpenSchedule,
    this.reloadToken = 0,
    this.historyController,
  });

  final VoidCallback onBack;
  final ValueChanged<LocalScheduleHistoryItem> onOpenSchedule;
  final int reloadToken;
  final ScheduleHistoryListController? historyController;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.arrow_back),
          title: Text(
            l10n.matchTableList,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          onTap: onBack,
        ),
        const Divider(height: 1),
        Expanded(
          child: ScheduleHistoryListView(
            padding: const EdgeInsets.all(12),
            reloadToken: reloadToken,
            controller: historyController,
            onOpenSchedule: onOpenSchedule,
          ),
        ),
      ],
    );
  }
}
