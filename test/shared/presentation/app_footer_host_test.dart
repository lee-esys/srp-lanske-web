import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/l10n/l10n.dart';
import 'package:srp_lanske/shared/presentation/app_footer.dart';
import 'package:srp_lanske/shared/presentation/app_footer_host.dart';

void main() {
  testWidgets('shows the footer when the page does not scroll', (tester) async {
    final resetController = AppFooterResetController();
    addTearDown(resetController.dispose);

    await tester.pumpWidget(
      _testApp(
        resetController: resetController,
        child: const Center(child: Text('short page')),
      ),
    );

    expect(find.byType(AppFooter), findsOneWidget);
  });

  testWidgets('shows the footer only near the end of a long page',
      (tester) async {
    final resetController = AppFooterResetController();
    final scrollController = ScrollController();
    addTearDown(resetController.dispose);
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      _testApp(
        resetController: resetController,
        child: ListView(
          controller: scrollController,
          children: const [
            SizedBox(height: 1600),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(AppFooter), findsNothing);

    scrollController.jumpTo(scrollController.position.maxScrollExtent);
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppFooter), findsOneWidget);

    final awayFromEnd = (scrollController.position.maxScrollExtent - 100)
        .clamp(0.0, double.infinity)
        .toDouble();
    scrollController.jumpTo(awayFromEnd);
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppFooter), findsNothing);
  });
}

Widget _testApp({
  required AppFooterResetController resetController,
  required Widget child,
}) {
  return MaterialApp(
    locale: const Locale('ja'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: AppFooterHost(
        resetListenable: resetController,
        child: child,
      ),
    ),
  );
}
