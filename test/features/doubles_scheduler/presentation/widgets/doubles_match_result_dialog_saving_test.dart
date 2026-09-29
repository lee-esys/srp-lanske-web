import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/doubles_match_progress_service.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/doubles_match_save_registry.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/models/doubles_match_editor_models.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/widgets/doubles_match_result_dialog.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';
import 'package:srp_lanske/l10n/l10n.dart';

void main() {
  testWidgets('debounces rapid edits and saves only the latest draft',
      (tester) async {
    final savedInputs = <DoublesMatchProgressInput>[];

    await tester.pumpWidget(
      _TestApp(
        onSave: ({required current, required input}) async {
          savedInputs.add(input);
          final saved = _savedProgress(input, revision: current.revision + 1);
          return DoublesMatchProgressSaveResult(
            match: saved,
            summary: _summary(saved),
          );
        },
      ),
    );

    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'first');
    await tester.pump(const Duration(milliseconds: 300));
    expect(savedInputs, isEmpty);

    await tester.enterText(find.byType(TextField), 'latest');
    await tester.pump(const Duration(milliseconds: 499));
    expect(savedInputs, isEmpty);

    await tester.pump(const Duration(milliseconds: 1));
    await tester.pump();

    expect(savedInputs, hasLength(1));
    expect(savedInputs.single.note, 'latest');
    expect(find.textContaining('同期済み '), findsOneWidget);
    expect(find.widgetWithText(FilledButton, '保存'), findsNothing);
  });

  testWidgets(
      'keeps editing enabled while saving and follows with the latest draft',
      (tester) async {
    final completers = <Completer<DoublesMatchProgressSaveResult>>[];
    final usedRevisions = <int>[];
    final savedInputs = <DoublesMatchProgressInput>[];

    await tester.pumpWidget(
      _TestApp(
        onLoadMatch: (_) async => _placeholder(),
        onSave: ({required current, required input}) {
          usedRevisions.add(current.revision);
          savedInputs.add(input);
          final completer = Completer<DoublesMatchProgressSaveResult>();
          completers.add(completer);
          return completer.future;
        },
      ),
    );

    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'first');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(savedInputs, hasLength(1));
    expect(savedInputs.single.note, 'first');
    expect(_closeButton(tester).onPressed, isNull);
    expect(_refreshButton(tester).onPressed, isNull);
    expect(_nextButton(tester).onPressed, isNull);
    expect(find.text('保存中…'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'latest');
    await tester.pump();
    expect(find.text('latest'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 500));
    expect(savedInputs, hasLength(1));

    final firstSaved = _savedProgress(savedInputs.first, revision: 1);
    completers.first.complete(
      DoublesMatchProgressSaveResult(
        match: firstSaved,
        summary: _summary(firstSaved),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(savedInputs, hasLength(2));
    expect(savedInputs.last.note, 'latest');
    expect(usedRevisions, <int>[0, 1]);
    expect(find.text('latest'), findsOneWidget);

    final secondSaved = _savedProgress(savedInputs.last, revision: 2);
    completers.last.complete(
      DoublesMatchProgressSaveResult(
        match: secondSaved,
        summary: _summary(secondSaved),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('latest'), findsOneWidget);
    expect(find.textContaining('同期済み '), findsOneWidget);
    expect(_closeButton(tester).onPressed, isNotNull);
    expect(_refreshButton(tester).onPressed, isNotNull);
    expect(_nextButton(tester).onPressed, isNotNull);
  });

  testWidgets('save failure does not retry until another user edit',
      (tester) async {
    var saveCallCount = 0;

    await tester.pumpWidget(
      _TestApp(
        onSave: ({required current, required input}) async {
          saveCallCount += 1;
          throw StateError('save failed');
        },
      ),
    );

    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'first');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(saveCallCount, 1);
    expect(find.textContaining('試合情報を保存できませんでした'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    expect(saveCallCount, 1);

    await tester.enterText(find.byType(TextField), 'second');
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump();

    expect(saveCallCount, 2);
  });

  testWidgets('dirty close flushes immediately without a confirmation dialog',
      (tester) async {
    final usedRevisions = <int>[];
    final savedNotes = <String>[];

    await tester.pumpWidget(
      _TestApp(
        onSave: ({required current, required input}) async {
          usedRevisions.add(current.revision);
          savedNotes.add(input.note);
          final saved = _savedProgress(input, revision: current.revision + 1);
          return DoublesMatchProgressSaveResult(
            match: saved,
            summary: _summary(saved),
          );
        },
      ),
    );

    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'save before closing');
    await tester.pump();

    await tester.tap(find.widgetWithText(TextButton, '閉じる'));
    await tester.pumpAndSettle();

    expect(usedRevisions, <int>[0]);
    expect(savedNotes, <String>['save before closing']);
    expect(find.text('保存して閉じる'), findsNothing);
    expect(find.text('試合状態・最終スコア'), findsNothing);
  });
}

IconButton _nextButton(WidgetTester tester) {
  return tester.widget<IconButton>(
    find.byKey(const Key('doubles-match-next-button')),
  );
}

TextButton _closeButton(WidgetTester tester) {
  return tester.widget<TextButton>(
    find.widgetWithText(TextButton, '閉じる'),
  );
}

TextButton _refreshButton(WidgetTester tester) {
  return tester.widget<TextButton>(
    find.widgetWithText(TextButton, '最新の情報に更新'),
  );
}

ScheduleMatchProgress _savedProgress(
  DoublesMatchProgressInput input, {
  required int revision,
}) {
  final now = DateTime(2026, 8, 6, 9, 40);
  return ScheduleMatchProgress(
    schemaVersion: ScheduleMatchProgress.currentSchemaVersion,
    scheduleType: ScheduleProgressScheduleType.doubles,
    generatedScheduleId: 'generated-1',
    roundNo: 1,
    courtNo: 1,
    matchNo: 1,
    status: input.status,
    result: null,
    note: input.note.trim(),
    startedAt: input.startedAt,
    finishedAt: input.finishedAt,
    createdAt: now,
    updatedAt: now,
    revision: revision,
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

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.onSave,
    this.onLoadMatch,
  });

  final DoublesMatchSaveCallback onSave;
  final DoublesMatchLoadCallback? onLoadMatch;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return FilledButton(
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
                            displayName: '参加者1',
                          ),
                          DoublesMatchParticipantViewModel(
                            slotNumber: 2,
                            displayName: '参加者2',
                          ),
                        ],
                        side2Players: <DoublesMatchParticipantViewModel>[
                          DoublesMatchParticipantViewModel(
                            slotNumber: 3,
                            displayName: '参加者3',
                          ),
                          DoublesMatchParticipantViewModel(
                            slotNumber: 4,
                            displayName: '参加者4',
                          ),
                        ],
                      ),
                      matches: const <DoublesMatchSelection>[
                        DoublesMatchSelection(
                          roundNo: 1,
                          courtNo: 1,
                          matchNo: 1,
                          side1Players: <DoublesMatchParticipantViewModel>[
                            DoublesMatchParticipantViewModel(
                              slotNumber: 1,
                              displayName: '参加者1',
                            ),
                            DoublesMatchParticipantViewModel(
                              slotNumber: 2,
                              displayName: '参加者2',
                            ),
                          ],
                          side2Players: <DoublesMatchParticipantViewModel>[
                            DoublesMatchParticipantViewModel(
                              slotNumber: 3,
                              displayName: '参加者3',
                            ),
                            DoublesMatchParticipantViewModel(
                              slotNumber: 4,
                              displayName: '参加者4',
                            ),
                          ],
                        ),
                        DoublesMatchSelection(
                          roundNo: 1,
                          courtNo: 2,
                          matchNo: 2,
                          side1Players: <DoublesMatchParticipantViewModel>[
                            DoublesMatchParticipantViewModel(
                              slotNumber: 1,
                              displayName: '参加者1',
                            ),
                            DoublesMatchParticipantViewModel(
                              slotNumber: 3,
                              displayName: '参加者3',
                            ),
                          ],
                          side2Players: <DoublesMatchParticipantViewModel>[
                            DoublesMatchParticipantViewModel(
                              slotNumber: 2,
                              displayName: '参加者2',
                            ),
                            DoublesMatchParticipantViewModel(
                              slotNumber: 4,
                              displayName: '参加者4',
                            ),
                          ],
                        ),
                      ],
                      initialProgress: _placeholder(),
                      onLoadMatch: onLoadMatch,
                      onSave: onSave,
                    );
                  },
                );
              },
              child: const Text('開く'),
            );
          },
        ),
      ),
    );
  }
}
