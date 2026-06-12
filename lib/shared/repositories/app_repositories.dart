// lib/shared/repositories/app_repositories.dart

import 'package:srp_lanske/app/config/app_config.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/event_repository.dart';
import 'package:srp_lanske/features/doubles_scheduler/data/firestore_event_repository.dart';
import 'package:srp_lanske/features/doubles_scheduler/data/in_memory_event_repository.dart';
import 'package:srp_lanske/features/team_scheduler/application/team_schedule_repository.dart';
import 'package:srp_lanske/features/team_scheduler/data/firestore_team_schedule_repository.dart';
import 'package:srp_lanske/features/team_scheduler/data/in_memory_team_schedule_repository.dart';

final EventRepository appEventRepository = _createEventRepository();

final TeamScheduleRepository appTeamScheduleRepository =
    _createTeamScheduleRepository();

EventRepository _createEventRepository() {
  if (AppConfig.usesFirestoreEventRepository) {
    return FirestoreEventRepository();
  }

  return InMemoryEventRepository();
}

TeamScheduleRepository _createTeamScheduleRepository() {
  if (AppConfig.usesFirestoreEventRepository) {
    return FirestoreTeamScheduleRepository();
  }

  return InMemoryTeamScheduleRepository();
}
