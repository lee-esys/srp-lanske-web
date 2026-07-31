import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/doubles_match_progress_service.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/models/doubles_match_editor_models.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/widgets/doubles_match_result_dialog.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';
import 'package:srp_lanske/l10n/l10n.dart';

void main() {
  testWidgets('selecting completed sets the finish time and saves scores', (
    tester,
  ) async {
    DoublesMatchProgressInput? savedInput;

    await tester.pumpWidget(
      _TestApp(
        progress: _placeholder(),
        onSaved: (input) {
          savedInput = input;
        },
      ),
    );

    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('終了'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pump();

    expect(find.widgetWithText(OutlinedButton, '1'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '0'), findsOneWidget);

    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(savedInput, isNotNull);
    expect(savedInput!.status, ScheduleMatchStatus.completed);
    expect(savedInput!.side1Score, 1);
    expect(savedInput!.side2Score, 0);
    expect(savedInput!.startedAt, isNull);
    expect(savedInput!.finishedAt, isNotNull);
  });

  testWidgets('selecting in progress sets the start time', (tester) async {
    DoublesMatchProgressInput? savedInput;

    await tester.pumpWidget(
      _TestApp(
        progress: _placeholder(),
        onSaved: (input) {
          savedInput = input;
        },
      ),
    );

    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('試合中'));
    await tester.pump();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(savedInput, isNotNull);
    expect(savedInput!.status, ScheduleMatchStatus.inProgress);
    expect(savedInput!.startedAt, isNotNull);
    expect(savedInput!.finishedAt, isNull);
  });

  testWidgets('restores saved score and note and can clear both scores', (
    tester,
  ) async {
    DoublesMatchProgressInput? savedInput;
    final now = DateTime(2026, 7, 31, 15, 41);

    await tester.pumpWidget(
      _TestApp(
        progress: ScheduleMatchProgress(
          schemaVersion: ScheduleMatchProgress.currentSchemaVersion,
          scheduleType: ScheduleProgressScheduleType.doubles,
          generatedScheduleId: 'generated-1',
          roundNo: 1,
          courtNo: 1,
          matchNo: null,
          status: ScheduleMatchStatus.completed,
          result: ScheduleMatchResultSummary.simpleScore(<int>[4, 2]),
          note: '接戦でした',
          startedAt: DateTime(2026, 7, 31, 15, 24),
          finishedAt: now,
          createdAt: now,
          updatedAt: now,
          revision: 1,
        ),
        onSaved: (input) {
          savedInput = input;
        },
      ),
    );

    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(OutlinedButton, '4'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '2'), findsOneWidget);
    expect(find.text('接戦でした'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, '4'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('スコアを未入力に戻す'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存'));
    await tester.pumpAndSettle();

    expect(savedInput, isNotNull);
    expect(savedInput!.side1Score, isNull);
    expect(savedInput!.side2Score, isNull);
  });
}

ScheduleMatchProgress _placeholder() {
  return ScheduleMatchProgress.scheduledPlaceholder(
    scope: ScheduleProgressScope(
      scheduleType: ScheduleProgressScheduleType.doubles,
      shareId: 'ABC123',
      generatedScheduleId: 'generated-1',
    ),
    roundNo: 1,
    courtNo: 1,
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.progress,
    required this.onSaved,
  });

  final ScheduleMatchProgress progress;
  final ValueChanged<DoublesMatchProgressInput> onSaved;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return Center(
              child: FilledButton(
                onPressed: () async {
                  final input = await showDialog<DoublesMatchProgressInput>(
                    context: context,
                    builder: (context) {
                      return DoublesMatchResultDialog(
                        match: const DoublesMatchSelection(
                          roundNo: 1,
                          courtNo: 1,
                          side1Players: <DoublesMatchParticipantViewModel>[
                            DoublesMatchParticipantViewModel(
                              slotNumber: 1,
                              playerId: 'player-1',
                              displayName: '参加者1',
                            ),
                            DoublesMatchParticipantViewModel(
                              slotNumber: 2,
                              playerId: 'player-2',
                              displayName: '参加者2',
                            ),
                          ],
                          side2Players: <DoublesMatchParticipantViewModel>[
                            DoublesMatchParticipantViewModel(
                              slotNumber: 3,
                              playerId: 'player-3',
                              displayName: '参加者3',
                            ),
                            DoublesMatchParticipantViewModel(
                              slotNumber: 4,
                              playerId: 'player-4',
                              displayName: '参加者4',
                            ),
                          ],
                        ),
                        initialProgress: progress,
                      );
                    },
                  );
                  if (input != null) {
                    onSaved(input);
                  }
                },
                child: const Text('開く'),
              ),
            );
          },
        ),
      ),
    );
  }
}
