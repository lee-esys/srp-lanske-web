import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srp_lanske/features/doubles_scheduler/data/local_schedule_history_item.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/doubles_navigation_drawer.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/widgets/doubles_navigation_menu_button.dart';
import 'package:srp_lanske/l10n/l10n.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'lanske_doubles_navigation_menu_hint_v1': true,
    });
  });

  testWidgets('switches between compact operation menu and wide schedule list',
      (tester) async {
    await _pumpDrawer(tester, width: 400);

    var drawer = tester.widget<Drawer>(find.byType(Drawer));
    expect(drawer.width, 300);
    expect(find.byIcon(Icons.sports_tennis_outlined), findsOneWidget);
    expect(find.text('ダブルス乱数表'), findsOneWidget);
    expect(find.byKey(const ValueKey('doubles-navigation-drawer-close')),
        findsOneWidget);
    expect(find.text('TOPへ'), findsOneWidget);
    expect(find.text('対戦表一覧'), findsOneWidget);
    expect(find.text('操作ヒントを表示'), findsOneWidget);
    expect(find.text('サポート'), findsOneWidget);

    await tester.tap(find.text('対戦表一覧'));
    await tester.pumpAndSettle();

    drawer = tester.widget<Drawer>(find.byType(Drawer));
    expect(drawer.width, 340);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.text('対戦表一覧'), findsOneWidget);
    expect(find.text('TOPへ'), findsNothing);
    expect(find.byKey(const ValueKey('doubles-navigation-drawer-close')),
        findsNothing);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    drawer = tester.widget<Drawer>(find.byType(Drawer));
    expect(drawer.width, 300);
    expect(find.text('TOPへ'), findsOneWidget);
  });

  testWidgets('closes the operation menu from the header close button',
      (tester) async {
    await _pumpDrawer(tester, width: 400);

    expect(find.byType(Drawer), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('doubles-navigation-drawer-close')),
    );
    await tester.pumpAndSettle();

    final scaffold = tester.state<ScaffoldState>(find.byType(Scaffold));
    expect(scaffold.isEndDrawerOpen, isFalse);
  });

  testWidgets('reloads local history when entering the schedule list',
      (tester) async {
    await _pumpDrawer(tester, width: 400);
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'lanske_recent_schedules',
      jsonEncode([
        _historyItem(title: 'あとから追加した対戦表').toJson(),
      ]),
    );

    expect(find.text('あとから追加した対戦表'), findsNothing);

    await tester.tap(find.text('対戦表一覧'));
    await tester.pumpAndSettle();

    expect(find.text('あとから追加した対戦表'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    await prefs.setString(
      'lanske_recent_schedules',
      jsonEncode([
        _historyItem(title: '再表示時に更新した対戦表').toJson(),
      ]),
    );

    await tester.tap(find.text('対戦表一覧'));
    await tester.pumpAndSettle();

    expect(find.text('あとから追加した対戦表'), findsNothing);
    expect(find.text('再表示時に更新した対戦表'), findsOneWidget);
  });

  testWidgets(
      'shows schedule-specific actions only when callbacks are supplied',
      (tester) async {
    var refreshCount = 0;
    var editCount = 0;
    var courtCount = 0;
    var regenerateCount = 0;

    await _pumpDrawer(
      tester,
      width: 400,
      onRefreshLatestInfo: () {
        refreshCount += 1;
      },
      onEditEventInfo: () {
        editCount += 1;
      },
      onChangeCourtDisplay: () {
        courtCount += 1;
      },
      onRegenerate: () {
        regenerateCount += 1;
      },
    );

    expect(find.text('最新の情報に更新'), findsOneWidget);
    expect(find.text('イベント情報を編集'), findsOneWidget);
    expect(find.text('コート表示: 変更'), findsOneWidget);
    expect(find.text('再生成'), findsOneWidget);

    await tester.tap(find.text('最新の情報に更新'));
    await tester.pumpAndSettle();
    expect(refreshCount, 1);
    expect(editCount, 0);
    expect(courtCount, 0);
    expect(regenerateCount, 0);
  });
}

LocalScheduleHistoryItem _historyItem({required String title}) {
  final createdAt = DateTime(2026, 8, 15, 7, 30);

  return LocalScheduleHistoryItem(
    publicId: 'ABCDEFGH',
    title: title,
    courtCount: 1,
    playerCount: 6,
    createdAt: createdAt,
    firstSavedAt: createdAt,
    lastOpenedAt: createdAt,
  );
}

Future<void> _pumpDrawer(
  WidgetTester tester, {
  required double width,
  VoidCallback? onRefreshLatestInfo,
  VoidCallback? onEditEventInfo,
  VoidCallback? onChangeCourtDisplay,
  VoidCallback? onRegenerate,
}) async {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final hintController = DoublesNavigationMenuHintController();

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: Scaffold(
          key: scaffoldKey,
          endDrawer: DoublesNavigationDrawer(
            hintController: hintController,
            onOpenSchedule: (_) {},
            onRefreshLatestInfo: onRefreshLatestInfo,
            onEditEventInfo: onEditEventInfo,
            onChangeCourtDisplay: onChangeCourtDisplay,
            onRegenerate: onRegenerate,
          ),
        ),
      ),
    ),
  );

  scaffoldKey.currentState!.openEndDrawer();
  await tester.pumpAndSettle();
}
