import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';
import 'package:srp_lanske/shared/presentation/app_navigation_sections.dart';
import 'package:srp_lanske/shared/utils/external_link.dart';

import '../../my_page/presentation/my_page_routes.dart';

const _supportPagePath = '/support/index.html';

class AccountNavigationDrawer extends StatelessWidget {
  const AccountNavigationDrawer({super.key});

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
                    Icons.manage_accounts_outlined,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l10n.accountMenuLabel,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('account-navigation-drawer-close'),
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
                  AppNavigationCommonSection(
                    onOpenTop: () => _openPath(context, '/'),
                    onOpenMyPage: () => _openPath(context, myPagePath),
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
