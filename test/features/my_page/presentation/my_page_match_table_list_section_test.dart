import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/saved_event_models.dart';
import 'package:srp_lanske/features/my_page/presentation/widgets/my_page_match_table_list_section.dart';
import 'package:srp_lanske/l10n/l10n.dart';

void main() {
  testWidgets('shows only current owner events with account-list metadata',
      (tester) async {
    String? requestedOwnerUid;
    SavedEventAggregate? opened;

    final own = _aggregate(
      publicId: 'OWN00001',
      ownerUid: 'owner-1',
      title: '10月の対戦表',
      createdAt: DateTime(2026, 10, 1, 12),
      eventDate: DateTime(2026, 10, 5),
      location: '大久保スポーツプラザ',
      status: SavedEventStatus.adopted,
    );
    final other = _aggregate(
      publicId: 'OTHER001',
      ownerUid: 'owner-2',
      title: '他のownerの対戦表',
      createdAt: DateTime(2026, 10, 2),
    );

    await _pumpSection(
      tester,
      loadOwnedEvents: (ownerUid) async {
        requestedOwnerUid = ownerUid;
        return [other, own];
      },
      onOpenEvent: (aggregate) {
        opened = aggregate;
      },
    );
    await tester.pumpAndSettle();

    expect(requestedOwnerUid, 'owner-1');
    expect(find.text('10月の対戦表'), findsOneWidget);
    expect(find.text('他のownerの対戦表'), findsNothing);
    expect(find.textContaining('作成日:'), findsOneWidget);
    expect(find.textContaining('開催日:'), findsOneWidget);
    expect(find.text('場所: 大久保スポーツプラザ'), findsOneWidget);
    expect(find.text('確定済み'), findsOneWidget);

    await tester.tap(find.text('開く'));
    await tester.pump();

    expect(opened?.event.publicId, 'OWN00001');
  });

  testWidgets('sorts owned events and pages them ten at a time',
      (tester) async {
    final items = List<SavedEventAggregate>.generate(12, (index) {
      final number = index + 1;
      return _aggregate(
        publicId: 'PUBLIC${number.toString().padLeft(2, '0')}',
        ownerUid: 'owner-1',
        title: '対戦表 $number',
        createdAt: DateTime(2026, 9, number),
        status: number.isEven
            ? SavedEventStatus.generated
            : SavedEventStatus.draft,
      );
    });

    await _pumpSection(
      tester,
      loadOwnedEvents: (_) async => items,
    );
    await tester.pumpAndSettle();

    expect(find.text('1 / 2'), findsOneWidget);
    expect(find.text('対戦表 12'), findsOneWidget);
    expect(find.text('対戦表 3'), findsOneWidget);
    expect(find.text('対戦表 2'), findsNothing);
    expect(find.text('対戦表 1'), findsNothing);

    await tester.ensureVisible(find.text('次へ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('次へ'));
    await tester.pumpAndSettle();

    expect(find.text('2 / 2'), findsOneWidget);
    expect(find.text('対戦表 12'), findsNothing);
    expect(find.text('対戦表 2'), findsOneWidget);
    expect(find.text('対戦表 1'), findsOneWidget);
  });

  testWidgets('shows loading then empty state', (tester) async {
    final completer = Completer<List<SavedEventAggregate>>();

    await _pumpSection(
      tester,
      loadOwnedEvents: (_) => completer.future,
    );
    await tester.pump();

    expect(find.text('対戦表を読み込んでいます…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);

    completer.complete(const []);
    await tester.pumpAndSettle();

    expect(
      find.text('このアカウントで管理している対戦表はありません'),
      findsOneWidget,
    );
  });

  testWidgets('shows load error and retries', (tester) async {
    var calls = 0;
    final recovered = _aggregate(
      publicId: 'RECOVER1',
      ownerUid: 'owner-1',
      title: '再取得できた対戦表',
      createdAt: DateTime(2026, 10, 2),
      status: SavedEventStatus.generated,
    );

    await _pumpSection(
      tester,
      loadOwnedEvents: (_) async {
        calls += 1;
        if (calls == 1) {
          throw StateError('load failed');
        }
        return [recovered];
      },
    );
    await tester.pumpAndSettle();

    expect(find.text('対戦表を読み込めませんでした'), findsOneWidget);
    expect(find.text('再読み込み'), findsOneWidget);

    await tester.tap(find.text('再読み込み'));
    await tester.pumpAndSettle();

    expect(find.text('対戦表を読み込めませんでした'), findsNothing);
    expect(find.text('再取得できた対戦表'), findsOneWidget);
    expect(find.text('未確定'), findsOneWidget);
    expect(calls, 2);
  });
}

Future<void> _pumpSection(
  WidgetTester tester, {
  required MyPageOwnedEventsLoader loadOwnedEvents,
  MyPageOwnedEventOpenCallback? onOpenEvent,
}) {
  return tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: MyPageMatchTableListSection(
            ownerUid: 'owner-1',
            loadOwnedEvents: loadOwnedEvents,
            onOpenEvent: onOpenEvent,
          ),
        ),
      ),
    ),
  );
}

SavedEventAggregate _aggregate({
  required String publicId,
  required String ownerUid,
  required String title,
  required DateTime createdAt,
  DateTime? eventDate,
  String? location,
  SavedEventStatus status = SavedEventStatus.draft,
}) {
  final eventId = 'event-$publicId';
  final event = SavedEvent(
    id: eventId,
    publicId: publicId,
    ownerUid: ownerUid,
    title: title,
    eventDate: eventDate,
    location: location,
    courtCount: 1,
    sourceType: EventSourceType.manual,
    sourceUrl: null,
    status: status,
    createdAt: createdAt,
    updatedAt: createdAt,
  );

  return SavedEventAggregate(
    event: event,
    players: const [],
    share: SavedEventShare(
      publicId: publicId,
      eventId: eventId,
      createdAt: createdAt,
      updatedAt: createdAt,
    ),
  );
}
