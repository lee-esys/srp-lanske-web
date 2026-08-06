import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/widgets/schedule_rounds_view_impl.dart'
    as impl;
import 'package:srp_lanske/l10n/l10n.dart';

void main() {
  testWidgets('round metadata shares one match header row on mobile width', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(375, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const _TestApp());
    await tester.pumpAndSettle();

    expect(find.text('R1・Aコート'), findsOneWidget);
    expect(find.text('R1・Bコート'), findsOneWidget);
    expect(find.text('R 1'), findsNothing);
    expect(find.text('試合前'), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey('round-rest-toggle-1')),
      findsOneWidget,
    );
    expect(find.text('休憩：3人'), findsOneWidget);

    final positionCenter = tester.getCenter(
      find.byKey(const ValueKey('match-position-R1・Aコート')),
    );
    final statusCenter = tester.getCenter(
      find.byKey(const ValueKey('match-status-scheduled')).first,
    );
    final restCenter = tester.getCenter(
      find.byKey(const ValueKey('round-rest-toggle-1')),
    );

    expect((positionCenter.dy - statusCenter.dy).abs(), lessThan(1));
    expect((positionCenter.dy - restCenter.dy).abs(), lessThan(1));
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('round-rest-toggle-1')));
    await tester.pumpAndSettle();

    expect(find.text('休憩:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _TestApp extends StatelessWidget {
  const _TestApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('ja'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: impl.ScheduleRoundsView(
            scheduleResponse: _scheduleResponse,
            playerNameById: _playerNameById,
            courtCount: 2,
            courtLabelByNumber: const <int, String>{1: 'A', 2: 'B'},
          ),
        ),
      ),
    );
  }
}

const _playerNameById = <String, String>{
  'player-1': '参加者1',
  'player-2': '参加者2',
  'player-3': '参加者3',
  'player-4': '参加者4',
  'player-5': '参加者5',
  'player-6': '参加者6',
  'player-7': '参加者7',
  'player-8': '参加者8',
  'player-9': '参加者9',
  'player-10': '参加者10',
  'player-11': '参加者11',
};

const _scheduleResponse = <String, dynamic>{
  'generated_schedule_id': 'generated-1',
  'adopted': true,
  'assignment': <Map<String, dynamic>>[
    {'slot_number': 1, 'player_id': 'player-1'},
    {'slot_number': 2, 'player_id': 'player-2'},
    {'slot_number': 3, 'player_id': 'player-3'},
    {'slot_number': 4, 'player_id': 'player-4'},
    {'slot_number': 5, 'player_id': 'player-5'},
    {'slot_number': 6, 'player_id': 'player-6'},
    {'slot_number': 7, 'player_id': 'player-7'},
    {'slot_number': 8, 'player_id': 'player-8'},
    {'slot_number': 9, 'player_id': 'player-9'},
    {'slot_number': 10, 'player_id': 'player-10'},
    {'slot_number': 11, 'player_id': 'player-11'},
  ],
  'rounds': <Map<String, dynamic>>[
    {
      'round_number': 1,
      'rest_slot_numbers': <int>[9, 10, 11],
      'courts': <Map<String, dynamic>>[
        {
          'court_number': 1,
          'match_number': 1,
          'team1_player_slots': <int>[1, 2],
          'team2_player_slots': <int>[3, 4],
        },
        {
          'court_number': 2,
          'match_number': 2,
          'team1_player_slots': <int>[5, 6],
          'team2_player_slots': <int>[7, 8],
        },
      ],
    },
  ],
};
