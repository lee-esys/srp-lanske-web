import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srp_lanske/features/doubles_scheduler/data/local_schedule_history_item.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/doubles_schedule_list_drawer.dart';
import 'package:srp_lanske/l10n/l10n.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  testWidgets('uses 85 percent width on narrow screens', (tester) async {
    await _pumpDrawer(tester, width: 320);

    final drawer = tester.widget<Drawer>(find.byType(Drawer));
    expect(drawer.width, 272);
  });

  testWidgets('uses 85 percent width on wide screens without a max cap',
      (tester) async {
    await _pumpDrawer(tester, width: 800);

    final drawer = tester.widget<Drawer>(find.byType(Drawer));
    expect(drawer.width, 680);
  });

  testWidgets('schedule list panel delegates its back action', (tester) async {
    var backCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ja'),
        home: Scaffold(
          body: DoublesScheduleListPanel(
            onBack: () {
              backCount += 1;
            },
            onOpenSchedule: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();

    expect(backCount, 1);
  });

  testWidgets('opens the selected local schedule with compact list cards',
      (tester) async {
    final item = LocalScheduleHistoryItem(
      publicId: 'ABCDEFGH',
      title: 'テスト対戦表',
      courtCount: 2,
      playerCount: 8,
      createdAt: DateTime(2026, 8, 10, 10),
      firstSavedAt: DateTime(2026, 8, 10, 10),
      lastOpenedAt: DateTime(2026, 8, 10, 12),
    );
    SharedPreferences.setMockInitialValues({
      'lanske_recent_schedules': jsonEncode([item.toJson()]),
    });

    LocalScheduleHistoryItem? openedItem;
    await _pumpDrawer(
      tester,
      width: 400,
      onOpenSchedule: (item) {
        openedItem = item;
      },
    );

    expect(find.text('テスト対戦表'), findsOneWidget);
    expect(find.text('面数 2'), findsOneWidget);
    expect(find.text('人数 8'), findsOneWidget);
    expect(find.byIcon(Icons.sports_tennis_outlined), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    await tester.tap(find.text('テスト対戦表'));
    await tester.pump();

    expect(openedItem?.publicId, 'ABCDEFGH');
  });
}

Future<void> _pumpDrawer(
  WidgetTester tester, {
  required double width,
  ValueChanged<LocalScheduleHistoryItem>? onOpenSchedule,
}) async {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: Scaffold(
          key: scaffoldKey,
          endDrawer: DoublesScheduleListDrawer(
            onOpenSchedule: onOpenSchedule ?? (_) {},
          ),
        ),
      ),
    ),
  );

  scaffoldKey.currentState!.openEndDrawer();
  await tester.pumpAndSettle();
}
