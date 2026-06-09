import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

import '../features/doubles_scheduler/presentation/event_setup_page.dart';
import '../features/doubles_scheduler/presentation/restored_schedule_page.dart';
import '../features/team_scheduler/presentation/team_setup_page.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final uri = Uri.base;
    final publicId = uri.queryParameters['sid']?.trim();

    final home = publicId == null || publicId.isEmpty
        ? _homeForPath(uri.path)
        : RestoredSchedulePage(publicId: publicId);

    return MaterialApp(
      title: 'Lanske',
      debugShowCheckedModeBanner: true,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      theme: appTheme,
      home: home,
    );
  }

  Widget _homeForPath(String path) {
    if (path == '/team') {
      return const TeamSetupPage();
    }

    return const EventSetupPage();
  }
}
