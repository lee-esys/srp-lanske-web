import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';
import 'package:srp_lanske/shared/presentation/app_navigation_sections.dart';
import 'package:srp_lanske/shared/utils/external_link.dart';

import '../../auth/presentation/account_routes.dart';
import '../../auth/presentation/admin_role_visibility.dart';
import '../../external_identity/presentation/admin_profile_link_review_routes.dart';

const _supportPagePath = '/support/index.html';

class MyPageNavigationDrawer extends StatelessWidget {
  const MyPageNavigationDrawer({super.key});

  static double widthFor(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    return math.min(screenWidth * 0.75, 300);
  }

  void _openPath(BuildContext context, String path) {
    Navigator.of(context).pop();
    openUrlInCurrentTab(path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return Drawer(
      width: widthFor(context),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.person_outline,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.myPageMenuLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('my-page-navigation-drawer-close'),
                    tooltip: l10n.closeButton,
                    onPressed: () => Navigator.of(context).pop(),
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
                  AppNavigationTile(
                    icon: Icons.manage_accounts_outlined,
                    label: l10n.accountMenuLabel,
                    onTap: () => _openPath(context, accountPagePath),
                  ),
                  const Divider(height: 1),
                  AppNavigationCommonSection(
                    onOpenTop: () => _openPath(context, '/'),
                    adminItem: AdminRoleVisibility(
                      child: AppNavigationTile(
                        icon: Icons.admin_panel_settings_outlined,
                        label: l10n.adminProfileLinkReviewMenuLabel,
                        onTap: () => _openPath(
                          context,
                          adminProfileLinkReviewPath,
                        ),
                      ),
                    ),
                    onOpenSupport: () => _openPath(context, _supportPagePath),
                  ),
                  const Divider(height: 1),
                  AppNavigationServiceSection(
                    onOpenDoubles: () => _openPath(context, '/'),
                    onOpenTeam: () => _openPath(context, '/team'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
