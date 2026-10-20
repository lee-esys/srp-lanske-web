import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/my_page/presentation/widgets/my_page_participation_history_section.dart';
import 'package:srp_lanske/features/participation_history/application/participation_history_service.dart';
import 'package:srp_lanske/features/participation_history/domain/participation_history_entry.dart';
import 'package:srp_lanske/l10n/l10n.dart';

void main() {
  Widget app(MyPageParticipationHistoryLoader loader,
      {VoidCallback? onOpenProfileLinkManagement}) {
    return MaterialApp(
      locale: const Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: MyPageParticipationHistorySection(
            lanskeUserId: 'user-1',
            loadHistory: loader,
            onOpenProfileLinkManagement: onOpenProfileLinkManagement ?? () {},
          ),
        ),
      ),
    );
  }

  testWidgets('unlinked state offers link management', (tester) async {
    var opened = false;
    await tester.pumpWidget(app(
      (_) async => const ParticipationHistoryResult.unlinked(),
      onOpenProfileLinkManagement: () => opened = true,
    ));
    await tester.pumpAndSettle();
    expect(find.textContaining('連携されていないため'), findsOneWidget);
    await tester.tap(find.text('プロフィール連携へ'));
    expect(opened, isTrue);
  });

  testWidgets('linked empty state is distinct from unlinked', (tester) async {
    await tester.pumpWidget(app(
      (_) async => const ParticipationHistoryResult.linked([]),
    ));
    await tester.pumpAndSettle();
    expect(find.text('現在表示できる参加イベントはありません'), findsOneWidget);
    expect(find.text('プロフィール連携へ'), findsNothing);
  });

  testWidgets('shows only safe snapshot fields and eligible chip',
      (tester) async {
    final entries = [
      ParticipationHistoryEntry(
        eventId: 'internal-secret-id',
        sourceType: 'tennisbear',
        sourceUserId: '899212',
        eventDate: DateTime.utc(2026, 10, 10, 3),
        selfSnapshot: const ParticipationSelfSnapshot(
          sourceDisplayName: '本人の表示名',
          levelName: '中上級',
          levelId: 6,
        ),
        statisticsEligible: true,
        isConfirmed: true,
        participantCount: 7,
        updatedAt: DateTime.utc(2026, 10, 12),
      ),
      ParticipationHistoryEntry(
        eventId: 'internal-other-id',
        sourceType: 'tennisbear',
        sourceUserId: '899212',
        statisticsEligible: false,
        isConfirmed: true,
        participantCount: 4,
        updatedAt: DateTime.utc(2026, 10, 12),
      ),
    ];
    await tester.pumpWidget(app(
      (_) async => ParticipationHistoryResult.linked(entries),
    ));
    await tester.pumpAndSettle();

    expect(find.text('参加イベント一覧'), findsOneWidget);
    // Self snapshot remains in the projection, but is no longer shown in the list.
    expect(find.textContaining('本人の表示名'), findsNothing);
    expect(find.textContaining('中上級'), findsNothing);
    expect(find.byIcon(Icons.groups_outlined), findsNWidgets(2));
    expect(find.text('7人'), findsOneWidget);
    expect(find.text('4人'), findsOneWidget);
    expect(find.text('開催日不明'), findsOneWidget);
    expect(find.text('統計対象'), findsOneWidget);
    expect(find.textContaining('internal-secret-id'), findsNothing);
    expect(find.textContaining('899212'), findsNothing);
  });

  testWidgets('unconfirmed entries are not shown', (tester) async {
    final entries = [
      ParticipationHistoryEntry(
        eventId: 'unconfirmed-event',
        sourceType: 'tennisbear',
        sourceUserId: '899212',
        eventDate: DateTime.utc(2026, 10, 13),
        selfSnapshot: const ParticipationSelfSnapshot(
          sourceDisplayName: '未確定の本人',
        ),
        statisticsEligible: false,
        isConfirmed: false,
        participantCount: 7,
        updatedAt: DateTime.utc(2026, 10, 13),
      ),
    ];
    await tester.pumpWidget(app(
      (_) async => ParticipationHistoryResult.linked(entries),
    ));
    await tester.pumpAndSettle();
    expect(find.text('現在表示できる参加イベントはありません'), findsOneWidget);
    expect(find.text('表示名：未確定の本人'), findsNothing);
    expect(find.text('7人'), findsNothing);
  });

  testWidgets('keeps date and attendee count visible on narrow screens',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(app(
      (_) async => ParticipationHistoryResult.linked([
        ParticipationHistoryEntry(
          eventId: 'confirmed-event',
          sourceType: 'tennisbear',
          sourceUserId: '899212',
          eventDate: DateTime.utc(2026, 10, 13),
          selfSnapshot: const ParticipationSelfSnapshot(
            sourceDisplayName: '長い本人のテニスベア表示名',
            levelId: 6,
            levelName: '中上級',
          ),
          statisticsEligible: true,
          isConfirmed: true,
          participantCount: 7,
          updatedAt: DateTime.utc(2026, 10, 13),
        ),
      ]),
    ));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.groups_outlined), findsOneWidget);
    expect(find.text('7人'), findsOneWidget);
    expect(find.text('統計対象'), findsOneWidget);
    expect(find.textContaining('長い本人'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('loading and error can retry', (tester) async {
    final pending = Completer<ParticipationHistoryResult>();
    var calls = 0;
    await tester.pumpWidget(app((_) {
      calls++;
      if (calls == 1) return pending.future;
      if (calls == 2) throw StateError('unavailable');
      return Future.value(const ParticipationHistoryResult.linked([]));
    }));
    await tester.pump();
    expect(find.text('参加イベントを読み込んでいます…'), findsOneWidget);
    pending.completeError(StateError('unavailable'));
    await tester.pumpAndSettle();
    expect(find.text('参加イベントを読み込めませんでした'), findsOneWidget);
    await tester.tap(find.text('再読み込み'));
    await tester.pumpAndSettle();
    expect(find.text('参加イベントを読み込めませんでした'), findsOneWidget);
    await tester.tap(find.text('再読み込み'));
    await tester.pumpAndSettle();
    expect(find.text('現在表示できる参加イベントはありません'), findsOneWidget);
    expect(calls, 3);
  });
}
