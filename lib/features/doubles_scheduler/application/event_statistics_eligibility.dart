import '../domain/saved_event_models.dart';

bool shouldPromoteStatisticsEligibleOnAdopt({
  required SavedEvent event,
  required String appEnvironment,
  required String? currentUid,
}) {
  if (event.statisticsEligible) {
    return false;
  }

  final ownerUid = event.ownerUid?.trim() ?? '';
  final actorUid = currentUid?.trim() ?? '';
  if (ownerUid.isEmpty || actorUid.isEmpty || ownerUid != actorUid) {
    return false;
  }

  return appEnvironment.trim().toLowerCase() == 'prod';
}
