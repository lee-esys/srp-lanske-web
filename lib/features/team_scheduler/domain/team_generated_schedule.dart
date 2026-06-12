class TeamGeneratedSchedule {
  const TeamGeneratedSchedule({
    required this.generatedScheduleId,
    required this.scheduleType,
    required this.status,
    required this.algorithmVersion,
    required this.courts,
    required this.roundCount,
    required this.playerCount,
    required this.teamCount,
    required this.teamsPerMatch,
    required this.activeTeamCountPerRound,
    required this.players,
    required this.teams,
    required this.assignments,
    required this.rounds,
    required this.inspection,
    required this.score,
    required this.warnings,
    required this.rawJson,
  });

  factory TeamGeneratedSchedule.fromJson(Map<String, dynamic> json) {
    return TeamGeneratedSchedule(
      generatedScheduleId: _readString(json, 'generated_schedule_id'),
      scheduleType: _readString(json, 'schedule_type'),
      status: _readString(json, 'status'),
      algorithmVersion: _readString(json, 'algorithm_version'),
      courts: _readInt(json, 'courts'),
      roundCount: _readInt(json, 'round_count'),
      playerCount: _readInt(json, 'player_count'),
      teamCount: _readInt(json, 'team_count'),
      teamsPerMatch: _readInt(json, 'teams_per_match'),
      activeTeamCountPerRound: _readInt(
        json,
        'active_team_count_per_round',
      ),
      players: _readObjectList(json, 'players')
          .map(TeamGeneratedPlayer.fromJson)
          .toList(growable: false),
      teams: _readObjectList(json, 'teams')
          .map(TeamGeneratedTeam.fromJson)
          .toList(growable: false),
      assignments: _readObjectList(json, 'assignments')
          .map(TeamGeneratedAssignment.fromJson)
          .toList(growable: false),
      rounds: _readObjectList(json, 'rounds')
          .map(TeamGeneratedRound.fromJson)
          .toList(growable: false),
      inspection: _readObject(json, 'inspection'),
      score: _readObject(json, 'score'),
      warnings: _readStringList(json, 'warnings'),
      rawJson: Map<String, dynamic>.unmodifiable(json),
    );
  }

  final String generatedScheduleId;
  final String scheduleType;
  final String status;
  final String algorithmVersion;
  final int courts;
  final int roundCount;
  final int playerCount;
  final int teamCount;
  final int teamsPerMatch;
  final int activeTeamCountPerRound;
  final List<TeamGeneratedPlayer> players;
  final List<TeamGeneratedTeam> teams;
  final List<TeamGeneratedAssignment> assignments;
  final List<TeamGeneratedRound> rounds;
  final Map<String, dynamic> inspection;
  final Map<String, dynamic> score;
  final List<String> warnings;
  final Map<String, dynamic> rawJson;
}

class TeamGeneratedPlayer {
  const TeamGeneratedPlayer({
    required this.playerSlot,
    required this.potNumber,
  });

  factory TeamGeneratedPlayer.fromJson(Map<String, dynamic> json) {
    return TeamGeneratedPlayer(
      playerSlot: _readInt(json, 'player_slot'),
      potNumber: _readInt(json, 'pot_number'),
    );
  }

  final int playerSlot;
  final int potNumber;
}

class TeamGeneratedTeam {
  const TeamGeneratedTeam({
    required this.teamSlot,
    required this.memberPlayerSlots,
  });

  factory TeamGeneratedTeam.fromJson(Map<String, dynamic> json) {
    return TeamGeneratedTeam(
      teamSlot: _readInt(json, 'team_slot'),
      memberPlayerSlots: _readIntList(json, 'member_player_slots'),
    );
  }

  final int teamSlot;
  final List<int> memberPlayerSlots;
}

class TeamGeneratedAssignment {
  const TeamGeneratedAssignment({
    required this.playerSlot,
    required this.teamSlot,
  });

  factory TeamGeneratedAssignment.fromJson(Map<String, dynamic> json) {
    return TeamGeneratedAssignment(
      playerSlot: _readInt(json, 'player_slot'),
      teamSlot: _readInt(json, 'team_slot'),
    );
  }

  final int playerSlot;
  final int teamSlot;
}

class TeamGeneratedRound {
  const TeamGeneratedRound({
    required this.roundNo,
    required this.courts,
  });

  factory TeamGeneratedRound.fromJson(Map<String, dynamic> json) {
    final courts = _readObjectList(json, 'courts');
    final fallbackMatches =
        courts.isEmpty ? _readObjectList(json, 'matches') : courts;

    return TeamGeneratedRound(
      roundNo: _readInt(json, 'round_no'),
      courts: fallbackMatches
          .map(TeamGeneratedRoundCourt.fromJson)
          .toList(growable: false),
    );
  }

  final int roundNo;
  final List<TeamGeneratedRoundCourt> courts;
}

class TeamGeneratedRoundCourt {
  const TeamGeneratedRoundCourt({
    required this.courtNo,
    required this.matchNo,
    required this.teamSlots,
  });

  factory TeamGeneratedRoundCourt.fromJson(Map<String, dynamic> json) {
    return TeamGeneratedRoundCourt(
      courtNo: _readInt(json, 'court_no'),
      matchNo: _readInt(json, 'match_no'),
      teamSlots: _readIntList(json, 'team_slots'),
    );
  }

  final int courtNo;
  final int matchNo;
  final List<int> teamSlots;
}

String _readString(
  Map<String, dynamic> json,
  String key, {
  String defaultValue = '',
}) {
  final value = json[key];
  if (value == null) {
    return defaultValue;
  }

  return value.toString();
}

int _readInt(
  Map<String, dynamic> json,
  String key, {
  int defaultValue = 0,
}) {
  return _tryReadInt(json[key]) ?? defaultValue;
}

int? _tryReadInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value);
  }

  return null;
}

List<int> _readIntList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List) {
    return const [];
  }

  final result = <int>[];
  for (final item in value) {
    final parsed = _tryReadInt(item);
    if (parsed != null) {
      result.add(parsed);
    }
  }

  return List<int>.unmodifiable(result);
}

List<String> _readStringList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List) {
    return const [];
  }

  return List<String>.unmodifiable(value.map((item) => item.toString()));
}

Map<String, dynamic> _readObject(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  return const <String, dynamic>{};
}

List<Map<String, dynamic>> _readObjectList(
  Map<String, dynamic> json,
  String key,
) {
  final value = json[key];
  if (value is! List) {
    return const [];
  }

  return value.whereType<Map>().map((item) {
    return Map<String, dynamic>.from(item);
  }).toList(growable: false);
}
