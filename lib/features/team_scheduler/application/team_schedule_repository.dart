import '../domain/saved_team_schedule.dart';
import '../domain/team_generated_schedule.dart';
import '../presentation/models/team_setup_draft.dart';

abstract class TeamScheduleRepository {
  Future<SavedTeamSchedule> createFromGenerated({
    required TeamSetupDraft draft,
    required TeamGeneratedSchedule generated,
    required String eventTitle,
    required Map<int, String> teamNames,
    required Map<int, String> memberNames,
  });

  Future<SavedTeamSchedule?> findByShareId(String shareId);

  Future<SavedTeamSchedule> updateDisplay({
    required String shareId,
    required SavedTeamScheduleDisplay display,
  });
}
