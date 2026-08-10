import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

import '../../data/local_schedule_history_item.dart';
import '../../data/local_schedule_history_store.dart';

class ScheduleHistoryListView extends StatefulWidget {
  const ScheduleHistoryListView({
    super.key,
    required this.onOpenSchedule,
    this.padding = const EdgeInsets.all(16),
    this.reloadToken = 0,
    this.onItemsLoaded,
  });

  final ValueChanged<LocalScheduleHistoryItem> onOpenSchedule;
  final EdgeInsetsGeometry padding;
  final int reloadToken;
  final ValueChanged<List<LocalScheduleHistoryItem>>? onItemsLoaded;

  @override
  State<ScheduleHistoryListView> createState() =>
      _ScheduleHistoryListViewState();
}

class _ScheduleHistoryListViewState extends State<ScheduleHistoryListView> {
  final LocalScheduleHistoryStore _historyStore = LocalScheduleHistoryStore();

  late Future<List<LocalScheduleHistoryItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _loadItems();
  }

  @override
  void didUpdateWidget(covariant ScheduleHistoryListView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.reloadToken != widget.reloadToken) {
      _reloadItems();
    }
  }

  Future<List<LocalScheduleHistoryItem>> _loadItems() async {
    final items = await _historyStore.findAll();

    if (mounted) {
      widget.onItemsLoaded?.call(items);
    }

    return items;
  }

  void _reloadItems() {
    setState(() {
      _itemsFuture = _loadItems();
    });
  }

  Future<void> _refreshItems() async {
    final future = _loadItems();

    setState(() {
      _itemsFuture = future;
    });

    await future;
  }

  String _formatDateTime(DateTime dateTime) {
    final local = dateTime.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');
    final hh = local.hour.toString().padLeft(2, '0');
    final mm = local.minute.toString().padLeft(2, '0');

    return '$y/$m/$d $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return FutureBuilder<List<LocalScheduleHistoryItem>>(
      future: _itemsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return _ScheduleHistoryMessage(
            message: l10n.reloadScheduleFailedMessage(
              snapshot.error.toString(),
            ),
            actionLabel: l10n.refreshLatestButton,
            onActionPressed: _reloadItems,
          );
        }

        final items = snapshot.data ?? const [];

        if (items.isEmpty) {
          return _ScheduleHistoryMessage(
            message: l10n.scheduleHistoryEmptyMessage,
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshItems,
          child: ListView.separated(
            padding: widget.padding,
            physics: const AlwaysScrollableScrollPhysics(),
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
                  onTap: () => widget.onOpenSchedule(item),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ScheduleHistoryMessage extends StatelessWidget {
  const _ScheduleHistoryMessage({
    required this.message,
    this.actionLabel,
    this.onActionPressed,
  });

  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.refresh),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
