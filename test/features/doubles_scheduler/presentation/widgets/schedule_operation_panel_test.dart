import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/widgets/schedule_operation_panel.dart';
import 'package:srp_lanske/l10n/l10n.dart';

void main() {
  testWidgets(
      'shows court, regenerate, and confirm actions before confirmation',
      (tester) async {
    var regenerateCount = 0;
    var adoptCount = 0;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ja'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ScheduleOperationPanel(
            courtDisplaySummary: '1 / 2',
            canChangeCourtDisplay: true,
            onChangeCourtDisplay: () {},
            showActionButtons: true,
            isLoading: false,
            isAdopting: false,
            generateButtonLabel: '再生成',
            canAdopt: true,
            onGenerate: () {
              regenerateCount += 1;
            },
            onAdopt: () {
              adoptCount += 1;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('コート表示: 1 / 2'), findsOneWidget);
    expect(find.text('変更'), findsOneWidget);
    expect(find.text('再生成'), findsOneWidget);
    expect(find.text('この対戦表で確定'), findsOneWidget);

    await tester.tap(find.text('再生成'));
    await tester.pump();

    expect(regenerateCount, 1);
    expect(adoptCount, 0);
  });
}
