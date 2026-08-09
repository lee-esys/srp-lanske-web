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

    expect(find.text('R 1 / C 1'), findsOneWidget);
    expect(find.textContaining('/ M '), findsNothing);
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

  testWidgets('revision conflict keeps the draft and can restore latest state', (
    tester,
  ) async {
    final latest = _progressFor(
      _matchSelection(roundNo: 1, courtNo: 1, matchNo: 1),
      note: 'latest from another device',
      revision: 2,
    );

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
        onLoadMatch: (_) async => latest,
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

    await tester.tap(find.text('最新の状態に戻す'));
    await tester.pumpAndSettle();
    expect(find.text('未保存の変更を破棄して最新の状態に戻しますか？'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '最新の状態に戻す'));
    await tester.pumpAndSettle();

    expect(find.text('latest from another device'), findsOneWidget);
    expect(find.text('keep this draft'), findsNothing);
    expect(find.text('試合情報を更新しました'), findsOneWidget);
    expect(_saveButton(tester).onPressed, isNull);
  });

  testWidgets('navigation follows all displayed matches including completed', (
    tester,
  ) async {
    final match1 = _matchSelection(roundNo: 1, courtNo: 1, matchNo: 1);
    final match2 = _matchSelection(roundNo: 1, courtNo: 2, matchNo: 2);
    final match3 = _matchSelection(roundNo: 2, courtNo: 1, matchNo: 3);
    final loaded = <String>[];

    await tester.pumpWidget(
      _TestApp(
        match: match1,
        matches: <DoublesMatchSelection>[match1, match2, match3],
        progress: _progressFor(match1),
        onSave: ({required current, required input}) async {
          final saved = _savedProgress(current: current, input: input);
          return DoublesMatchProgressSaveResult(
            match: saved,
            summary: _summary(saved),
          );
        },
        onLoadMatch: (match) async {
          loaded.add('${match.roundNo}-${match.courtNo}');
          return _progressFor(
            match,
            status: match.courtNo == 2
                ? ScheduleMatchStatus.completed
                : ScheduleMatchStatus.scheduled,
            side1Score: match.courtNo == 2 ? 4 : null,
            side2Score: match.courtNo == 2 ? 2 : null,
          );
        },
      ),
    );

    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();

    expect(find.text('R 1 / C 1'), findsOneWidget);
    expect(_navigationButton(tester, previous: true).onPressed, isNull);
    expect(_navigationButton(tester, previous: false).onPressed, isNotNull);

    await _tapNextMatch(tester);
    await tester.pumpAndSettle();

    expect(find.text('R 1 / C 2'), findsOneWidget);
    expect(find.text('終了'), findsOneWidget);
    expect(loaded, <String>['1-2']);

    await _tapNextMatch(tester);
    await tester.pumpAndSettle();

    expect(find.text('R 2 / C 1'), findsOneWidget);
    expect(loaded, <String>['1-2', '2-1']);
    expect(_navigationButton(tester, previous: false).onPressed, isNull);
  });

  testWidgets('dirty navigation can cancel or discard before moving', (
    tester,
  ) async {
    final match1 = _matchSelection(roundNo: 1, courtNo: 1, matchNo: 1);
    final match2 = _matchSelection(roundNo: 1, courtNo: 2, matchNo: 2);

    await tester.pumpWidget(
      _TestApp(
        match: match1,
        matches: <DoublesMatchSelection>[match1, match2],
        progress: _progressFor(match1),
        onSave: ({required current, required input}) async {
          final saved = _savedProgress(current: current, input: input);
          return DoublesMatchProgressSaveResult(
            match: saved,
            summary: _summary(saved),
          );
        },
        onLoadMatch: (match) async => _progressFor(match, note: 'target note'),
      ),
    );

    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'discard me');
    await tester.pump();

    await _tapNextMatch(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'キャンセル'));
    await tester.pumpAndSettle();

    expect(find.text('R 1 / C 1'), findsOneWidget);
    expect(find.text('discard me'), findsOneWidget);

    await _tapNextMatch(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存せず移動'));
    await tester.pumpAndSettle();

    expect(find.text('R 1 / C 2'), findsOneWidget);
    expect(find.text('target note'), findsOneWidget);
    expect(find.text('discard me'), findsNothing);
  });

  testWidgets('dirty navigation saves successfully before moving', (
    tester,
  ) async {
    final match1 = _matchSelection(roundNo: 1, courtNo: 1, matchNo: 1);
    final match2 = _matchSelection(roundNo: 1, courtNo: 2, matchNo: 2);
    final savedNotes = <String>[];

    await tester.pumpWidget(
      _TestApp(
        match: match1,
        matches: <DoublesMatchSelection>[match1, match2],
        progress: _progressFor(match1),
        onSave: ({required current, required input}) async {
          savedNotes.add(input.note);
          final saved = _savedProgress(current: current, input: input);
          return DoublesMatchProgressSaveResult(
            match: saved,
            summary: _summary(saved),
          );
        },
        onLoadMatch: (match) async => _progressFor(match, note: 'next match'),
      ),
    );

    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'save before move');
    await tester.pump();

    await _tapNextMatch(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('保存して移動'));
    await tester.pumpAndSettle();

    expect(savedNotes, <String>['save before move']);
    expect(find.text('R 1 / C 2'), findsOneWidget);
    expect(find.text('next match'), findsOneWidget);
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

Future<void> _tapNextMatch(WidgetTester tester) async {
  final finder = find.byKey(const Key('doubles-match-next-button'));
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
}

FilledButton _saveButton(WidgetTester tester) {
  return tester.widget<FilledButton>(
    find.widgetWithText(FilledButton, '保存'),
  );
}

IconButton _navigationButton(WidgetTester tester, {required bool previous}) {
  return tester.widget<IconButton>(
    find.byKey(
      Key(
        previous
            ? 'doubles-match-previous-button'
            : 'doubles-match-next-button',
      ),
    ),
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

DoublesMatchSelection _matchSelection({
  required int roundNo,
  required int courtNo,
  required int matchNo,
}) {
  final firstSlot = (matchNo - 1) * 4 + 1;
  return DoublesMatchSelection(
    roundNo: roundNo,
    courtNo: courtNo,
    matchNo: matchNo,
    side1Players: <DoublesMatchParticipantViewModel>[
      DoublesMatchParticipantViewModel(
        slotNumber: firstSlot,
        playerId: 'player-$firstSlot',
        displayName: '参加者$firstSlot',
      ),
      DoublesMatchParticipantViewModel(
        slotNumber: firstSlot + 1,
        playerId: 'player-${firstSlot + 1}',
        displayName: '参加者${firstSlot + 1}',
      ),
    ],
    side2Players: <DoublesMatchParticipantViewModel>[
      DoublesMatchParticipantViewModel(
        slotNumber: firstSlot + 2,
        playerId: 'player-${firstSlot + 2}',
        displayName: '参加者${firstSlot + 2}',
      ),
      DoublesMatchParticipantViewModel(
        slotNumber: firstSlot + 3,
        playerId: 'player-${firstSlot + 3}',
        displayName: '参加者${firstSlot + 3}',
      ),
    ],
  );
}

ScheduleMatchProgress _progressFor(
  DoublesMatchSelection match, {
  ScheduleMatchStatus status = ScheduleMatchStatus.scheduled,
  int? side1Score,
  int? side2Score,
  String note = '',
  int revision = 0,
}) {
  final now = DateTime(2026, 8, 9, 9, revision);
  final hasScores = side1Score != null && side2Score != null;
  return ScheduleMatchProgress(
    schemaVersion: ScheduleMatchProgress.currentSchemaVersion,
    scheduleType: ScheduleProgressScheduleType.doubles,
    generatedScheduleId: 'generated-1',
    roundNo: match.roundNo,
    courtNo: match.courtNo,
    matchNo: match.matchNo,
    status: status,
    result: hasScores
        ? ScheduleMatchResultSummary.simpleScore(<int>[
            side1Score!,
            side2Score!,
          ])
        : null,
    note: note,
    startedAt: status == ScheduleMatchStatus.scheduled ? null : now,
    finishedAt: status == ScheduleMatchStatus.completed ? now : null,
    createdAt: revision == 0 ? null : now,
    updatedAt: revision == 0 ? null : now,
    revision: revision,
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
    this.match,
    this.matches = const <DoublesMatchSelection>[],
    this.onLoadMatch,
  });

  final ScheduleMatchProgress progress;
  final DoublesMatchSaveCallback onSave;
  final DoublesMatchSelection? match;
  final List<DoublesMatchSelection> matches;
  final DoublesMatchLoadCallback? onLoadMatch;

  @override
  Widget build(BuildContext context) {
    final initialMatch =
        match ?? _matchSelection(roundNo: 1, courtNo: 1, matchNo: 1);

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
                        match: initialMatch,
                        initialProgress: progress,
                        matches: matches,
                        onLoadMatch: onLoadMatch,
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
