import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/team_l10n.dart';
import '../data/local_team_schedule_history_item.dart';
import '../data/local_team_schedule_history_store.dart';
import 'team_schedule_page.dart';

class TeamScheduleListPage extends StatefulWidget {
  const TeamScheduleListPage({super.key});

  @override
  State<TeamScheduleListPage> createState() => _TeamScheduleListPageState();
}

class _TeamScheduleListPageState extends State<TeamScheduleListPage> {
  final LocalTeamScheduleHistoryStore _historyStore =
      LocalTeamScheduleHistoryStore();

  late Future<List<LocalTeamScheduleHistoryItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _historyStore.loadItems();
  }

  Future<void> _reload() async {
    setState(() {
      _itemsFuture = _historyStore.loadItems();
    });
  }

  void _openSchedule(LocalTeamScheduleHistoryItem item) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => TeamSchedulePage.restore(shareId: item.shareId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.teamScheduleListTitle),
        actions: [
          IconButton(
            tooltip: l10n.refreshLatestInfo,
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<LocalTeamScheduleHistoryItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return _TeamScheduleListMessage(
              icon: Icons.error_outline,
              title: l10n.teamScheduleListLoadErrorTitle,
              message: l10n.teamScheduleListLoadErrorMessage,
              actionLabel: l10n.refreshLatestInfo,
              onActionPressed: _reload,
            );
          }

          final items = snapshot.data ?? const [];

          if (items.isEmpty) {
            return _TeamScheduleListMessage(
              icon: Icons.list_alt_outlined,
              title: l10n.teamScheduleListEmptyTitle,
              message: l10n.teamScheduleListEmptyMessage,
            );
          }

          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => _openSchedule(item),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                colorScheme.primary.withValues(alpha: 0.12),
                            foregroundColor: colorScheme.primary,
                            child: const Icon(Icons.groups_outlined),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TeamScheduleListItemBody(item: item),
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
              },
            ),
          );
        },
      ),
    );
  }
}

class _TeamScheduleListItemBody extends StatelessWidget {
  const _TeamScheduleListItemBody({required this.item});

  final LocalTeamScheduleHistoryItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final title = item.eventTitle.trim().isEmpty
        ? l10n.teamScheduleUntitledEvent
        : item.eventTitle.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          l10n.teamScheduleListShareId(item.shareId),
          style: textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _TeamScheduleListChip(
              icon: Icons.groups_2_outlined,
              label: l10n.teamScheduleListTeamCount(item.teamCount),
            ),
            _TeamScheduleListChip(
              icon: Icons.person_outline,
              label: l10n.teamScheduleListMemberCount(item.memberCount),
            ),
            _TeamScheduleListChip(
              icon: Icons.schedule_outlined,
              label: l10n.teamScheduleListUpdatedAt(
                _formatUpdatedAt(item.updatedAt),
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _formatUpdatedAt(DateTime updatedAt) {
    final local = updatedAt.toLocal();
    final year = local.year.toString().padLeft(4, '0');
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');

    return '$year/$month/$day $hour:$minute';
  }
}

class _TeamScheduleListChip extends StatelessWidget {
  const _TeamScheduleListChip({
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

class _TeamScheduleListMessage extends StatelessWidget {
  const _TeamScheduleListMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onActionPressed,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                title,
                style: textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              if (actionLabel != null && onActionPressed != null) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onActionPressed,
                  icon: const Icon(Icons.refresh),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
