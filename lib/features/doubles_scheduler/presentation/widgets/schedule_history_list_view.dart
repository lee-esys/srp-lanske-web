import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';
import 'package:srp_lanske/shared/presentation/app_message_type.dart';
import 'package:srp_lanske/shared/presentation/app_snack_bar.dart';

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
  bool _selectionMode = false;
  bool _isUpdating = false;

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

  Future<void> _setPendingRemoval(
    LocalScheduleHistoryItem item,
    bool isPendingRemoval,
  ) async {
    if (_isUpdating) return;

    setState(() {
      _isUpdating = true;
    });
    try {
      await _historyStore.setPendingRemoval(
        publicId: item.publicId,
        isPendingRemoval: isPendingRemoval,
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isUpdating = false;
        _itemsFuture = _loadItems();
      });
    }
  }

  Future<void> _markAllUnconfirmed(
    List<LocalScheduleHistoryItem> items,
  ) async {
    if (_isUpdating) return;

    final publicIds = items
        .where((item) => item.isAdopted == false)
        .map((item) => item.publicId)
        .toList(growable: false);
    if (publicIds.isEmpty) return;

    setState(() {
      _isUpdating = true;
    });
    try {
      await _historyStore.setPendingRemovalForPublicIds(
        publicIds,
        isPendingRemoval: true,
      );
    } finally {
      if (!mounted) return;
      setState(() {
        _isUpdating = false;
        _itemsFuture = _loadItems();
      });
    }
  }

  Future<void> _confirmSuppressPending() async {
    if (_isUpdating) return;

    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.clearScheduleHistoryConfirmTitle),
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

    setState(() {
      _isUpdating = true;
    });
    var suppressedCount = 0;
    try {
      suppressedCount = await _historyStore.suppressPendingRemoval();
    } finally {
      if (!mounted) return;
      setState(() {
        _isUpdating = false;
        _selectionMode = false;
        _itemsFuture = _loadItems();
      });
    }

    if (!mounted || suppressedCount <= 0) return;
    AppSnackBar.show(
      context,
      message: l10n.scheduleHistoryClearedMessage,
      type: AppMessageType.success,
    );
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

        final pendingCount =
            items.where((item) => item.isPendingRemoval).length;
        final hasUnconfirmed = items.any((item) => item.isAdopted == false);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Wrap(
                alignment: WrapAlignment.end,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  if (_selectionMode && hasUnconfirmed)
                    TextButton.icon(
                      onPressed: _isUpdating
                          ? null
                          : () => _markAllUnconfirmed(items),
                      icon: const Icon(Icons.select_all),
                      label: Text(l10n.scheduleHistoryUnconfirmedLabel),
                    ),
                  if (_selectionMode)
                    TextButton.icon(
                      onPressed: _isUpdating
                          ? null
                          : () {
                              setState(() {
                                _selectionMode = false;
                              });
                            },
                      icon: const Icon(Icons.check),
                      label: Text(l10n.confirmButton),
                    )
                  else
                    IconButton(
                      onPressed: _isUpdating
                          ? null
                          : () {
                              setState(() {
                                _selectionMode = true;
                              });
                            },
                      icon: const Icon(Icons.delete_outline),
                      tooltip: l10n.clearScheduleHistoryTooltip,
                    ),
                  if (pendingCount > 0)
                    FilledButton.tonalIcon(
                      onPressed: _isUpdating ? null : _confirmSuppressPending,
                      icon: const Icon(Icons.delete_sweep_outlined),
                      label: Text(l10n.clearScheduleHistoryActionButton),
                    ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
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
                      selectionMode: _selectionMode,
                      onTap: () {
                        if (_selectionMode) {
                          _setPendingRemoval(item, !item.isPendingRemoval);
                          return;
                        }
                        widget.onOpenSchedule(item);
                      },
                      onSelectionChanged: (value) {
                        _setPendingRemoval(item, value);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ScheduleHistoryListItem extends StatelessWidget {
  const _ScheduleHistoryListItem({
    required this.item,
    required this.selectionMode,
    required this.onTap,
    required this.onSelectionChanged,
  });

  final LocalScheduleHistoryItem item;
  final bool selectionMode;
  final VoidCallback onTap;
  final ValueChanged<bool> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: item.isPendingRemoval ? colorScheme.surfaceContainerHighest : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectionMode) ...[
                Checkbox(
                  value: item.isPendingRemoval,
                  onChanged: (value) {
                    if (value != null) {
                      onSelectionChanged(value);
                    }
                  },
                ),
                const SizedBox(width: 4),
              ],
              Expanded(
                child: Opacity(
                  opacity: item.isPendingRemoval ? 0.55 : 1,
                  child: _ScheduleHistoryListItemBody(item: item),
                ),
              ),
              if (!selectionMode) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
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
