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
  testWidgets('saving disables duplicate save and close actions',
      (tester) async {
    final completer = Completer<DoublesMatchProgressSaveResult>();
    var saveCallCount = 0;

    await tester.pumpWidget(
      _TestApp(
        onSave: ({required current, required input}) {
          saveCallCount += 1;
          return completer.future;
        },
      ),
    );

    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('試合中'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pump();

    expect(saveCallCount, 1);
    expect(_saveButton(tester).onPressed, isNull);
    expect(_closeButton(tester).onPressed, isNull);
    expect(find.text('処理中…'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pump();
    expect(saveCallCount, 1);

    final input = DoublesMatchProgressInput(
      status: ScheduleMatchStatus.inProgress,
      side1Score: null,
      side2Score: null,
      note: '',
      startedAt: DateTime(2026, 8, 6, 9, 30),
      finishedAt: null,
    );
    final saved = _savedProgress(input, revision: 1);
    completer.complete(
      DoublesMatchProgressSaveResult(
        match: saved,
        summary: _summary(saved),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('試合状態・最終スコア'), findsOneWidget);
    expect(find.text('試合情報を保存しました'), findsOneWidget);
    expect(_saveButton(tester).onPressed, isNull);
    expect(_closeButton(tester).onPressed, isNotNull);
  });

  testWidgets('save and close closes only after a successful save', (
    tester,
  ) async {
    final usedRevisions = <int>[];

    await tester.pumpWidget(
      _TestApp(
        onSave: ({required current, required input}) async {
          usedRevisions.add(current.revision);
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
    await tester.tap(find.text('保存して閉じる'));
    await tester.pumpAndSettle();

    expect(usedRevisions, <int>[0]);
    expect(find.text('試合状態・最終スコア'), findsNothing);
  });
}

FilledButton _saveButton(WidgetTester tester) {
  return tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, '保存'),
  );
}

TextButton _closeButton(WidgetTester tester) {
  return tester.widget<TextButton>(
    find.widgetWithText(TextButton, '閉じる'),
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

class _TestApp extends StatelessWidget {
  const _TestApp({required this.onSave});

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
                      initialProgress:
                          ScheduleMatchProgress.scheduledPlaceholder(
                        scope: ScheduleProgressScope(
                          scheduleType: ScheduleProgressScheduleType.doubles,
                          shareId: 'ABC123',
                          generatedScheduleId: 'generated-1',
                        ),
                        roundNo: 1,
                        courtNo: 1,
                        matchNo: 1,
                      ),
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
