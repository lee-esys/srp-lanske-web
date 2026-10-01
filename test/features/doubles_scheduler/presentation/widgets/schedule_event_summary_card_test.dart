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

  testWidgets('shows TennisBear source link for imported event',
      (tester) async {
    final aggregate = _aggregate(
      sourceType: EventSourceType.tennisbear,
      sourceUrl: 'https://www.tennisbear.net/event/1645753/info',
    );

    await tester.pumpWidget(
      _testApp(
        ScheduleEventSummaryCard(
          aggregate: aggregate,
          repository: _FakeEventRepository(aggregate),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('テニスベアのイベントを表示する'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('open-tennisbear-source-event-button')),
      findsOneWidget,
    );
  });

  testWidgets('shows TennisBear source link for legacy unknown source',
      (tester) async {
    final aggregate = _aggregate(
      sourceType: EventSourceType.unknown,
      sourceUrl: 'https://www.tennisbear.net/event/1645753/info',
    );

    await tester.pumpWidget(
      _testApp(
        ScheduleEventSummaryCard(
          aggregate: aggregate,
          repository: _FakeEventRepository(aggregate),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('テニスベアのイベントを表示する'), findsOneWidget);
  });

  testWidgets('hides TennisBear source link for manual event', (tester) async {
    final aggregate = _aggregate();

    await tester.pumpWidget(
      _testApp(
        ScheduleEventSummaryCard(
          aggregate: aggregate,
          repository: _FakeEventRepository(aggregate),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('テニスベアのイベントを表示する'), findsNothing);
  });

  testWidgets('uses tap trigger for the event title tooltip', (tester) async {
    final aggregate = _aggregate();
    final repository = _FakeEventRepository(aggregate);

    await tester.pumpWidget(
      _testApp(
        ScheduleEventSummaryCard(
          aggregate: aggregate,
          repository: repository,
        ),
      ),
    );
    await tester.pumpAndSettle();

    final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
    expect(tooltip.triggerMode, TooltipTriggerMode.tap);
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

  testWidgets('shows next match details and invokes navigation',
      (tester) async {
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
    expect(find.text('次の対戦'), findsOneWidget);
    expect(find.text('次の対戦：第2ラウンド / Aコート'), findsOneWidget);
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

    expect(find.text('試合中'), findsOneWidget);
    expect(find.text('試合中：第3ラウンド / 2コート'), findsOneWidget);
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

  testWidgets('loads latest once and directly returns saved display fragment',
      (tester) async {
    final aggregate = _aggregate();
    final repository = _FakeEventRepository(aggregate);
    SavedEventAggregate? updatedResult;

    await tester.pumpWidget(
      _testApp(
        ScheduleEventSummaryCard(
          aggregate: aggregate,
          repository: repository,
          onDisplayUpdated: (updated) async {
            updatedResult = updated;
          },
          progressText: '0 / 10',
          canEditEventInfo: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(repository.findCallCount, 0);
    expect(find.text('イベント'), findsOneWidget);

    await tester.tap(find.text('イベント情報を編集'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(repository.findCallCount, 1);
    expect(find.byType(AlertDialog), findsOneWidget);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '更新後イベント');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AlertDialog), findsNothing);
    expect(repository.findCallCount, 1);
    expect(updatedResult, isNotNull);
    expect(updatedResult!.event.title, '更新後イベント');
  });

  testWidgets('can delegate event editing without showing the inline action',
      (tester) async {
    final aggregate = _aggregate(adopted: true);
    final repository = _FakeEventRepository(aggregate);
    final controller = ScheduleEventSummaryController();

    await tester.pumpWidget(
      _testApp(
        ScheduleEventSummaryCard(
          controller: controller,
          aggregate: aggregate,
          repository: repository,
          showEditAction: false,
          canEditEventInfo: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('イベント情報を編集'), findsNothing);

    controller.editEventInfo();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(AlertDialog), findsOneWidget);
  });

  testWidgets('blocks inline and delegated editing when capability is disabled',
      (tester) async {
    final aggregate = _aggregate();
    final repository = _FakeEventRepository(aggregate);
    final controller = ScheduleEventSummaryController();

    await tester.pumpWidget(
      _testApp(
        ScheduleEventSummaryCard(
          controller: controller,
          aggregate: aggregate,
          repository: repository,
          canEditEventInfo: false,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('イベント情報を編集'), findsNothing);

    await controller.editEventInfo();
    await tester.pumpAndSettle();

    expect(repository.findCallCount, 0);
    expect(find.byType(AlertDialog), findsNothing);
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

SavedEventAggregate _aggregate({
  bool adopted = false,
  EventSourceType sourceType = EventSourceType.manual,
  String? sourceUrl,
}) {
  final now = DateTime.utc(2026, 8, 1);
  final event = SavedEvent(
    id: 'event-1',
    publicId: 'ABCD1234',
    title: 'イベント',
    memo: 'メモ',
    courtCount: 1,
    sourceType: sourceType,
    sourceUrl: sourceUrl,
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

  SavedEventAggregate aggregate;
  int findCallCount = 0;

  @override
  Future<SavedEventAggregate?> findByPublicId(String publicId) async {
    findCallCount += 1;
    return aggregate;
  }

  @override
  Future<SavedEventAggregate> updateDisplayInfo({
    required String publicId,
    required int expectedDisplayRevision,
    required String title,
    required String memo,
    required Map<String, String> playerDisplayNamesById,
  }) async {
    final updatedAt = aggregate.event.updatedAt.add(const Duration(minutes: 1));
    aggregate = SavedEventAggregate(
      event: aggregate.event.copyWith(
        title: title.trim(),
        memo: memo.trim(),
        revision: aggregate.event.revision + 1,
        updatedAt: updatedAt,
      ),
      players: aggregate.players.map((player) {
        final displayName = playerDisplayNamesById[player.id];
        return displayName == null
            ? player
            : player.copyWith(
                displayName: displayName.trim(),
                updatedAt: updatedAt,
              );
      }).toList(growable: false),
      share: aggregate.share,
      importRecord: aggregate.importRecord,
      revisions: aggregate.revisions.copyWith(
        display: aggregate.revisions.display + 1,
      ),
      courtSettings: aggregate.courtSettings,
    );
    return aggregate;
  }

  @override
  Future<SavedEventAggregate> createFromDraft(
    EventDraft draft, {
    required String ownerUid,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<SavedEventPlayer>> listPlayers(String publicId) {
    throw UnimplementedError();
  }

  @override
  Future<SavedEvent> updateCurrentGeneratedScheduleId({
    required String publicId,
    required String generatedScheduleId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SavedEvent> updateAdoptedGeneratedScheduleId({
    required String publicId,
    required String generatedScheduleId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SavedEventAggregate> updateCourtSettings({
    required String publicId,
    required List<SavedEventCourtSetting> courtSettings,
  }) {
    throw UnimplementedError();
  }
}
