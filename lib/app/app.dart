import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

import '../features/doubles_scheduler/presentation/event_setup_page.dart';
import '../features/doubles_scheduler/presentation/restored_schedule_page.dart';
import '../features/team_scheduler/presentation/team_schedule_list_page.dart';
import '../features/team_scheduler/presentation/team_schedule_page.dart';
import '../features/team_scheduler/presentation/team_setup_page.dart';
import '../shared/presentation/app_footer_host.dart';
import 'theme/app_theme.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AppFooterController _footerController;
  late final AppFooterNavigatorObserver _footerNavigatorObserver;

  @override
  void initState() {
    super.initState();
    _footerController = AppFooterController();
    _footerNavigatorObserver = AppFooterNavigatorObserver(_footerController);
  }

  @override
  void dispose() {
    _footerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uri = Uri.base;
    final publicId = uri.queryParameters['sid']?.trim();
    final isTeamRoute = uri.path == '/team' || uri.path.startsWith('/team/');

    final home = publicId == null || publicId.isEmpty
        ? _homeForPath(uri.path)
        : RestoredSchedulePage(publicId: publicId);

    return MaterialApp(
      title: 'Lanske',
      debugShowCheckedModeBanner: true,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      theme: isTeamRoute ? appTheme : doublesAppTheme,
      navigatorObservers: [_footerNavigatorObserver],
      builder: (context, child) {
        return AppFooterHost(
          controller: _footerController,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: home,
    );
  }

  Widget _homeForPath(String path) {
    if (path == '/team') {
      return const TeamSetupPage();
    }

    if (path == '/team/schedules') {
      return const TeamScheduleListPage();
    }

    final teamScheduleMatch =
        RegExp(r'^/team/schedules/([^/]+)$').firstMatch(path);
    if (teamScheduleMatch != null) {
      return TeamSchedulePage.restore(
        shareId: teamScheduleMatch.group(1)!.trim().toUpperCase(),
      );
    }

    return const EventSetupPage();
  }
}
