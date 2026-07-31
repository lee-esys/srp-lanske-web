import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/event_repository.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/saved_event_models.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/models/event_draft.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/widgets/doubles_event_info_dialog.dart';
import 'package:srp_lanske/l10n/l10n.dart';

void main() {
  testWidgets('shows initial names as labels and current names as inputs',
      (tester) async {
    final aggregate = _aggregate();
    final repository = _FakeEventRepository(aggregate);

    await _openDialog(tester, repository, aggregate);

    expect(find.text('イベント情報を編集'), findsOneWidget);
    expect(find.text('参加者1：①'), findsOneWidget);
    expect(find.text('参加者2：②'), findsOneWidget);
    expect(find.text('現在名1'), findsOneWidget);
    expect(find.text('現在名2'), findsOneWidget);
  });

  testWidgets('saves title memo and every player display name',
      (tester) async {
    final aggregate = _aggregate();
    final repository = _FakeEventRepository(aggregate);
    SavedEventAggregate? result;

    await _openDialog(
      tester,
      repository,
      aggregate,
      onResult: (value) => result = value,
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '更新後イベント');
    await tester.enterText(fields.at(1), '運営メモ');
    await tester.enterText(
      find.byKey(const ValueKey('doubles-player-player-1')),
      '更新名1',
    );
    await tester.enterText(
      find.byKey(const ValueKey('doubles-player-player-2')),
      '更新名2',
    );

    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(repository.updateCallCount, 1);
    expect(repository.expectedRevisions, <int>[1]);
    expect(repository.lastTitle, '更新後イベント');
    expect(repository.lastMemo, '運営メモ');
    expect(repository.lastNames, <String, String>{
      'player-1': '更新名1',
      'player-2': '更新名2',
    });
    expect(result, isNotNull);
    expect(result!.event.title, '更新後イベント');
  });

  testWidgets('keeps input and retries with latest revision after conflict',
      (tester) async {
    final aggregate = _aggregate();
    final repository = _FakeEventRepository(
      aggregate,
      conflictOnFirstUpdate: true,
    );
    SavedEventAggregate? result;

    await _openDialog(
      tester,
      repository,
      aggregate,
      onResult: (value) => result = value,
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '自分の入力');

    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(find.text('イベント情報を編集'), findsOneWidget);
    expect(find.text('自分の入力'), findsOneWidget);
    expect(
      find.textContaining('別の端末でイベント情報が更新されていました'),
      findsOneWidget,
    );
    expect(repository.expectedRevisions, <int>[1]);

    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(repository.expectedRevisions, <int>[1, 2]);
    expect(result, isNotNull);
    expect(result!.event.title, '自分の入力');
  });

  testWidgets('does not save when required values are empty', (tester) async {
    final aggregate = _aggregate();
    final repository = _FakeEventRepository(aggregate);

    await _openDialog(tester, repository, aggregate);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '');
    await tester.enterText(
      find.byKey(const ValueKey('doubles-player-player-1')),
      '',
    );

    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pump();

    expect(find.text('イベントタイトルを入力してください'), findsOneWidget);
    expect(find.text('プレイヤー表示名を入力してください'), findsOneWidget);
    expect(repository.updateCallCount, 0);
  });
}

Future<void> _openDialog(
  WidgetTester tester,
  EventRepository repository,
  SavedEventAggregate aggregate, {
  ValueChanged<SavedEventAggregate?>? onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                final result = await showDialog<SavedEventAggregate>(
                  context: context,
                  builder: (_) => DoublesEventInfoDialog(
                    initialAggregate: aggregate,
                    repository: repository,
                  ),
                );
                onResult?.call(result);
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

SavedEventAggregate _aggregate({int revision = 1, String title = 'イベント'}) {
  final now = DateTime.utc(2026, 8, 1);
  final event = SavedEvent(
    id: 'event-1',
    publicId: 'ABCD1234',
    title: title,
    memo: '初期メモ',
    courtCount: 1,
    sourceType: EventSourceType.manual,
    sourceUrl: null,
    status: SavedEventStatus.generated,
    currentGeneratedScheduleId: 'generated-1',
    revision: revision,
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
        displayName: '現在名1',
        orderNo: 1,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      ),
      SavedEventPlayer(
        id: 'player-2',
        eventId: event.id,
        initialDisplayName: '②',
        displayName: '現在名2',
        orderNo: 2,
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
  _FakeEventRepository(
    this.current, {
    this.conflictOnFirstUpdate = false,
  });

  SavedEventAggregate current;
  final bool conflictOnFirstUpdate;
  int updateCallCount = 0;
  final List<int> expectedRevisions = <int>[];
  String? lastTitle;
  String? lastMemo;
  Map<String, String>? lastNames;

  @override
  Future<SavedEventAggregate?> findByPublicId(String publicId) async {
    return current;
  }

  @override
  Future<SavedEventAggregate> updateDisplayInfo({
    required String publicId,
    required int expectedRevision,
    required String title,
    required String memo,
    required Map<String, String> playerDisplayNamesById,
  }) async {
    updateCallCount += 1;
    expectedRevisions.add(expectedRevision);
    lastTitle = title;
    lastMemo = memo;
    lastNames = Map<String, String>.from(playerDisplayNamesById);

    if (conflictOnFirstUpdate && updateCallCount == 1) {
      current = _copyAggregate(
        current,
        title: '別端末の更新',
        revision: current.event.revision + 1,
      );
      throw EventRevisionConflictException(
        eventId: current.event.id,
        expectedRevision: expectedRevision,
        actualRevision: current.event.revision,
      );
    }

    current = _copyAggregate(
      current,
      title: title.trim(),
      memo: memo.trim(),
      names: playerDisplayNamesById,
      revision: current.event.revision + 1,
    );
    return current;
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

SavedEventAggregate _copyAggregate(
  SavedEventAggregate source, {
  required String title,
  String? memo,
  Map<String, String>? names,
  required int revision,
}) {
  final updatedAt = source.event.updatedAt.add(const Duration(minutes: 1));
  return SavedEventAggregate(
    event: source.event.copyWith(
      title: title,
      memo: memo,
      revision: revision,
      updatedAt: updatedAt,
    ),
    players: source.players.map((player) {
      final nextName = names?[player.id];
      return nextName == null
          ? player
          : player.copyWith(
              displayName: nextName.trim(),
              updatedAt: updatedAt,
            );
    }).toList(growable: false),
    share: source.share,
    importRecord: source.importRecord,
    courtSettings: source.courtSettings,
  );
}
