import 'dart:async';

import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';
import 'package:srp_lanske/shared/repositories/app_repositories.dart';
import 'package:srp_lanske/shared/utils/external_link.dart';

import '../../../doubles_scheduler/application/schedule_share_url.dart';
import '../../../doubles_scheduler/domain/saved_event_models.dart';
import 'my_page_section_card.dart';

typedef MyPageOwnedEventsLoader = Future<List<SavedEventAggregate>> Function(
  String ownerUid,
);

typedef MyPageOwnedEventOpenCallback = void Function(
  SavedEventAggregate aggregate,
);

class MyPageMatchTableListSection extends StatefulWidget {
  const MyPageMatchTableListSection({
    super.key,
    required this.ownerUid,
    this.loadOwnedEvents,
    this.onOpenEvent,
    this.pageSize = 10,
  }) : assert(pageSize > 0);

  final String ownerUid;
  final MyPageOwnedEventsLoader? loadOwnedEvents;
  final MyPageOwnedEventOpenCallback? onOpenEvent;
  final int pageSize;

  @override
  State<MyPageMatchTableListSection> createState() =>
      _MyPageMatchTableListSectionState();
}

class _MyPageMatchTableListSectionState
    extends State<MyPageMatchTableListSection> {
  bool _loading = true;
  Object? _loadError;
  List<SavedEventAggregate> _items = const [];
  int _pageIndex = 0;
  int _loadSequence = 0;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant MyPageMatchTableListSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ownerUid != widget.ownerUid ||
        oldWidget.loadOwnedEvents != widget.loadOwnedEvents) {
      _pageIndex = 0;
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final sequence = ++_loadSequence;
    final requestedOwnerUid = widget.ownerUid;
    final loader = widget.loadOwnedEvents ?? appEventRepository.listByOwnerUid;

    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }

    try {
      final loaded = await loader(requestedOwnerUid);
      if (!mounted ||
          sequence != _loadSequence ||
          requestedOwnerUid != widget.ownerUid) {
        return;
      }

      final owned = loaded
          .where((aggregate) => aggregate.event.ownerUid == requestedOwnerUid)
          .toList(growable: false)
        ..sort(_compareEvents);

      final pageCount = _pageCountFor(owned.length);
      setState(() {
        _items = owned;
        _loading = false;
        _loadError = null;
        _pageIndex =
            pageCount == 0 ? 0 : _pageIndex.clamp(0, pageCount - 1).toInt();
      });
    } catch (error) {
      if (!mounted ||
          sequence != _loadSequence ||
          requestedOwnerUid != widget.ownerUid) {
        return;
      }

      setState(() {
        _loading = false;
        _loadError = error;
      });
    }
  }

  int _compareEvents(SavedEventAggregate left, SavedEventAggregate right) {
    final leftDate = left.event.eventDate ?? left.event.createdAt;
    final rightDate = right.event.eventDate ?? right.event.createdAt;
    final dateOrder = rightDate.compareTo(leftDate);
    if (dateOrder != 0) return dateOrder;

    return right.event.createdAt.compareTo(left.event.createdAt);
  }

  int _pageCountFor(int itemCount) {
    if (itemCount == 0) return 0;
    return (itemCount + widget.pageSize - 1) ~/ widget.pageSize;
  }

  List<SavedEventAggregate> get _visibleItems {
    if (_items.isEmpty) return const [];

    final start = _pageIndex * widget.pageSize;
    final end = (start + widget.pageSize).clamp(0, _items.length).toInt();
    return _items.sublist(start, end);
  }

  void _openEvent(SavedEventAggregate aggregate) {
    final callback = widget.onOpenEvent;
    if (callback != null) {
      callback(aggregate);
      return;
    }

    final baseUri = Uri.base.resolve('/');
    openUrlInCurrentTab(
      buildScheduleShareUrl(
        baseUri: baseUri,
        publicId: aggregate.event.publicId,
      ),
    );
  }

  void _showPreviousPage() {
    if (_pageIndex <= 0) return;
    setState(() {
      _pageIndex -= 1;
    });
  }

  void _showNextPage() {
    final pageCount = _pageCountFor(_items.length);
    if (_pageIndex + 1 >= pageCount) return;
    setState(() {
      _pageIndex += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return MyPageSectionCard(
      icon: Icons.calendar_month_outlined,
      title: l10n.myPageMatchTableListTitle,
      subtitle: l10n.myPageMatchTableListSubtitle,
      trailing: IconButton(
        tooltip: l10n.myPageMatchTableRefreshTooltip,
        onPressed: _loading ? null : _load,
        icon: const Icon(Icons.refresh),
      ),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (_loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
          Text(l10n.myPageMatchTableLoadingMessage),
        ],
      );
    }

    if (_loadError != null) {
      final colorScheme = Theme.of(context).colorScheme;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline,
                color: colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.myPageMatchTableLoadErrorTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.myPageLoadErrorBody),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.myPageRetryButton),
            ),
          ),
        ],
      );
    }

    if (_items.isEmpty) {
      return Text(l10n.myPageMatchTableEmptyMessage);
    }

    final pageCount = _pageCountFor(_items.length);
    final visibleItems = _visibleItems;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var index = 0; index < visibleItems.length; index++) ...[
          _MatchTableListItem(
            aggregate: visibleItems[index],
            onOpen: () => _openEvent(visibleItems[index]),
          ),
          if (index != visibleItems.length - 1) const SizedBox(height: 10),
        ],
        if (pageCount > 1) ...[
          const SizedBox(height: 16),
          _PaginationControls(
            currentPage: _pageIndex + 1,
            totalPages: pageCount,
            onPrevious: _pageIndex > 0 ? _showPreviousPage : null,
            onNext: _pageIndex + 1 < pageCount ? _showNextPage : null,
          ),
        ],
      ],
    );
  }
}

class _MatchTableListItem extends StatelessWidget {
  const _MatchTableListItem({
    required this.aggregate,
    required this.onOpen,
  });

  final SavedEventAggregate aggregate;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final event = aggregate.event;
    final colorScheme = Theme.of(context).colorScheme;
    final dateLocalizations = MaterialLocalizations.of(context);
    final createdDate =
        dateLocalizations.formatMediumDate(event.createdAt.toLocal());
    final eventDate = event.eventDate;
    final location = event.location?.trim();

    return Material(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(_statusLabel(l10n, event.status)),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(l10n.myPageMatchTableCreatedAtLabel(createdDate)),
              if (eventDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.myPageMatchTableEventDateLabel(
                    dateLocalizations.formatMediumDate(eventDate),
                  ),
                ),
              ],
              if (location != null && location.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(l10n.myPageMatchTableLocationLabel(location)),
              ],
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onOpen,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(l10n.myPageMatchTableOpenButton),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(
    AppLocalizations l10n,
    SavedEventStatus status,
  ) {
    return switch (status) {
      SavedEventStatus.draft => l10n.myPageMatchTableDraftStatus,
      SavedEventStatus.generated => l10n.myPageMatchTableGeneratedStatus,
      SavedEventStatus.adopted => l10n.myPageMatchTableAdoptedStatus,
    };
  }
}

class _PaginationControls extends StatelessWidget {
  const _PaginationControls({
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
  });

  final int currentPage;
  final int totalPages;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton(
          onPressed: onPrevious,
          child: Text(l10n.myPageMatchTablePreviousPage),
        ),
        const SizedBox(width: 12),
        Text(
          l10n.myPageMatchTablePageLabel(currentPage, totalPages),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: onNext,
          child: Text(l10n.myPageMatchTableNextPage),
        ),
      ],
    );
  }
}
