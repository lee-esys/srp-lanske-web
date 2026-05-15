import 'package:flutter/material.dart';

import '../features/doubles_scheduler/presentation/event_setup_page.dart';
import '../features/doubles_scheduler/presentation/restored_schedule_page.dart';
import 'theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    final publicId = Uri.base.queryParameters['sid']?.trim();

    final home = publicId == null || publicId.isEmpty
        ? const EventSetupPage()
        : RestoredSchedulePage(publicId: publicId);

    return MaterialApp(
      title: 'Lanske',
      debugShowCheckedModeBanner: true,
      theme: appTheme,
      home: home,
    );
  }
}
