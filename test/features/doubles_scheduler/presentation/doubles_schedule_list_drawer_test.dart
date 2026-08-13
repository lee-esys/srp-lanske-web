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

  testWidgets('marks unconfirmed schedules and removes them from the local list',
      (tester) async {
    final unconfirmed = LocalScheduleHistoryItem(
      publicId: 'UNCONFIRMED',
      title: '未確定イベント',
      courtCount: 1,
      playerCount: 6,
      createdAt: DateTime(2026, 8, 14, 8),
      firstSavedAt: DateTime(2026, 8, 14, 8),
      lastOpenedAt: DateTime(2026, 8, 14, 8),
      generatedScheduleId: 'schedule-unconfirmed',
      isAdopted: false,
      completedMatchCount: 0,
      totalMatchCount: 10,
    );
    final confirmed = LocalScheduleHistoryItem(
      publicId: 'CONFIRMED',
      title: '確定済みイベント',
      courtCount: 1,
      playerCount: 6,
      createdAt: DateTime(2026, 8, 13, 8),
      firstSavedAt: DateTime(2026, 8, 13, 8),
      lastOpenedAt: DateTime(2026, 8, 13, 8),
      generatedScheduleId: 'schedule-confirmed',
      isAdopted: true,
      completedMatchCount: 3,
      totalMatchCount: 10,
    );
    SharedPreferences.setMockInitialValues({
      'lanske_recent_schedules': jsonEncode([
        unconfirmed.toJson(),
        confirmed.toJson(),
      ]),
    });

    await _pumpDrawer(tester, width: 340);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.select_all));
    await tester.pumpAndSettle();

    final prefsAfterMark = await SharedPreferences.getInstance();
    final rawAfterMark = jsonDecode(
      prefsAfterMark.getString('lanske_recent_schedules')!,
    ) as List<dynamic>;
    final markedById = {
      for (final value in rawAfterMark.cast<Map<String, dynamic>>())
        value['public_id'] as String: value['is_pending_removal'] as bool,
    };
    expect(markedById['UNCONFIRMED'], isTrue);
    expect(markedById['CONFIRMED'], isFalse);

    await tester.tap(find.text('決定'));
    await tester.pumpAndSettle();
    expect(find.byType(Checkbox), findsNothing);
    expect(find.text('未確定イベント'), findsOneWidget);

    await tester.tap(find.text('履歴を削除'));
    await tester.pumpAndSettle();
    expect(find.text('対戦表表示履歴を削除しますか？'), findsOneWidget);

    await tester.tap(
      find.widgetWithText(FilledButton, '履歴を削除').last,
    );
    await tester.pumpAndSettle();

    expect(find.text('未確定イベント'), findsNothing);
    expect(find.text('確定済みイベント'), findsOneWidget);

    final prefsAfterSuppress = await SharedPreferences.getInstance();
    expect(
      prefsAfterSuppress.getStringList('lanske_suppressed_schedule_ids'),
      contains('UNCONFIRMED'),
    );
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
