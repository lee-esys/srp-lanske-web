import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/doubles_progress_ui_store.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/widgets/schedule_rounds_view.dart';
import 'package:srp_lanske/l10n/l10n.dart';

void main() {
  tearDown(DoublesProgressUiStore.clearOverride);

  testWidgets('shows floating navigation near match table and scrolls to top',
      (tester) async {
    final scrollController = ScrollController();
    var navigationCount = 0;
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      _testApp(
        scrollController: scrollController,
      ),
    );
    await tester.pumpAndSettle();

    DoublesProgressUiStore.setNavigation(
      DoublesProgressNavigationUiState(
        kind: DoublesProgressNavigationUiKind.nextMatch,
        roundNo: 3,
        courtLabel: '1',
        side1PlayerNames: const ['1', '2'],
        side2PlayerNames: const ['3', '4'],
        inProgressMatchCount: 0,
        targetKey: '3_1',
        onNavigate: () async {
          navigationCount += 1;
        },
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('doubles-schedule-floating-navigation')),
      findsNothing,
    );

    scrollController.jumpTo(500);
    await tester.pump();
    await tester.pump();

    expect(
      find.byKey(const ValueKey('doubles-schedule-floating-navigation')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(
        const ValueKey('doubles-schedule-floating-primary-button'),
      ),
    );
    await tester.pump();
    expect(navigationCount, 1);

    await tester.tap(
      find.byKey(const ValueKey('doubles-schedule-floating-top-button')),
    );
    await tester.pumpAndSettle();

    expect(scrollController.offset, 0);
    expect(
      find.byKey(const ValueKey('doubles-schedule-floating-navigation')),
      findsNothing,
    );
  });

  testWidgets('completed floating navigation scrolls to page bottom',
      (tester) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      _testApp(
        scrollController: scrollController,
      ),
    );
    await tester.pumpAndSettle();

    DoublesProgressUiStore.setNavigation(
      const DoublesProgressNavigationUiState.completed(),
    );
    scrollController.jumpTo(500);
    await tester.pump();
    await tester.pump();

    expect(DoublesProgressUiStore.completedNavigation.value, isNotNull);

    await tester.tap(
      find.byKey(
        const ValueKey('doubles-schedule-floating-primary-button'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      scrollController.offset,
      closeTo(scrollController.position.maxScrollExtent, 0.1),
    );
  });

  testWidgets('completed navigation exposes page bottom action',
      (tester) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      _testApp(
        scrollController: scrollController,
      ),
    );
    await tester.pumpAndSettle();

    DoublesProgressUiStore.setNavigation(
      const DoublesProgressNavigationUiState.completed(),
    );
    scrollController.jumpTo(500);
    await tester.pump();
    await tester.pump();

    final onNavigate = DoublesProgressUiStore.completedNavigation.value;
    expect(onNavigate, isNotNull);

    final navigationFuture = onNavigate?.call();
    await tester.pumpAndSettle();
    await navigationFuture;

    expect(
      scrollController.offset,
      closeTo(scrollController.position.maxScrollExtent, 0.1),
    );
  });
}

Widget _testApp({required ScrollController scrollController}) {
  return MaterialApp(
    locale: const Locale('ja'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ListView(
        controller: scrollController,
        children: const [
          SizedBox(height: 600),
          ScheduleRoundsView(
            scheduleResponse: null,
            playerNameById: {},
            courtCount: 1,
            courtLabelByNumber: {},
          ),
          SizedBox(height: 900),
        ],
      ),
    ),
  );
}
