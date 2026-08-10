import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';
import 'package:srp_lanske/shared/presentation/app_message_type.dart';
import 'package:srp_lanske/shared/presentation/app_snack_bar.dart';
import 'package:srp_lanske/shared/utils/browser_url.dart';

import '../application/schedule_share_url.dart';
import '../data/local_schedule_history_item.dart';
import '../data/local_schedule_history_store.dart';
import 'restored_schedule_page.dart';
import 'widgets/schedule_history_list_view.dart';

class EventListPage extends StatefulWidget {
  const EventListPage({
    super.key,
    this.currentPublicId,
  });

  final String? currentPublicId;

  @override
  State<EventListPage> createState() => _EventListPageState();
}

class _EventListPageState extends State<EventListPage> {
  final _historyStore = LocalScheduleHistoryStore();

  bool _canClearHistory = false;
  int _reloadToken = 0;

  String? get _currentPublicId {
    final publicId = widget.currentPublicId?.trim().toUpperCase();
    if (publicId == null || publicId.isEmpty) return null;
    return publicId;
  }

  void _openSchedule(LocalScheduleHistoryItem item) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RestoredSchedulePage(publicId: item.publicId),
      ),
    );

    replaceUrl(
      buildScheduleShareUrl(
        baseUri: Uri.base,
        publicId: item.publicId,
      ),
    );
  }

  bool _hasClearableHistory(List<LocalScheduleHistoryItem> items) {
    final currentPublicId = _currentPublicId;
    if (currentPublicId == null) return items.isNotEmpty;

    return items.any(
      (item) => item.publicId.trim().toUpperCase() != currentPublicId,
    );
  }

  void _handleItemsLoaded(List<LocalScheduleHistoryItem> items) {
    final canClearHistory = _hasClearableHistory(items);
    if (canClearHistory == _canClearHistory) return;

    setState(() {
      _canClearHistory = canClearHistory;
    });
  }

  void _reloadItems() {
    setState(() {
      _canClearHistory = false;
      _reloadToken += 1;
    });
  }

  Future<void> _confirmClearHistory() async {
    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.clearScheduleHistoryConfirmTitle),
          content: Text(l10n.clearScheduleHistoryConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.clearScheduleHistoryActionButton),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    final currentPublicId = _currentPublicId;
    if (currentPublicId == null) {
      await _historyStore.clearAll();
    } else {
      await _historyStore.clearExceptPublicId(currentPublicId);
    }

    if (!mounted) return;

    _showMessage(l10n.scheduleHistoryClearedMessage);
    _reloadItems();
  }

  void _showMessage(String message) {
    AppSnackBar.show(
      context,
      message: message,
      type: AppMessageType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.matchTableList),
        actions: [
          if (_canClearHistory)
            IconButton(
              onPressed: _confirmClearHistory,
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: l10n.clearScheduleHistoryTooltip,
            ),
        ],
      ),
      body: ScheduleHistoryListView(
        reloadToken: _reloadToken,
        onItemsLoaded: _handleItemsLoaded,
        onOpenSchedule: _openSchedule,
      ),
    );
  }
}
