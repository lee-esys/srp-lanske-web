import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../l10n/team_l10n.dart';
import '../../data/local_team_schedule_history_item.dart';
import '../../data/local_team_schedule_history_store.dart';

class TeamScheduleHistoryListView extends StatefulWidget {
  const TeamScheduleHistoryListView({
    super.key,
    required this.onOpenSchedule,
    this.padding = const EdgeInsets.all(16),
  });

  final ValueChanged<LocalTeamScheduleHistoryItem> onOpenSchedule;
  final EdgeInsetsGeometry padding;

  @override
  State<TeamScheduleHistoryListView> createState() =>
      _TeamScheduleHistoryListViewState();
}

class _TeamScheduleHistoryListViewState