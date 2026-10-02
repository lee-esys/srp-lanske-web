import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/auth/presentation/account_navigation_drawer.dart';
import 'package:srp_lanske/l10n/l10n.dart';

void main() {
  testWidgets('shows shared navigation without an account self-link',
      (tester) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ja'),
        home: MediaQuery(
          data: const MediaQueryData(size: Size(400, 800)),
          child: Scaffold(
            key: scaffoldKey,
            endDrawer: const AccountNavigationDrawer(),
          ),
        ),
      ),
    );

    scaffoldKey.currentState!.openEndDrawer();
    await tester.pumpAndSettle();

    final drawer = tester.widget<Drawer>(find.byType(Drawer));
    expect(drawer.width, 300);

    expect(find.text('アカウント管理'), findsOneWidget);
    expect(find.text('マイページ'), findsOneWidget);
    expect(find.text('TOPへ'), findsOneWidget);
    expect(find.text('サポート'), findsOneWidget);
    expect(find.text('サービス一覧'), findsOneWidget);
    expect(find.text('ダブルス乱数表'), findsOneWidget);
    expect(find.text('チーム対戦表'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('account-navigation-drawer-close')),
      findsOneWidget,
    );
  });

  testWidgets('closes from the account drawer header', (tester) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ja'),
        home: Scaffold(
          key: scaffoldKey,
          endDrawer: const AccountNavigationDrawer(),
        ),
      ),
    );

    scaffoldKey.currentState!.openEndDrawer();
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('account-navigation-drawer-close')),
    );
    await tester.pumpAndSettle();

    expect(scaffoldKey.currentState!.isEndDrawerOpen, isFalse);
  });
}
