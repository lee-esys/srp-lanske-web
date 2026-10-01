import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';
import 'package:srp_lanske/shared/presentation/app_navigation_sections.dart';
import 'package:srp_lanske/shared/utils/external_link.dart';
import '../../auth/presentation/account_routes.dart';
import '../../auth/presentation/admin_role_visibility.dart';
import '../../external_identity/presentation/admin_profile_link_review_routes.dart';
import '../data/local_team_schedule_history_item.dart';
import 'team_schedule_page.dart';
import 'widgets/team_schedule_history_list_view.dart';

const _supportPagePath = '/support/index.html';

enum _TeamDrawerView {
  menu,
  schedules,
}

class TeamNavigationDrawer extends StatefulWidget {
  const TeamNavigationDrawer({
    super.key,
    required this.showHomeLink,
    this.onRefreshLatestInfo,
  });

  final bool showHomeLink;
  final VoidCallback? onRefreshLatestInfo;

  static double widthFor(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return screenWidth * 0.85;
  }

  @override
  State<TeamNavigationDrawer> createState() => _TeamNavigationDrawerState();
}

class _TeamNavigationDrawerState extends State<TeamNavigationDrawer> {
  _TeamDrawerView _view = _TeamDrawerView.menu;

  void _showSchedules() {
    setState(() {
      _view = _TeamDrawerView.schedules;
    });
  }

  void _showMenu() {
    setState(() {
      _view = _TeamDrawerView.menu;
    });
  }

  void _openPath(BuildContext context, String path) {
    Navigator.of(context).pop();
    openUrlInCurrentTab(path);
  }

  void _openSchedule(
    BuildContext context,
    LocalTeamScheduleHistoryItem item,
  ) {
    Navigator.of(context).pop();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TeamSchedulePage.restore(shareId: item.shareId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: TeamNavigationDrawer.widthFor(context),
      child: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: switch (_view) {
                _TeamDrawerView.menu => _buildMenu(context),
                _TeamDrawerView.schedules => _buildScheduleList(context),
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      color: colorScheme.primaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.groups_outlined,
            color: colorScheme.onPrimaryContainer,
            size: 32,
          ),
          const SizedBox(height: 12),
          Text(
            l10n.teamNavigationTitle,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.teamNavigationSubtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (widget.showHomeLink)
          AppNavigationTile(
            icon: Icons.home_outlined,
            label: l10n.teamNavigationHome,
            onTap: () => _openPath(context, '/team'),
          ),
        AppNavigationTile(
          icon: Icons.list_alt_outlined,
          label: l10n.teamNavigationScheduleList,
          onTap: _showSchedules,
        ),
        if (widget.onRefreshLatestInfo != null)
          AppNavigationTile(
            icon: Icons.refresh,
            label: l10n.refreshLatestButton,
            onTap: () {
              Navigator.of(context).pop();
              widget.onRefreshLatestInfo!();
            },
          ),
        const Divider(height: 1),
        AppNavigationCommonSection(
          onOpenTop: () => _openPath(context, '/'),
          onOpenAccount: () => _openPath(context, accountPagePath),
          adminItem: AdminRoleVisibility(
            child: AppNavigationTile(
              icon: Icons.admin_panel_settings_outlined,
              label: l10n.adminProfileLinkReviewMenuLabel,
              onTap: () => _openPath(context, adminProfileLinkReviewPath),
            ),
          ),
          onOpenSupport: () => _openPath(context, _supportPagePath),
        ),
        const Divider(height: 1),
        AppNavigationServiceSection(
          onOpenDoubles: () => _openPath(context, '/'),
        ),
      ],
    );
  }

  Widget _buildScheduleList(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: const Icon(Icons.arrow_back),
          title: Text(
            l10n.teamScheduleListTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          onTap: _showMenu,
        ),
        const Divider(height: 1),
        Expanded(
          child: TeamScheduleHistoryListView(
            padding: const EdgeInsets.all(12),
            onOpenSchedule: (item) => _openSchedule(context, item),
          ),
        ),
      ],
    );
  }
}
