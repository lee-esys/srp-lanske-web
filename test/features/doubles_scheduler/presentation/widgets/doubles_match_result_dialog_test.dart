import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/doubles_match_progress_service.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/doubles_match_save_registry.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/models/doubles_match_editor_models.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/widgets/doubles_match_result_dialog.dart';
import 'package:srp_lanske/features/schedule_progress/application/schedule_progress_repository.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';
import 'package:srp_lanske/l10n/l10n.dart';

void main() {
  testWidgets('save keeps the dialog open and advances the baseline revision', (
    tester,
  ) async {
    final usedRevisions = <int>[];
    final savedInputs = <DoublesMatchProgressInput>[];

    await tester.pumpWidget(
      _TestApp(
        progress: _placeholder(),
        onSave: ({required current, required input}) async {
          usedRevisions.add(current.revision);
          savedInputs.add(input);
          final saved = _savedProgress(current: current, input: input);
          return DoublesMatchProgressSaveResult(
            match: saved,
            summary: _summary(saved),
          );
        },
      ),
    );

    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();

    expect(find.text('R 1 / C 1 / M 1'), findsOneWidget);
    expect(_saveButton(tester).onPressed, isNull);

    await tester.tap(find.text('終了'));
    await tester.pump();
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pump();

    expect(find.text('未保存の変更があります'), findsOneWidget);
    expect(_saveButton(tester).onPressed, isNotNull);

    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(usedRevisions, <int>[0]);
    expect(savedInputs.single.status, ScheduleMatchStatus.completed);
    expect(savedInputs.single.side1Score, 1);
    expect(savedInputs.single.side2Score, 0);
    expect(savedInputs.single.startedAt, isNotNull);
    expect(savedInputs.single.finishedAt, savedInputs.single.startedAt);
    expect(find.text('試合状態・最終スコア'), findsOneWidget);
    expect(find.text('試合情報を保存しました'), findsOneWidget);
    expect(_saveButton(tester).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'after first save');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(usedRevisions, <int>[0, 1]);
    expect(savedInputs.last.note, 'after first save');
    expect(find.text('試合状態・最終スコア'), findsOneWidget);
  });

  testWidgets('revision conflict keeps the draft and supports discard close', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        progress: _placeholder(),
        onSave: ({required current, required input}) async {
          throw ScheduleProgressConflictException(
            matchKey: current.key,
            expectedRevision: current.revision,
            actualRevision: current.revision + 1,
          );
        },
      ),
    );

    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('試合中'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'keep this draft');
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(
      find.text('別の端末で試合情報が更新されています。最新情報を取得してください。'),
      findsOneWidget,
    );
    expect(find.text('keep this draft'), findsOneWidget);
    expect(find.text('試合状態・最終スコア'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '閉じる'));
    await tester.pumpAndSettle();
    expect(find.text('未保存の変更があります'), findsWidgets);

    await tester.tap(find.widgetWithText(TextButton, 'キャンセル'));
    await tester.pumpAndSettle();
    expect(find.text('試合状態・最終スコア'), findsOneWidget);
    expect(find.text('keep this draft'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, '閉じる'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存せず閉じる'));
    await tester.pumpAndSettle();

    expect(find.text('試合状態・最終スコア'), findsNothing);
  });

  testWidgets('saved scores can be cleared without horizontal overflow', (
    tester,
  ) async {
    _setLogicalViewSize(tester, const Size(320, 760));

    final progress = _persistedProgress();
    DoublesMatchProgressInput? savedInput;

    await tester.pumpWidget(
      _TestApp(
        progress: progress,
        onSave: ({required current, required input}) async {
          savedInput = input;
          final saved = _savedProgress(current: current, input: input);
          return DoublesMatchProgressSaveResult(
            match: saved,
            summary: _summary(saved),
          );
        },
      ),
    );

    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(const Key('doubles-match-narrow-score-layout')),
      findsOneWidget,
    );
    expect(find.widgetWithText(OutlinedButton, '4'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, '2'), findsOneWidget);
    expect(find.text('接戦でした'), findsOneWidget);

    await tester.tap(find.widgetWithText(OutlinedButton, '4'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('スコアを未入力に戻す'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(savedInput, isNotNull);
    expect(savedInput!.side1Score, isNull);
    expect(savedInput!.side2Score, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('score layout switches at 400 logical pixels', (tester) async {
    _setLogicalViewSize(tester, const Size(399, 760));

    await tester.pumpWidget(
      _TestApp(
        progress: _placeholder(),
        onSave: ({required current, required input}) async {
          final saved = _savedProgress(current: current, input: input);
          return DoublesMatchProgressSaveResult(
            match: saved,
            summary: _summary(saved),
          );
        },
      ),
    );

    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('doubles-match-narrow-score-layout')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('doubles-match-wide-score-layout')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(400, 760);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('doubles-match-wide-score-layout')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('doubles-match-narrow-score-layout')),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}

void _setLogicalViewSize(WidgetTester tester, Size size) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

FilledButton _saveButton(WidgetTester tester) {
  return tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, '保存'),
  );
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
    matchNo: 1,
  );
}

ScheduleMatchProgress _persistedProgress() {
  final now = DateTime(2026, 8, 6, 9, 41);
  return ScheduleMatchProgress(
    schemaVersion: ScheduleMatchProgress.currentSchemaVersion,
    scheduleType: ScheduleProgressScheduleType.doubles,
    generatedScheduleId: 'generated-1',
    roundNo: 1,
    courtNo: 1,
    matchNo: 1,
    status: ScheduleMatchStatus.completed,
    result: ScheduleMatchResultSummary.simpleScore(<int>[4, 2]),
    note: '接戦でした',
    startedAt: DateTime(2026, 8, 6, 9, 24),
    finishedAt: now,
    createdAt: now,
    updatedAt: now,
    revision: 1,
  );
}

ScheduleMatchProgress _savedProgress({
  required ScheduleMatchProgress current,
  required DoublesMatchProgressInput input,
}) {
  final now = DateTime(2026, 8, 6, 10, current.revision);
  final hasScores = input.side1Score != null && input.side2Score != null;
  return ScheduleMatchProgress(
    schemaVersion: ScheduleMatchProgress.currentSchemaVersion,
    scheduleType: current.scheduleType,
    generatedScheduleId: current.generatedScheduleId,
    roundNo: current.roundNo,
    courtNo: current.courtNo,
    matchNo: current.matchNo,
    status: input.status,
    result: hasScores
        ? ScheduleMatchResultSummary.simpleScore(<int>[
            input.side1Score!,
            input.side2Score!,
          ])
        : null,
    note: input.note.trim(),
    startedAt: input.startedAt,
    finishedAt: input.finishedAt,
    createdAt: current.createdAt ?? now,
    updatedAt: now,
    revision: current.revision + 1,
  );
}

ScheduleProgressSummary _summary(ScheduleMatchProgress match) {
  final now = match.updatedAt!;
  return ScheduleProgressSummary(
    schemaVersion: ScheduleProgressSummary.currentSchemaVersion,
    scheduleType: match.scheduleType,
    generatedScheduleId: match.generatedScheduleId,
    totalMatchCount: 1,
    completedMatchCount: match.status == ScheduleMatchStatus.completed ? 1 : 0,
    inProgressMatchCount:
        match.status == ScheduleMatchStatus.inProgress ? 1 : 0,
    createdAt: now,
    updatedAt: now,
    revision: match.revision,
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.progress,
    required this.onSave,
  });

  final ScheduleMatchProgress progress;
  final DoublesMatchSaveCallback onSave;

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
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (context) {
                      return DoublesMatchResultDialog(
                        match: const DoublesMatchSelection(
                          roundNo: 1,
                          courtNo: 1,
                          matchNo: 1,
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
                        onSave: onSave,
                      );
                    },
                  );
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
