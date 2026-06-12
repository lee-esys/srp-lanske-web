import 'package:srp_lanske/features/doubles_scheduler/infrastructure/generated_schedule_api_client.dart';

import '../domain/team_generated_schedule.dart';
import '../presentation/models/team_setup_draft.dart';

class TeamGeneratedScheduleService {
  TeamGeneratedScheduleService(this._apiClient);

  static const int fixedRoundCount = 5;

  final GeneratedScheduleApiClient _apiClient;

  Future<TeamGeneratedSchedule> generateFromDraft(TeamSetupDraft draft) async {
    final response = await _apiClient.generate(
      body: buildGenerateRequest(draft),
    );

    return TeamGeneratedSchedule.fromJson(response);
  }

  Map<String, dynamic> buildGenerateRequest(TeamSetupDraft draft) {
    final participantCount = draft.participantCount.clamp(2, 50).toInt();
    final maxTargetTeamSize = (participantCount - 1).clamp(1, participantCount);
    final targetTeamSize =
        draft.preferredTeamSize.clamp(1, maxTargetTeamSize).toInt();
    final teamCount = (participantCount / targetTeamSize)
        .ceil()
        .clamp(2, participantCount)
        .toInt();
    final teamsPerMatch = draft.teamsPerMatch.clamp(2, teamCount).toInt();
    final maxConcurrentMatchCount =
        (teamCount ~/ teamsPerMatch).clamp(1, teamCount).toInt();
    final concurrentMatchCount =
        draft.concurrentMatchCount.clamp(1, maxConcurrentMatchCount).toInt();
    final activeTeamCountPerRound = concurrentMatchCount * teamsPerMatch;

    return <String, dynamic>{
      'schedule_type': 'team',
      'courts': concurrentMatchCount,
      'round_count': fixedRoundCount,
      'players': List<Map<String, dynamic>>.generate(
        participantCount,
        (index) => <String, dynamic>{
          'player_slot': index + 1,
          'pot_number': 1,
        },
        growable: false,
      ),
      'team_schedule': <String, dynamic>{
        'team_count': teamCount,
        'target_team_size': targetTeamSize,
        'teams_per_match': teamsPerMatch,
        'active_team_count_per_round': activeTeamCountPerRound,
      },
      'constraints': const <String, dynamic>{
        'randomize': true,
      },
    };
  }
}
