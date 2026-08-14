import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/widgets/doubles_scroll_refresh_action.dart';

void main() {
  testWidgets('reveals and hides refresh action around scroll thresholds',
      (tester) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Scaffold(
            appBar: AppBar(
              actions: [
                DoublesScrollRefreshAction(
                  scrollController: scrollController,
                  tooltip: '最新の情報に更新',
                  isAvailable: true,
                  isRefreshing: false,
                  onPressed: () {},
                ),
              ],
            ),
            body: ListView(
              controller: scrollController,
              children: const [
                SizedBox(height: 1600),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.sync), findsNothing);

    scrollController.jumpTo(420);
    await tester.pump();
    expect(find.byIcon(Icons.sync), findsOneWidget);

    scrollController.jumpTo(350);
    await tester.pump();
    expect(find.byIcon(Icons.sync), findsOneWidget);

    scrollController.jumpTo(250);
    await tester.pump();
    expect(find.byIcon(Icons.sync), findsNothing);
  });

  testWidgets('keeps action hidden when refresh is unavailable',
      (tester) async {
    final scrollController = ScrollController();
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Scaffold(
            appBar: AppBar(
              actions: [
                DoublesScrollRefreshAction(
                  scrollController: scrollController,
                  tooltip: '最新の情報に更新',
                  isAvailable: false,
                  isRefreshing: false,
                  onPressed: null,
                ),
              ],
            ),
            body: ListView(
              controller: scrollController,
              children: const [
                SizedBox(height: 1600),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    scrollController.jumpTo(500);
    await tester.pump();

    expect(find.byIcon(Icons.sync), findsNothing);
  });
}
