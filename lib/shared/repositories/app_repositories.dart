// lib/shared/repositories/app_repositories.dart

import 'package:srp_lanske/app/config/app_config.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/event_repository.dart';
import 'package:srp_lanske/features/doubles_scheduler/data/firestore_event_repository.dart';
import 'package:srp_lanske/features/doubles_scheduler/data/in_memory_event_repository.dart';
import 'package:srp_lanske/features/schedule_progress/application/schedule_progress_repository.dart';
import 'package:srp_lanske/features/schedule_progress/data/firestore_schedule_progress_repository.dart';
import 'package:srp_lanske/features/schedule_progress/data/in_memory_schedule_progress_repository.dart';
import 'package:srp_lanske/features/team_scheduler/application/team_schedule_repository.dart';
import 'package:srp_lanske/features/team_scheduler/data/firestore_team_schedule_repository.dart';
import 'package:srp_lanske/features/team_scheduler/data/in_memory_team_schedule_repository.dart';

final EventRepository appEventRepository = _createEventRepository();

final TeamScheduleRepository appTeamScheduleRepository =
    _createTeamScheduleRepository();

final ScheduleProgressRepository appScheduleProgressRepository =
    _createScheduleProgressRepository();

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

ScheduleProgressRepository _createScheduleProgressRepository() {
  if (AppConfig.usesFirestoreEventRepository) {
    return FirestoreScheduleProgressRepository();
  }

  return InMemoryScheduleProgressRepository();
}
