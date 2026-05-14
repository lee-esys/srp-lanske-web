// lib/shared/repositories/app_repositories.dart

import 'package:srp_lanske/app/config/app_config.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/event_repository.dart';
import 'package:srp_lanske/features/doubles_scheduler/data/firestore_event_repository.dart';
import 'package:srp_lanske/features/doubles_scheduler/data/in_memory_event_repository.dart';

final EventRepository appEventRepository = _createEventRepository();

EventRepository _createEventRepository() {
  if (AppConfig.usesFirestoreEventRepository) {
    return FirestoreEventRepository();
  }

  return InMemoryEventRepository();
}
