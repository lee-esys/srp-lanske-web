import 'dart:convert';

class TeamSetupDraft {
  const TeamSetupDraft({
    required this.concurrentMatchCount,
    required this.participantCount,
    required this.preferredTeamSize,
    required this.teamsPerMatch,
    required this.participantNames,
  });

  final int concurrentMatchCount;
  final int participantCount;
  final int preferredTeamSize;
  final int teamsPerMatch;
  final List<String> participantNames;

  Map<String, dynamic> toJson() {
    return {
      'scheduleType': 'team',
      'concurrentMatchCount': concurrentMatchCount,
      'participantCount': participantCount,
      'preferredTeamSize': preferredTeamSize,
      'teamsPerMatch': teamsPerMatch,
      'participantNames': participantNames,
    };
  }

  @override
  String toString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }
}
