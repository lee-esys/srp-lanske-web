import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/widgets/schedule_event_summary_card.dart';
import 'package:srp_lanske/l10n/l10n.dart';

void main() {
  testWidgets('disables refresh while loading and shows progress text',
      (tester) async {
    var refreshCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ScheduleEventSummaryCard(
            onRefresh: () async {
              refreshCount += 1;
            },
            isRefreshing: true,
            progressText: '- / -',
          ),
        ),
      ),
    );

    expect(find.text('- / -'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    expect(refreshCount, 0);
  });

  testWidgets('runs refresh action when enabled', (tester) async {
    var refreshCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ScheduleEventSummaryCard(
            onRefresh: () async {
              refreshCount += 1;
            },
            progressText: '3 / 15',
          ),
        ),
      ),
    );

    expect(find.text('3 / 15'), findsOneWidget);
    expect(find.byIcon(Icons.sync), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(refreshCount, 1);
  });
}
