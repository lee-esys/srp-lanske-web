import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../l10n/team_l10n.dart';
import '../data/local_team_schedule_history_item.dart';
import 'team_schedule_page.dart';
import 'widgets/team_schedule_history_list_view.dart';

class TeamScheduleListPage extends StatelessWidget {
  const TeamScheduleListPage({super.key});

  void _openSchedule(
    BuildContext context,
    LocalTeamScheduleHistoryItem item,
  ) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => TeamSchedulePage.restore(shareId: item.shareId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.teamScheduleListTitle),
      ),
      body: TeamScheduleHistoryListView(
        onOpenSchedule: (item) => _openSchedule(context, item),
      ),
    );
  }
}
