import 'dart:async';

import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';
import 'package:srp_lanske/shared/presentation/app_message_type.dart';
import 'package:srp_lanske/shared/presentation/app_snack_bar.dart';

import '../../data/local_schedule_history_item.dart';
import '../../data/local_schedule_history_store.dart';

class ScheduleHistoryListController {
  Future<void> Function()? _flushSelection;

  Future<void> flushSelection() async {
    final flushSelection = _flushSelection;
    if (flushSelection != null) {
      await flushSelection();
    }
  }

  void _attach(Future<void> Function() flushSelection) {
    _flushSelection = flushSelection;
  }

  void _detach() {
    _flushSelection = null;
  }
}

class ScheduleHistoryListView extends StatefulWidget {
  const ScheduleHistoryListView({
    super.key,
    required this.onOpenSchedule,
    this.padding = const EdgeInsets.all(16),
    this.reloadToken = 0,
    this.onItemsLoaded,
    this.controller,
  });

  final ValueChanged<LocalScheduleHistoryItem> onOpenSchedule;
  final EdgeInsetsGeometry padding;
  final int reloadToken;
  final ValueChanged<List<LocalScheduleHistoryItem>>? onItemsLoaded;
  final ScheduleHistoryListController? controller;

  @override
  State<ScheduleHistoryListView> createState() =>
      _ScheduleHistoryListViewState();
}

class _ScheduleHistoryListViewState extends State<ScheduleHistoryListView> {
  final LocalScheduleHistoryStore _historyStore = LocalScheduleHistoryStore();
  final Set<String> _draftPendingPublicIds = <String>{};
  final Set<String> _persistedPendingPublicIds = <String>{};
  Set<String> _visiblePublicIds = <String>{};

