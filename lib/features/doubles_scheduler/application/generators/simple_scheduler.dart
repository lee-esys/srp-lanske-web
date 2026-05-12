/// イベント内で使用するプレイヤー情報。
class SchedulerPlayer {
  const SchedulerPlayer({
    required this.inputOrder,
    required this.eventNumber,
    required this.displayName,
  });

  /// 入力画面上の並び順
  final int inputOrder;

  /// このイベント内で試合計算に使う番号
  final int eventNumber;

  /// 表示用の名前
  final String displayName;

  @override
  String toString() => '$eventNumber:$displayName';
}

/// 1コート分の対戦情報。
class ScheduledCourt {
  const ScheduledCourt({
    required this.teamA,
    required this.teamB,
  });

  final List<SchedulerPlayer> teamA;
  final List<SchedulerPlayer> teamB;

  Map<String, dynamic> toJson() {
    return {
      'teamA': teamA.map((e) => e.eventNumber).toList(),
      'teamB': teamB.map((e) => e.eventNumber).toList(),
    };
  }
}

/// 1ラウンド分の対戦情報。
class ScheduledRound {
  const ScheduledRound({
    required this.roundNumber,
    required this.restPlayers,
    required this.courts,
  });

  final int roundNumber;
  final List<SchedulerPlayer> restPlayers;
  final List<ScheduledCourt> courts;

  Map<String, dynamic> toJson() {
    return {
      'roundNumber': roundNumber,
      'restPlayers': restPlayers.map((e) => e.eventNumber).toList(),
      'courts': courts.map((e) => e.toJson()).toList(),
    };
  }
}

class SimpleScheduler {
  const SimpleScheduler();

  List<ScheduledRound> generate({
    required List<SchedulerPlayer> players,
    required int courtCount,
    required int rounds,
  }) {
    if (players.isEmpty) {
      throw ArgumentError('players must not be empty.');
    }
    if (courtCount < 1) {
      throw ArgumentError('courtCount must be >= 1.');
    }
    if (rounds < 1) {
      throw ArgumentError('rounds must be >= 1.');
    }

    final playersPerRound = courtCount * 4;
    if (players.length < playersPerRound) {
      throw ArgumentError(
        'Not enough players. players=${players.length}, '
        'requiredAtLeast=$playersPerRound',
      );
    }

    final result = <ScheduledRound>[];

    for (var roundIndex = 0; roundIndex < rounds; roundIndex++) {
      final restPlayers = _selectRestPlayers(
        players: players,
        restPerRound: players.length - playersPerRound,
      );

      final playingPlayers = players
          .where((p) => !restPlayers.any((r) => r.eventNumber == p.eventNumber))
          .toList();

      final courtGroups = _buildCourtGroups(
        playingPlayers: playingPlayers,
        courtCount: courtCount,
      );

      final courts = <ScheduledCourt>[];
      for (final group in courtGroups) {
        courts.add(_selectBestPairingForCourt(playersOnCourt: group));
      }

      result.add(
        ScheduledRound(
          roundNumber: roundIndex + 1,
          restPlayers: restPlayers,
          courts: courts,
        ),
      );
    }

    return result;
  }

  List<SchedulerPlayer> _selectRestPlayers({
    required List<SchedulerPlayer> players,
    required int restPerRound,
  }) {
    if (restPerRound <= 0) {
      return const [];
    }

    final sorted = [...players]
      ..sort((a, b) => a.eventNumber.compareTo(b.eventNumber));

    return sorted.reversed.take(restPerRound).toList();
  }

  List<List<SchedulerPlayer>> _buildCourtGroups({
    required List<SchedulerPlayer> playingPlayers,
    required int courtCount,
  }) {
    final groups = <List<SchedulerPlayer>>[];

    for (var i = 0; i < courtCount; i++) {
      final start = i * 4;
      final end = start + 4;

      if (end > playingPlayers.length) {
        throw StateError(
          'Not enough playing players for court groups. '
          'start=$start end=$end total=${playingPlayers.length}',
        );
      }

      groups.add(playingPlayers.sublist(start, end));
    }

    return groups;
  }

  ScheduledCourt _selectBestPairingForCourt({
    required List<SchedulerPlayer> playersOnCourt,
  }) {
    if (playersOnCourt.length != 4) {
      throw ArgumentError('playersOnCourt must be exactly 4.');
    }

    final sorted = [...playersOnCourt]
      ..sort((a, b) => a.eventNumber.compareTo(b.eventNumber));

    return ScheduledCourt(
      teamA: [sorted[0], sorted[1]],
      teamB: [sorted[2], sorted[3]],
    );
  }
}
