import 'package:srp_lanske/features/doubles_scheduler/domain/public_id.dart';

import '../application/team_schedule_repository.dart';
import '../domain/saved_team_schedule.dart';
import '../domain/team_generated_schedule.dart';
import '../presentation/models/team_setup_draft.dart';

class InMemoryTeamScheduleRepository implements TeamScheduleRepository {
  InMemoryTeamScheduleRepository({
    String Function()? shareIdGenerator,
  }) : _shareIdGenerator = shareIdGenerator ?? generatePublicId;

  final String Function() _shareIdGenerator;
  final Map<String, SavedTeamSchedule> _schedulesByShareId = {};

  @override
  Future<SavedTeamSchedule> createFromGenerated({
    required TeamSetupDraft draft,
    required TeamGeneratedSchedule generated,
    required String eventTitle,
    required Map<int, String> teamNames,
    required Map<int, String> memberNames,
  }) async {
    final now = DateTime.now();
    final shareId = _generateUniqueShareId();

    final saved = SavedTeamSchedule(
      schemaVersion: SavedTeamSchedule.currentSchemaVersion,
      shareId: shareId,
      status: 'active',
      scheduleType: SavedTeamSchedule.teamScheduleType,
      createdAt: now,
      updatedAt: now,
      setup: SavedTeamScheduleSetup(
        concurrentMatchCount: draft.concurrentMatchCount,
        participantCount: draft.participantCount,
        preferredTeamSize: draft.preferredTeamSize,
        teamsPerMatch: draft.teamsPerMatch,
        roundCount: generated.roundCount,
      ),
      display: SavedTeamScheduleDisplay(
        eventTitle: eventTitle,
        teamNames: Map<int, String>.unmodifiable(teamNames),
        memberNames: Map<int, String>.unmodifiable(memberNames),
      ),
      snapshot: generated.rawJson,
      scores: const <String, dynamic>{},
    );

    _schedulesByShareId[shareId] = saved;
    return saved;
  }

  @override
  Future<SavedTeamSchedule?> findByShareId(String shareId) async {
    return _schedulesByShareId[shareId];
  }

  @override
  Future<SavedTeamSchedule> updateDisplay({
    required String shareId,
    required SavedTeamScheduleDisplay display,
  }) async {
    final current = _schedulesByShareId[shareId];
    if (current == null) {
      throw StateError('team schedule not found: $shareId');
    }

    final updated = current.copyWith(
      display: display,
      updatedAt: DateTime.now(),
    );

    _schedulesByShareId[shareId] = updated;
    return updated;
  }

  String _generateUniqueShareId() {
    for (var attempt = 0; attempt < 10; attempt += 1) {
      final candidate = _shareIdGenerator();

      if (!isValidPublicId(candidate)) {
        throw StateError('invalid share_id generated: $candidate');
      }

      if (!_schedulesByShareId.containsKey(candidate)) {
        return candidate;
      }
    }

    throw StateError('failed to generate unique share_id');
  }
}
