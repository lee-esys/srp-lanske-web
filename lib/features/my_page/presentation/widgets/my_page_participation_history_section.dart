import 'dart:async';

import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

import '../../../participation_history/application/participation_history_service.dart';
import '../../../participation_history/domain/participation_history_entry.dart';
import 'my_page_section_card.dart';

typedef MyPageParticipationHistoryLoader = Future<ParticipationHistoryResult>
    Function(String lanskeUserId);

class MyPageParticipationHistorySection extends StatefulWidget {
  const MyPageParticipationHistorySection({
    super.key,
    required this.lanskeUserId,
    required this.loadHistory,
    required this.onOpenProfileLinkManagement,
  });

  final String lanskeUserId;
  final MyPageParticipationHistoryLoader loadHistory;
  final VoidCallback onOpenProfileLinkManagement;

  @override
  State<MyPageParticipationHistorySection> createState() =>
      _MyPageParticipationHistorySectionState();
}

class _MyPageParticipationHistorySectionState
    extends State<MyPageParticipationHistorySection> {
  final _infoTooltipKey = GlobalKey<TooltipState>();
  int _loadSequence = 0;
  bool _loading = true;
  Object? _error;
  ParticipationHistoryResult? _result;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void didUpdateWidget(covariant MyPageParticipationHistorySection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lanskeUserId != widget.lanskeUserId ||
        oldWidget.loadHistory != widget.loadHistory) {
      unawaited(_load());
    }
  }

  Future<void> _load() async {
    final sequence = ++_loadSequence;
    final uid = widget.lanskeUserId;
    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });
    try {
      final result = await widget.loadHistory(uid);
      if (!mounted || sequence != _loadSequence || uid != widget.lanskeUserId) {
        return;
      }
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || sequence != _loadSequence || uid != widget.lanskeUserId) {
        return;
      }
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return MyPageSectionCard(
      icon: Icons.event_note_outlined,
      title: l10n.myPageParticipationTitle,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            key: _infoTooltipKey,
            message: l10n.myPageParticipationInfo,
            triggerMode: TooltipTriggerMode.manual,
            child: IconButton(
              tooltip: l10n.myPageParticipationInfoTooltip,
              onPressed: () =>
                  _infoTooltipKey.currentState?.ensureTooltipVisible(),
              icon: const Icon(Icons.help_outline),
            ),
          ),
          IconButton(
            tooltip: l10n.myPageParticipationRefresh,
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      child: _content(context),
    );
  }

  Widget _content(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (_loading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const LinearProgressIndicator(),
          const SizedBox(height: 12),
          Text(l10n.myPageParticipationLoading),
        ],
      );
    }
    if (_error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.myPageParticipationError),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: Text(l10n.myPageRetryButton),
          ),
        ],
      );
    }

    final result = _result!;
    if (!result.linked) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.myPageParticipationUnlinked),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: widget.onOpenProfileLinkManagement,
            icon: const Icon(Icons.link),
            label: Text(l10n.myPageParticipationLinkAction),
          ),
        ],
      );
    }
    final confirmedEntries = result.entries
        .where((entry) => entry.isConfirmed)
        .toList(growable: false);
    if (confirmedEntries.isEmpty) {
      return Text(l10n.myPageParticipationEmpty);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in confirmedEntries) ...[
          _ParticipationRow(entry: entry),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ParticipationRow extends StatelessWidget {
  const _ParticipationRow({required this.entry});

  final ParticipationHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final color = Theme.of(context).colorScheme;
    final date = entry.eventDate;
    final dateText = date == null
        ? l10n.myPageParticipationUnknownDate
        : MaterialLocalizations.of(context).formatMediumDate(date.toLocal());
    final name = entry.selfSnapshot?.sourceDisplayName.trim();
    final levelName = entry.selfSnapshot?.levelName?.trim();
    final levelId = entry.selfSnapshot?.levelId;
    final level = [
      if (levelName != null && levelName.isNotEmpty) levelName,
      if (levelId != null) '（$levelId）',
    ].join();
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dateText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (entry.participantCount != null) ...[
                Text(l10n.myPageParticipationParticipantCount(
                    entry.participantCount!)),
                const SizedBox(width: 8),
              ],
              if (entry.statisticsEligible)
                Chip(
                  label: Text(l10n.myPageParticipationEligible),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if ((name != null && name.isNotEmpty) || level.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                if (name != null && name.isNotEmpty)
                  Text('${l10n.myPageParticipationDisplayNameLabel}$name'),
                if (level.isNotEmpty)
                  Text('${l10n.myPageParticipationLevelLabel}$level'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