  late Future<List<LocalScheduleHistoryItem>> _itemsFuture;
  bool _selectionMode = false;
  bool _isUpdating = false;
  bool _selectionDraftInitialized = false;

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(_persistDraftSelection);
    _itemsFuture = _loadItems(resetDraft: true);
  }

  @override
  void didUpdateWidget(covariant ScheduleHistoryListView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(_persistDraftSelection);
    }

    if (oldWidget.reloadToken != widget.reloadToken) {
      _itemsFuture = _reloadAfterPersist();
    }
  }

  @override
  void dispose() {
    unawaited(_persistDraftSelection());
    widget.controller?._detach();
    super.dispose();
  }

  Future<List<LocalScheduleHistoryItem>> _loadItems({
    bool resetDraft = false,
  }) async {
    final items = await _historyStore.findAll();

    if (resetDraft || !_selectionDraftInitialized) {
      _resetDraftFromItems(items);
    } else {
      _visiblePublicIds = items
          .map((item) => _normalizePublicId(item.publicId))
          .where((publicId) => publicId.isNotEmpty)
          .toSet();
    }

    if (mounted) {
      widget.onItemsLoaded?.call(items);
    }

    return items;
  }

  Future<List<LocalScheduleHistoryItem>> _reloadAfterPersist() async {
    await _persistDraftSelection();
    _selectionDraftInitialized = false;
    return _loadItems(resetDraft: true);
  }

  void _reloadItems() {
    setState(() {
      _itemsFuture = _reloadAfterPersist();
    });
  }

  Future<void> _refreshItems() async {
    final future = _reloadAfterPersist();

    setState(() {
      _itemsFuture = future;
    });

    await future;
  }

  void _resetDraftFromItems(List<LocalScheduleHistoryItem> items) {
    _visiblePublicIds = items
        .map((item) => _normalizePublicId(item.publicId))
        .where((publicId) => publicId.isNotEmpty)
        .toSet();
    final pendingPublicIds = items
        .where((item) => item.isPendingRemoval)
        .map((item) => _normalizePublicId(item.publicId))
        .where((publicId) => publicId.isNotEmpty)
        .toSet();

    _draftPendingPublicIds
      ..clear()
      ..addAll(pendingPublicIds);
    _persistedPendingPublicIds
      ..clear()
      ..addAll(pendingPublicIds);
    _selectionDraftInitialized = true;
  }

  bool get _hasDraftChanges {
    if (!_selectionDraftInitialized) {
      return false;
    }

    for (final publicId in _visiblePublicIds) {
      if (_draftPendingPublicIds.contains(publicId) !=
          _persistedPendingPublicIds.contains(publicId)) {
        return true;
      }
    }
    return false;
  }

  Future<void> _persistDraftSelection() async {
    if (!_hasDraftChanges || _visiblePublicIds.isEmpty) {
      return;
    }

    await _historyStore.replacePendingRemovalForPublicIds(
      visiblePublicIds: _visiblePublicIds,
      pendingPublicIds: _draftPendingPublicIds,
    );

    _persistedPendingPublicIds
      ..removeAll(_visiblePublicIds)
      ..addAll(_draftPendingPublicIds.where(_visiblePublicIds.contains));
  }

  void _setDraftPendingRemoval(
    LocalScheduleHistoryItem item,
    bool isPendingRemoval,
  ) {
    if (_isUpdating) return;

    final publicId = _normalizePublicId(item.publicId);
    if (publicId.isEmpty) return;

    setState(() {
      if (isPendingRemoval) {
        _draftPendingPublicIds.add(publicId);
      } else {
        _draftPendingPublicIds.remove(publicId);
      }
    });
  }

  void _markAllUnconfirmed(List<LocalScheduleHistoryItem> items) {
    if (_isUpdating) return;

    final publicIds = items
        .where((item) => item.isAdopted == false)
        .map((item) => _normalizePublicId(item.publicId))
        .where((publicId) => publicId.isNotEmpty)
        .toSet();
    if (publicIds.isEmpty) return;

    setState(() {
      _draftPendingPublicIds.addAll(publicIds);
    });
  }

  void _clearDraftSelection() {
    if (_isUpdating) return;

    setState(() {
      _draftPendingPublicIds.removeAll(_visiblePublicIds);
    });
  }

  Future<void> _confirmSelection() async {
    if (_isUpdating) return;

    if (!_hasDraftChanges) {
      setState(() {
        _selectionMode = false;
      });
      return;
    }

    setState(() {
      _isUpdating = true;
    });
    try {
      await _persistDraftSelection();
      if (mounted) {
        setState(() {
          _selectionMode = false;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _confirmSuppressPending() async {
    if (_isUpdating) return;

    final selectedPublicIds =
        _draftPendingPublicIds.where(_visiblePublicIds.contains).toSet();
    if (selectedPublicIds.isEmpty) return;

    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.scheduleHistorySelectedRemoveConfirmTitle),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.scheduleHistoryRemoveFromListAction),
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
      await _historyStore.replacePendingRemovalForPublicIds(
        visiblePublicIds: _visiblePublicIds,
        pendingPublicIds: _draftPendingPublicIds,
      );
      suppressedCount =
          await _historyStore.suppressPublicIds(selectedPublicIds);
      _draftPendingPublicIds.removeAll(selectedPublicIds);
      _persistedPendingPublicIds.removeAll(selectedPublicIds);
      _selectionDraftInitialized = false;
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
          _selectionMode = false;
          _itemsFuture = _loadItems(resetDraft: true);
        });
      }
    }

    if (!mounted || suppressedCount <= 0) return;
    AppSnackBar.show(
      context,
      message: l10n.scheduleHistorySelectedRemovedMessage,
      type: AppMessageType.success,
    );
  }

  bool _isDraftPendingRemoval(String publicId) {
    return _draftPendingPublicIds.contains(_normalizePublicId(publicId));
  }

  String _normalizePublicId(String publicId) {
    return publicId.trim().toUpperCase();
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
            items.where((item) => _isDraftPendingRemoval(item.publicId)).length;
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
                      onPressed:
                          _isUpdating ? null : () => _markAllUnconfirmed(items),
                      icon: const Icon(Icons.select_all),
                      label: Text(l10n.scheduleHistorySelectUnconfirmedAction),
                    ),
                  if (_selectionMode && pendingCount > 0)
                    TextButton.icon(
                      onPressed: _isUpdating ? null : _clearDraftSelection,
                      icon: const Icon(Icons.remove_done),
                      label: Text(l10n.scheduleHistoryClearSelectionAction),
                    ),
                  if (_selectionMode)
                    TextButton.icon(
                      onPressed: _isUpdating ? null : _confirmSelection,
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
                      label: Text(l10n.scheduleHistoryRemoveFromListAction),
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
                    final isPendingRemoval =
                        _isDraftPendingRemoval(item.publicId);

                    return _ScheduleHistoryListItem(
                      item: item,
                      selectionMode: _selectionMode,
                      isPendingRemoval: isPendingRemoval,
                      onTap: () {
                        if (_selectionMode) {
                          _setDraftPendingRemoval(item, !isPendingRemoval);
                          return;
                        }
                        widget.onOpenSchedule(item);
                      },
                      onSelectionChanged: (value) {
                        _setDraftPendingRemoval(item, value);
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
    required this.isPendingRemoval,
    required this.onTap,
    required this.onSelectionChanged,
  });

  final LocalScheduleHistoryItem item;
  final bool selectionMode;
  final bool isPendingRemoval;
  final VoidCallback onTap;
  final ValueChanged<bool> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      color: isPendingRemoval ? colorScheme.surfaceContainerHighest : null,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (selectionMode) ...[
                Checkbox(
                  value: isPendingRemoval,
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
                  opacity: isPendingRemoval ? 0.55 : 1,
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
