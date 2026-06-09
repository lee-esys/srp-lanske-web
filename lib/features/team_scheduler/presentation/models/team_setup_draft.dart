import 'dart:convert';

class TeamSetupDraft {
  const TeamSetupDraft({
    required this.concurrentMatchCount,
    required this.participantCount,
    required this.teamCount,
    required this.teamsPerMatch,
  });

  final int concurrentMatchCount;
  final int participantCount;
  final int teamCount;
  final int teamsPerMatch;

  Map<String, dynamic> toJson() {
    return {
      'scheduleType': 'team',
      'concurrentMatchCount': concurrentMatchCount,
      'participantCount': participantCount,
      'teamCount': teamCount,
      'teamsPerMatch': teamsPerMatch,
    };
  }

  @override
  String toString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }
}
