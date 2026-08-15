import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/l10n/l10n.dart';
import 'package:srp_lanske/shared/presentation/app_footer.dart';
import 'package:srp_lanske/shared/presentation/app_footer_host.dart';

void main() {
  testWidgets('shows the footer when the page does not scroll', (tester) async {
    final footerController = AppFooterController();
    addTearDown(footerController.dispose);

    await tester.pumpWidget(
      _testApp(
        footerController: footerController,
        child: const Center(child: Text('short page')),
      ),
    );

    expect(find.byType(AppFooter), findsOneWidget);
    expect(
      find.textContaining('Lanske · © 2026 S.R.P. · ver.'),
      findsOneWidget,
    );
  });

  testWidgets('shows the footer only near the end of a long page',
      (tester) async {
    final footerController = AppFooterController();
    final scrollController = ScrollController();
    addTearDown(footerController.dispose);
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      _testApp(
        footerController: footerController,
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

  testWidgets('ignores scroll notifications while a popup is active',
      (tester) async {
    final footerController = AppFooterController();
    final scrollController = ScrollController();
    addTearDown(footerController.dispose);
    addTearDown(scrollController.dispose);

    await tester.pumpWidget(
      _testApp(
        footerController: footerController,
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

    footerController.suspend();
    scrollController.jumpTo(scrollController.position.maxScrollExtent);
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppFooter), findsNothing);

    footerController.resume();
    final awayFromEnd = (scrollController.position.maxScrollExtent - 100)
        .clamp(0.0, double.infinity)
        .toDouble();
    scrollController.jumpTo(awayFromEnd);
    await tester.pump();
    scrollController.jumpTo(scrollController.position.maxScrollExtent);
    await tester.pump();
    await tester.pump();

    expect(find.byType(AppFooter), findsOneWidget);
  });
}

Widget _testApp({
  required AppFooterController footerController,
  required Widget child,
}) {
  return MaterialApp(
    locale: const Locale('ja'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: AppFooterHost(
        controller: footerController,
        child: child,
      ),
    ),
  );
}
