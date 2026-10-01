import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/widgets/event_setup_url_section.dart';
import 'package:srp_lanske/l10n/l10n.dart';

void main() {
  testWidgets('shows persistent import warnings and source link',
      (tester) async {
    final controller = TextEditingController(
      text: 'https://www.tennisbear.net/event/1645753/info',
    );
    addTearDown(controller.dispose);
    var openCount = 0;

    await tester.pumpWidget(
      _testApp(
        EventSetupUrlSection(
          controller: controller,
          isLoadingEvent: false,
          hasUrlInput: true,
          showUrlError: false,
          canClearEventUrl: true,
          canPasteEventUrl: false,
          canImportEventUrl: false,
          onChanged: (_) {},
          onClear: () {},
          onPaste: () {},
          onImport: () {},
          importedSourceUrl: 'https://www.tennisbear.net/event/1645753/info',
          showEventTitleImportWarning: true,
          showParticipantDisplayNamesImportWarning: true,
          onOpenSourceEvent: () {
            openCount += 1;
          },
        ),
      ),
    );

    expect(find.text('イベントタイトルが取り込めませんでした'), findsOneWidget);
    expect(find.text('参加者表示名が取り込めませんでした'), findsOneWidget);
    expect(find.text('テニスベアのイベントを表示する'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('open-tennisbear-source-event-button')),
    );
    await tester.pump();

    expect(openCount, 1);
  });

  testWidgets('hides import feedback before a TennisBear import',
      (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _testApp(
        EventSetupUrlSection(
          controller: controller,
          isLoadingEvent: false,
          hasUrlInput: false,
          showUrlError: false,
          canClearEventUrl: false,
          canPasteEventUrl: true,
          canImportEventUrl: false,
          onChanged: (_) {},
          onClear: () {},
          onPaste: () {},
          onImport: () {},
        ),
      ),
    );

    expect(find.text('イベントタイトルが取り込めませんでした'), findsNothing);
    expect(find.text('参加者表示名が取り込めませんでした'), findsNothing);
    expect(find.text('テニスベアのイベントを表示する'), findsNothing);
  });
}

Widget _testApp(Widget child) {
  return MaterialApp(
    locale: const Locale('ja'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}
