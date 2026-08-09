import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/event_repository.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/saved_event_models.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/doubles_progress_ui_store.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/models/event_draft.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/widgets/schedule_event_summary_card.dart';
import 'package:srp_lanske/l10n/l10n.dart';

void main() {
  setUp(DoublesProgressUiStore.clearOverride);
  tearDown(DoublesProgressUiStore.clearOverride);

  testWidgets('disables refresh while loading and shows progress text',
      (tester) async {
    final aggregate = _aggregate(adopted: true);
    final repository = _FakeEventRepository(aggregate);
    var refreshCount = 0;

    await tester.pumpWidget(
      _testApp(
        ScheduleEventSummaryCard(
          aggregate: aggregate,
          repository: repository,
          onRefresh: () async {
            refreshCount += 1;
          },
          isRefreshing: true,
          progressText: '- / -',
        ),
      ),
    );

    expect(find.text('- / -'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    expect(refreshCount, 0);
  });

  testWidgets('runs refresh action when enabled', (tester) async {
    final aggregate = _aggregate(adopted: true);
    final repository = _FakeEventRepository(aggregate);
    var refreshCount = 0;

    await tester.pumpWidget(
      _testApp(
        ScheduleEventSummaryCard(
          aggregate: aggregate,
          repository: repository,
          onRefresh: () async {
            refreshCount += 1;
          },
          progressText: '3 / 15',
        ),
      ),
    );

    expect(find.text('3 / 15'), findsOneWidget);
    expect(find.byIcon(Icons.sync), findsOneWidget);

    await tester.tap(find.byType(FilledButton));
    await tester.pump();
    expect(refreshCount, 1);
  });

  testWidgets('hides progress UI before the schedule is adopted',
      (tester) async {
    final aggregate = _aggregate();
    final repository = _FakeEventRepository(aggregate);
    DoublesProgressUiStore.setSummary(null, totalMatchCount: 15);
    DoublesProgressUiStore.setNavigation(
      DoublesProgressNavigationUiState(
        kind: DoublesProgressNavigationUiKind.nextMatch,
        roundNo: 1,
        courtLabel: 'A',
        side1PlayerNames: const ['参加者1', '参加者2'],
        side2PlayerNames: const ['参加者3', '参加者4'],
        inProgressMatchCount: 0,
        targetKey: 'r1_c1',
        onNavigate: () async {},
      ),
    );

    await tester.pumpWidget(
      _testApp(
        ScheduleEventSummaryCard(
          aggregate: aggregate,
          repository: repository,
          progressText: '0 / 15',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('doubles-progress-summary-chip')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('doubles-progress-navigation')),
      findsNothing,
    );
  });

  testWidgets('shows next match details and invokes navigation', (tester) async {
    final aggregate = _aggregate(adopted: true);
    final repository = _FakeEventRepository(aggregate);
    var navigationCount = 0;
    DoublesProgressUiStore.setSummary(null, totalMatchCount: 15);
    DoublesProgressUiStore.setNavigation(
      DoublesProgressNavigationUiState(
        kind: DoublesProgressNavigationUiKind.nextMatch,
        roundNo: 2,
        courtLabel: 'A',
        side1PlayerNames: const ['参加者1', '参加者2'],
        side2PlayerNames: const ['参加者3', '参加者4'],
        inProgressMatchCount: 0,
        targetKey: 'r2_c1',
        onNavigate: () async {
          navigationCount += 1;
        },
      ),
    );

    await tester.pumpWidget(
      _testApp(
        ScheduleEventSummaryCard(
          aggregate: aggregate,
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('0 / 15'), findsOneWidget);
    expect(find.text('次の対戦'), findsNWidgets(2));
    expect(find.text('第2ラウンド / A'), findsOneWidget);
    expect(find.text('参加者1 / 参加者2 vs 参加者3 / 参加者4'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('doubles-progress-move-button')),
    );
    await tester.pump();
    expect(navigationCount, 1);
  });

  testWidgets('shows multiple in-progress matches and completed state',
      (tester) async {
    final aggregate = _aggregate(adopted: true);
    final repository = _FakeEventRepository(aggregate);
    DoublesProgressUiStore.setNavigation(
      DoublesProgressNavigationUiState(
        kind: DoublesProgressNavigationUiKind.inProgress,
        roundNo: 3,
        courtLabel: '2',
        side1PlayerNames: const ['A', 'B'],
        side2PlayerNames: const ['C', 'D'],
        inProgressMatchCount: 2,
        targetKey: 'r3_c2',
        onNavigate: () async {},
      ),
    );

    await tester.pumpWidget(
      _testApp(
        ScheduleEventSummaryCard(
          aggregate: aggregate,
          repository: repository,
          progressText: '3 / 15',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('試合中'), findsNWidgets(2));
    expect(find.byType(Badge), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    DoublesProgressUiStore.setNavigation(
      const DoublesProgressNavigationUiState.completed(),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('doubles-progress-navigation-completed')),
      findsOneWidget,
    );
    expect(find.text('終了'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('doubles-progress-move-button')),
      findsNothing,
    );
  });

  testWidgets('refreshes before opening and after closing the edit dialog',
      (tester) async {
    final aggregate = _aggregate();
    final repository = _FakeEventRepository(aggregate);
    var refreshCount = 0;

    await tester.pumpWidget(
      _testApp(
        ScheduleEventSummaryCard(
          aggregate: aggregate,
          repository: repository,
          onRefreshForEdit: () async {
            refreshCount += 1;
            return true;
          },
          progressText: '0 / 10',
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('イベント'), findsOneWidget);
    await tester.tap(find.text('イベント情報を編集'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(refreshCount, 1);
    expect(find.byType(AlertDialog), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'キャンセル'));
    await tester.pumpAndSettle();

    expect(refreshCount, 2);
    expect(repository.findCallCount, greaterThanOrEqualTo(2));
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

SavedEventAggregate _aggregate({bool adopted = false}) {
  final now = DateTime.utc(2026, 8, 1);
  final event = SavedEvent(
    id: 'event-1',
    publicId: 'ABCD1234',
    title: 'イベント',
    memo: 'メモ',
    courtCount: 1,
    sourceType: EventSourceType.manual,
    sourceUrl: null,
    status: adopted ? SavedEventStatus.adopted : SavedEventStatus.generated,
    currentGeneratedScheduleId: 'generated-1',
    adoptedGeneratedScheduleId: adopted ? 'generated-1' : null,
    adoptedAt: adopted ? now : null,
    createdAt: now,
    updatedAt: now,
  );

  return SavedEventAggregate(
    event: event,
    players: <SavedEventPlayer>[
      SavedEventPlayer(
        id: 'player-1',
        eventId: event.id,
        initialDisplayName: '①',
        displayName: '参加者1',
        orderNo: 1,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      ),
    ],
    share: SavedEventShare(
      publicId: event.publicId,
      eventId: event.id,
      createdAt: now,
      updatedAt: now,
    ),
  );
}

class _FakeEventRepository extends EventRepository {
  _FakeEventRepository(this.aggregate);

  final SavedEventAggregate aggregate;
  int findCallCount = 0;

  @override
  Future<SavedEventAggregate?> findByPublicId(String publicId) async {
    findCallCount += 1;
    return aggregate;
  }

  @override
  Future<SavedEventAggregate> createFromDraft(EventDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<List<SavedEventPlayer>> listPlayers(String eventId) {
    throw UnimplementedError();
  }

  @override
  Future<SavedEvent> updateCurrentGeneratedScheduleId({
    required String eventId,
    required String generatedScheduleId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SavedEvent> updateAdoptedGeneratedScheduleId({
    required String eventId,
    required String generatedScheduleId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SavedEventAggregate> updateCourtSettings({
    required String eventId,
    required List<SavedEventCourtSetting> courtSettings,
  }) {
    throw UnimplementedError();
  }
}
