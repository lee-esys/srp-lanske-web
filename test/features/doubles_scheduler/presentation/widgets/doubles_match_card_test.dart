import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/doubles_progress_visuals.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/widgets/doubles_match_card.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';

void main() {
  testWidgets('unadopted card hides repeated match status and result details', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _TestApp(
        hasAdoptedSchedule: false,
        status: ScheduleMatchStatus.scheduled,
      ),
    );

    expect(find.text('試合前'), findsNothing);
    expect(find.byKey(const ValueKey('match-score')), findsNothing);
    expect(find.byIcon(Icons.note_alt_outlined), findsNothing);
    expect(find.text('ペアA'), findsOneWidget);
    expect(find.text('ペアB'), findsOneWidget);
  });

  testWidgets('adopted scheduled card keeps the pre-match status', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _TestApp(
        hasAdoptedSchedule: true,
        status: ScheduleMatchStatus.scheduled,
      ),
    );

    expect(find.text('試合前'), findsOneWidget);
    expect(find.byKey(const ValueKey('match-score')), findsNothing);
    expect(find.text('WIN'), findsNothing);
    expect(find.text('LOSE'), findsNothing);
    expect(find.text('DRAW'), findsNothing);
  });

  testWidgets(
      'completed card overlays one WIN and one LOSE without added height', (
    tester,
  ) async {
    await tester.pumpWidget(
      const _TestApp(
        hasAdoptedSchedule: true,
        status: ScheduleMatchStatus.scheduled,
      ),
    );
    final scheduledSize = tester.getSize(
      find.byType(DoublesMatchCardContent),
    );

    await tester.pumpWidget(
      _TestApp(
        hasAdoptedSchedule: true,
        status: ScheduleMatchStatus.completed,
        progress: _progress(
          status: ScheduleMatchStatus.completed,
          scores: const <int>[4, 2],
        ),
      ),
    );
    final completedSize = tester.getSize(
      find.byType(DoublesMatchCardContent),
    );

    expect(find.text('4 - 2'), findsOneWidget);
    expect(find.text('WIN'), findsOneWidget);
    expect(find.text('LOSE'), findsOneWidget);
    expect(find.text('DRAW'), findsNothing);
    expect(completedSize.height, scheduledSize.height);
  });

  testWidgets('draw overlays without changing the center width',
      (tester) async {
    await tester.pumpWidget(
      const _TestApp(
        hasAdoptedSchedule: true,
        status: ScheduleMatchStatus.scheduled,
      ),
    );

    final scheduledSize = tester.getSize(
      find.byType(DoublesMatchCardContent),
    );

    await tester.pumpWidget(
      _TestApp(
        hasAdoptedSchedule: true,
        status: ScheduleMatchStatus.completed,
        progress: _progress(
          status: ScheduleMatchStatus.completed,
          scores: const <int>[2, 2],
        ),
      ),
    );

    final drawSize = tester.getSize(
      find.byType(DoublesMatchCardContent),
    );

    expect(find.text('DRAW'), findsOneWidget);
    expect(find.text('vs'), findsOneWidget);
    expect(find.text('WIN'), findsNothing);
    expect(find.text('LOSE'), findsNothing);
    expect(drawSize.width, scheduledSize.width);
  });

  testWidgets('in-progress score does not show a provisional outcome', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        hasAdoptedSchedule: true,
        status: ScheduleMatchStatus.inProgress,
        progress: _progress(
          status: ScheduleMatchStatus.inProgress,
          scores: const <int>[3, 1],
        ),
      ),
    );

    expect(find.text('3 - 1'), findsOneWidget);
    expect(find.text('WIN'), findsNothing);
    expect(find.text('LOSE'), findsNothing);
    expect(find.text('DRAW'), findsNothing);
  });

  testWidgets('completed match without scores has no outcome label', (
    tester,
  ) async {
    await tester.pumpWidget(
      _TestApp(
        hasAdoptedSchedule: true,
        status: ScheduleMatchStatus.completed,
        progress: _progress(status: ScheduleMatchStatus.completed),
      ),
    );

    expect(find.text('終了'), findsOneWidget);
    expect(find.text('WIN'), findsNothing);
    expect(find.text('LOSE'), findsNothing);
    expect(find.text('DRAW'), findsNothing);
  });

  testWidgets('draw overlays without changing the center width',
      (tester) async {
    await tester.pumpWidget(
      const _TestApp(
        hasAdoptedSchedule: true,
        status: ScheduleMatchStatus.scheduled,
      ),
    );
    final scheduledSize = tester.getSize(
      find.byType(DoublesMatchCardContent),
    );

    await tester.pumpWidget(
      _TestApp(
        hasAdoptedSchedule: true,
        status: ScheduleMatchStatus.completed,
        progress: _progress(
          status: ScheduleMatchStatus.completed,
          scores: const <int>[2, 2],
        ),
      ),
    );
    final drawSize = tester.getSize(
      find.byType(DoublesMatchCardContent),
    );

    expect(find.text('DRAW'), findsOneWidget);
    expect(find.text('vs'), findsOneWidget);
    expect(drawSize.width, scheduledSize.width);
  });
}

ScheduleMatchProgress _progress({
  required ScheduleMatchStatus status,
  List<int>? scores,
}) {
  final now = DateTime(2026, 8, 5, 20);

  return ScheduleMatchProgress(
    schemaVersion: ScheduleMatchProgress.currentSchemaVersion,
    scheduleType: ScheduleProgressScheduleType.doubles,
    generatedScheduleId: 'generated-1',
    roundNo: 1,
    courtNo: 1,
    matchNo: 1,
    status: status,
    result:
        scores == null ? null : ScheduleMatchResultSummary.simpleScore(scores),
    note: '',
    startedAt: status == ScheduleMatchStatus.scheduled ? null : now,
    finishedAt: status == ScheduleMatchStatus.completed ? now : null,
    createdAt: now,
    updatedAt: now,
    revision: 1,
  );
}

class _TestApp extends StatelessWidget {
  const _TestApp({
    required this.hasAdoptedSchedule,
    required this.status,
    this.progress,
  });

  final bool hasAdoptedSchedule;
  final ScheduleMatchStatus status;
  final ScheduleMatchProgress? progress;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Builder(
            builder: (context) {
              return DoublesMatchCardContent(
                hasAdoptedSchedule: hasAdoptedSchedule,
                courtLabel: '1',
                showCourtLabel: false,
                side1: const SizedBox(
                  width: 120,
                  height: 56,
                  child: Center(child: Text('ペアA')),
                ),
                side2: const SizedBox(
                  width: 120,
                  height: 56,
                  child: Center(child: Text('ペアB')),
                ),
                progress: progress,
                status: status,
                visualStyle: resolveDoublesMatchVisualStyle(
                  Theme.of(context).colorScheme,
                  status,
                ),
                statusLabel: switch (status) {
                  ScheduleMatchStatus.scheduled => '試合前',
                  ScheduleMatchStatus.inProgress => '試合中',
                  ScheduleMatchStatus.completed => '終了',
                },
                winnerLabel: 'WIN',
                loserLabel: 'LOSE',
                drawLabel: 'DRAW',
              );
            },
          ),
        ),
      ),
    );
  }
}
