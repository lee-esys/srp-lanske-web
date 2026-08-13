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
      _itemsFuture = _loadItems();
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

              return _ScheduleHistoryListItem(
                item: item,
                onTap: () => widget.onOpenSchedule(item),
              );
            },
          ),
        );
      },
    );
  }
}

class _ScheduleHistoryListItem extends StatelessWidget {
  const _ScheduleHistoryListItem({
    required this.item,
    required this.onTap,
  });

  final LocalScheduleHistoryItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ScheduleHistoryListItemBody(item: item),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScheduleHistoryListItemBody extends StatelessWidget {
  const _ScheduleHistoryListItemBody({required this.item});

  final LocalScheduleHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final completedMatchCount = item.completedMatchCount;
    final totalMatchCount = item.totalMatchCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          item.title,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _ScheduleHistoryListChip(
              icon: Icons.grid_view_outlined,
              label: '${l10n.courtCountLabel} ${item.courtCount}',
            ),
            _ScheduleHistoryListChip(
              icon: Icons.person_outline,
              label: '${l10n.playerCountLabel} ${item.playerCount}',
            ),
            _ScheduleHistoryListChip(
              icon: Icons.calendar_today_outlined,
              label: l10n.scheduleHistoryCreatedAtLabel(
                _formatDate(item.createdAt),
              ),
            ),
            if (item.isAdopted == false)
              _ScheduleHistoryListChip(
                icon: Icons.pending_outlined,
                label: l10n.scheduleHistoryUnconfirmedLabel,
              )
            else if (item.isAdopted == true &&
                completedMatchCount != null &&
                totalMatchCount != null)
              _ScheduleHistoryListChip(
                icon: Icons.check_circle_outline,
                label: l10n.scheduleHistoryCompletedMatchesLabel(
                  completedMatchCount,
                  totalMatchCount,
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime dateTime) {
    final local = dateTime.toLocal();
    final y = local.year.toString().padLeft(4, '0');
    final m = local.month.toString().padLeft(2, '0');
    final d = local.day.toString().padLeft(2, '0');

    return '$y/$m/$d';
  }
}

class _ScheduleHistoryListChip extends StatelessWidget {
  const _ScheduleHistoryListChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: colorScheme.surfaceContainerHighest,
      side: BorderSide.none,
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
