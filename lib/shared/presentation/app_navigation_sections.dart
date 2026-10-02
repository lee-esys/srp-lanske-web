import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

class AppNavigationCommonSection extends StatelessWidget {
  const AppNavigationCommonSection({
    super.key,
    this.onOpenTop,
    this.onOpenMyPage,
    this.adminItem,
    this.onOpenSupport,
  });

  final VoidCallback? onOpenTop;
  final VoidCallback? onOpenMyPage;
  final Widget? adminItem;
  final VoidCallback? onOpenSupport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onOpenTop != null)
          AppNavigationTile(
            icon: Icons.home_outlined,
            label: l10n.topPageMenu,
            onTap: onOpenTop!,
          ),
        if (onOpenMyPage != null)
          AppNavigationTile(
            icon: Icons.person_outline,
            label: l10n.myPageMenuLabel,
            onTap: onOpenMyPage!,
          ),
        if (adminItem != null) adminItem!,
        if (onOpenSupport != null)
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(l10n.supportMenuTitle),
            subtitle: Text(l10n.supportMenuSubtitle),
            onTap: onOpenSupport,
          ),
      ],
    );
  }
}

class AppNavigationServiceSection extends StatelessWidget {
  const AppNavigationServiceSection({
    super.key,
    this.onOpenDoubles,
    this.onOpenTeam,
  });

  final VoidCallback? onOpenDoubles;
  final VoidCallback? onOpenTeam;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppNavigationSectionHeader(
          label: l10n.teamNavigationServiceList,
        ),
        if (onOpenDoubles != null)
          AppNavigationTile(
            icon: Icons.sports_tennis_outlined,
            label: l10n.teamNavigationDoublesScheduler,
            onTap: onOpenDoubles!,
          ),
        if (onOpenTeam != null)
          AppNavigationTile(
            icon: Icons.groups_outlined,
            label: l10n.teamScheduleTitle,
            onTap: onOpenTeam!,
          ),
      ],
    );
  }
}

class AppNavigationSectionHeader extends StatelessWidget {
  const AppNavigationSectionHeader({
    super.key,
    required this.label,
  });

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class AppNavigationTile extends StatelessWidget {
  const AppNavigationTile({
    super.key,
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
