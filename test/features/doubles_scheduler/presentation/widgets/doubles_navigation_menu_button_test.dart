import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/widgets/doubles_navigation_menu_button.dart';
import 'package:srp_lanske/l10n/l10n.dart';

void main() {
  testWidgets('stores the first automatic menu hint as shown', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final hintController = DoublesNavigationMenuHintController();

    await tester.pumpWidget(
      _testApp(
        DoublesNavigationMenuButton(
          hintController: hintController,
          onPressed: () {},
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();

    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getBool('lanske_doubles_navigation_menu_hint_v1'),
      isTrue,
    );
    expect(find.text('操作メニューを開く'), findsOneWidget);
  });

  testWidgets('controller can show the hint again after the first display',
      (tester) async {
    SharedPreferences.setMockInitialValues({
      'lanske_doubles_navigation_menu_hint_v1': true,
    });
    final hintController = DoublesNavigationMenuHintController();

    await tester.pumpWidget(
      _testApp(
        DoublesNavigationMenuButton(
          hintController: hintController,
          onPressed: () {},
        ),
      ),
    );

    hintController.showHint();
    await tester.pump();

    expect(find.text('操作メニューを開く'), findsOneWidget);
  });
}

Widget _testApp(Widget child) {
  return MaterialApp(
    locale: const Locale('ja'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      appBar: AppBar(actions: [child]),
    ),
  );
}
