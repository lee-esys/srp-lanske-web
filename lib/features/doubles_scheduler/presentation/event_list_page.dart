import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';
import 'package:srp_lanske/shared/utils/browser_url.dart';

import '../data/local_schedule_history_item.dart';
import '../data/local_schedule_history_store.dart';
import 'restored_schedule_page.dart';

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

  late Future<List<LocalScheduleHistoryItem>> _itemsFuture;
  bool _canClearHistory = false;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _loadItems();
  }

  String? get _currentPublicId {
    final publicId = widget.currentPublicId?.trim().toUpperCase();
    if (publicId == null || publicId.isEmpty) return null;
    return publicId;
  }

  String _formatDateTime(DateTime dateTime) {
    final y = dateTime.year.toString().padLeft(4, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');

    return '$y/$m/$d $hh:$mm';
  }

  void _openSchedule(LocalScheduleHistoryItem item) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => RestoredSchedulePage(publicId: item.publicId),
      ),
    );

    _replaceBrowserUrlWithPublicId(item.publicId);
  }

  void _replaceBrowserUrlWithPublicId(String publicId) {
    replaceUrl(
      Uri.base.replace(
        queryParameters: {
          ...Uri.base.queryParameters,
          'sid': publicId,
        },
      ).toString(),
    );
  }

  Future<List<LocalScheduleHistoryItem>> _loadItems() async {
    final items = await _historyStore.findAll();
    if (!mounted) return items;

    setState(() {
      _canClearHistory = _hasClearableHistory(items);
    });

    return items;
  }

  bool _hasClearableHistory(List<LocalScheduleHistoryItem> items) {
    final currentPublicId = _currentPublicId;
    if (currentPublicId == null) return items.isNotEmpty;

    return items.any(
      (item) => item.publicId.trim().toUpperCase() != currentPublicId,
    );
  }

  void _reloadItems() {
    setState(() {
      _itemsFuture = _loadItems();
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
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
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
      body: FutureBuilder<List<LocalScheduleHistoryItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  l10n.reloadScheduleFailedMessage(snapshot.error.toString()),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final items = snapshot.data ?? const [];

          if (items.isEmpty) {
            return Center(
              child: Text(l10n.scheduleHistoryEmptyMessage),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(4),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = items[index];

              return Card(
                child: ListTile(
                  title: Text(item.title),
                  subtitle: Text(
                    '${l10n.schedulePlayersTitle(item.courtCount, item.playerCount)}\n'
                    '${l10n.lastOpenedAtLabel(_formatDateTime(item.lastOpenedAt))}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _openSchedule(item),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
