import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';
import 'package:srp_lanske/shared/utils/external_link.dart';

import '../../auth/presentation/account_routes.dart';
import '../data/local_schedule_history_item.dart';
import 'doubles_schedule_list_drawer.dart';
import 'widgets/doubles_navigation_menu_button.dart';
import 'widgets/schedule_history_list_view.dart';

const _supportPagePath = '/support/index.html';

enum _DoublesDrawerView {
  menu,
  schedules,
}

class DoublesNavigationDrawer extends StatefulWidget {
  const DoublesNavigationDrawer({
    super.key,
    required this.onOpenSchedule,
    required this.hintController,
    this.onRefreshLatestInfo,
    this.onEditEventInfo,
    this.onChangeCourtDisplay,
    this.onRegenerate,
  });

  final ValueChanged<LocalScheduleHistoryItem> onOpenSchedule;
  final DoublesNavigationMenuHintController hintController;
  final VoidCallback? onRefreshLatestInfo;
  final VoidCallback? onEditEventInfo;
  final VoidCallback? onChangeCourtDisplay;
  final VoidCallback? onRegenerate;

  static double menuWidthFor(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return math.min(screenWidth * 0.75, 300);
  }

  static double scheduleListWidthFor(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return screenWidth * 0.85;
  }

  @override
  State<DoublesNavigationDrawer> createState() =>
      _DoublesNavigationDrawerState();
}

class _DoublesNavigationDrawerState extends State<DoublesNavigationDrawer> {
  final _historyController = ScheduleHistoryListController();
  _DoublesDrawerView _view = _DoublesDrawerView.menu;

  @override
  void dispose() {
    unawaited(_historyController.flushSelection());
    super.dispose();
  }

  void _showSchedules() {
    setState(() {
      _view = _DoublesDrawerView.schedules;
    });
  }

  Future<void> _showMenu() async {
    await _historyController.flushSelection();
    if (!mounted) return;

    setState(() {
      _view = _DoublesDrawerView.menu;
    });
  }

  Future<void> _closeDrawer({bool resetView = true}) async {
    await _historyController.flushSelection();
    if (!mounted) return;

    if (resetView) {
      setState(() {
        _view = _DoublesDrawerView.menu;
      });
    }
    Navigator.of(context).pop();
  }

  Future<void> _runAction(VoidCallback action) async {
    await _closeDrawer();
    if (!mounted) return;
    action();
  }

  Future<void> _openSchedule(LocalScheduleHistoryItem item) async {
    await _historyController.flushSelection();
    if (!mounted) return;

    Navigator.of(context).pop();
    widget.onOpenSchedule(item);
  }

  void _openTop() {
    unawaited(_runAction(() => openUrlInCurrentTab('/')));
  }

  void _openAccount() {
    unawaited(_runAction(() => openUrlInCurrentTab(accountPagePath)));
  }

  void _openTeam() {
    unawaited(_runAction(() => openUrlInCurrentTab('/team')));
  }

  void _openSupport() {
    unawaited(_runAction(() => openUrlInCurrentTab(_supportPagePath)));
  }

  void _showOperationHint() {
    unawaited(
      _runAction(() {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.hintController.showHint();
        });
      }),
    );
  }

  void _handlePop(bool didPop) {
    if (!didPop) return;

    unawaited(_historyController.flushSelection());
    if (mounted && _view != _DoublesDrawerView.menu) {
      setState(() {
        _view = _DoublesDrawerView.menu;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = switch (_view) {
      _DoublesDrawerView.menu => DoublesNavigationDrawer.menuWidthFor(context),
      _DoublesDrawerView.schedules =>
        DoublesNavigationDrawer.scheduleListWidthFor(context),
    };

    return PopScope(
      onPopInvokedWithResult: (didPop, _) => _handlePop(didPop),
      child: Drawer(
        width: width,
        child: SafeArea(
          child: switch (_view) {
            _DoublesDrawerView.menu => _buildMenu(context),
            _DoublesDrawerView.schedules => DoublesScheduleListPanel(
                historyController: _historyController,
                onBack: () {
                  unawaited(_showMenu());
                },
                onOpenSchedule: _openSchedule,
              ),
          },
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
          child: Row(
            children: [
              Icon(
                Icons.sports_tennis_outlined,
                color: colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.teamNavigationDoublesScheduler,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              IconButton(
                key: const ValueKey('doubles-navigation-drawer-close'),
                tooltip: l10n.closeButton,
                onPressed: () {
                  unawaited(_closeDrawer());
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _DoublesNavigationTile(
                icon: Icons.home_outlined,
                label: l10n.topPageMenu,
                onTap: _openTop,
              ),
              _DoublesNavigationTile(
                icon: Icons.list_alt_outlined,
                label: l10n.matchTableList,
                onTap: _showSchedules,
              ),
              if (widget.onRefreshLatestInfo != null)
                _DoublesNavigationTile(
                  icon: Icons.refresh,
                  label: l10n.refreshLatestButton,
                  onTap: () {
                    unawaited(_runAction(widget.onRefreshLatestInfo!));
                  },
                ),
              if (widget.onEditEventInfo != null)
                _DoublesNavigationTile(
                  icon: Icons.edit_outlined,
                  label: l10n.editDoublesEventInfoButton,
                  onTap: () {
                    unawaited(_runAction(widget.onEditEventInfo!));
                  },
                ),
              if (widget.onChangeCourtDisplay != null)
                _DoublesNavigationTile(
                  icon: Icons.tune,
                  label:
                      '${l10n.courtDisplaySectionTitle}: ${l10n.changeCourtDisplayButton}',
                  onTap: () {
                    unawaited(_runAction(widget.onChangeCourtDisplay!));
                  },
                ),
              if (widget.onRegenerate != null)
                _DoublesNavigationTile(
                  icon: Icons.restart_alt,
                  label: l10n.regenerateButton,
                  onTap: () {
                    unawaited(_runAction(widget.onRegenerate!));
                  },
                ),
              _DoublesNavigationTile(
                icon: Icons.lightbulb_outline,
                label: l10n.doublesNavigationShowHint,
                onTap: _showOperationHint,
              ),
              const Divider(height: 1),
              _DoublesNavigationTile(
                icon: Icons.person_outline,
                label: 'アカウント',
                onTap: _openAccount,
              ),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: Text(l10n.supportMenuTitle),
                subtitle: Text(l10n.supportMenuSubtitle),
                onTap: _openSupport,
              ),
              const Divider(height: 1),
              _DoublesNavigationSectionHeader(
                label: l10n.teamNavigationServiceList,
              ),
              _DoublesNavigationTile(
                icon: Icons.groups_outlined,
                label: l10n.teamScheduleTitle,
                onTap: _openTeam,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DoublesNavigationSectionHeader extends StatelessWidget {
  const _DoublesNavigationSectionHeader({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _DoublesNavigationTile extends StatelessWidget {
  const _DoublesNavigationTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      onTap: onTap,
    );
  }
}
