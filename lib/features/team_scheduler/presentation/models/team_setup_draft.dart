import 'dart:convert';

class TeamSetupDraft {
  const TeamSetupDraft({
    required this.courts,
    required this.teamCount,
    required this.activeTeamCountPerRound,
    required this.teamSize,
    required this.participantCount,
  });

  final int courts;
  final int teamCount;
  final int activeTeamCountPerRound;
  final int teamSize;
  final int participantCount;

  Map<String, dynamic> toJson() {
    return {
      'scheduleType': 'team',
      'courts': courts,
      'teamCount': teamCount,
      'activeTeamCountPerRound': activeTeamCountPerRound,
      'teamSize': teamSize,
      'participantCount': participantCount,
    };
  }

  @override
  String toString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }
}
