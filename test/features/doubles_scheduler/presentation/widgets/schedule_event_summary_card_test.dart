import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/event_repository.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/saved_event_models.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/models/event_draft.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/widgets/schedule_event_summary_card.dart';
import 'package:srp_lanske/l10n/l10n.dart';

void main() {
  testWidgets('disables refresh while loading and shows progress text',
      (tester) async {
    var refreshCount = 0;

    await tester.pumpWidget(
      _testApp(
        ScheduleEventSummaryCard(
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
    var refreshCount = 0;

    await tester.pumpWidget(
      _testApp(
        ScheduleEventSummaryCard(
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

SavedEventAggregate _aggregate() {
  final now = DateTime.utc(2026, 8, 1);
  final event = SavedEvent(
    id: 'event-1',
    publicId: 'ABCD1234',
    title: 'イベント',
    memo: 'メモ',
    courtCount: 1,
    sourceType: EventSourceType.manual,
    sourceUrl: null,
    status: SavedEventStatus.generated,
    currentGeneratedScheduleId: 'generated-1',
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
