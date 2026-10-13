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
            onOpenProfileLinkManagement:
                onOpenProfileLinkManagement ?? () {},
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
          levelName: 'Lv4',
        ),
        statisticsEligible: true,
        updatedAt: DateTime.utc(2026, 10, 12),
      ),
      ParticipationHistoryEntry(
        eventId: 'internal-other-id',
        sourceType: 'tennisbear',
        sourceUserId: '899212',
        statisticsEligible: false,
        updatedAt: DateTime.utc(2026, 10, 12),
      ),
    ];
    await tester.pumpWidget(app(
      (_) async => ParticipationHistoryResult.linked(entries),
    ));
    await tester.pumpAndSettle();

    expect(find.text('参加イベント一覧'), findsOneWidget);
    expect(find.text('本人の表示名 · Lv4'), findsOneWidget);
    expect(find.text('開催日不明'), findsOneWidget);
    expect(find.text('統計対象'), findsOneWidget);
    expect(find.textContaining('internal-secret-id'), findsNothing);
    expect(find.textContaining('899212'), findsNothing);
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
