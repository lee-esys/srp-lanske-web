import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/event_statistics_eligibility.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/saved_event_models.dart';

void main() {
  SavedEvent event({
    String? ownerUid = 'owner-1',
    bool statisticsEligible = false,
  }) {
    final now = DateTime.utc(2026, 10, 1);
    return SavedEvent(
      id: 'event-1',
      publicId: 'PUBLIC01',
      ownerUid: ownerUid,
      title: 'Event',
      courtCount: 1,
      sourceType: EventSourceType.manual,
      sourceUrl: null,
      status: SavedEventStatus.generated,
      currentGeneratedScheduleId: 'generated-1',
      statisticsEligible: statisticsEligible,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('promotes only when prod actor is the event owner', () {
    expect(
      shouldPromoteStatisticsEligibleOnAdopt(
        event: event(),
        appEnvironment: 'prod',
        currentUid: 'owner-1',
      ),
      isTrue,
    );

    for (final environment in <String>[
      'preview',
      'dev',
      'local',
      'unknown',
    ]) {
      expect(
        shouldPromoteStatisticsEligibleOnAdopt(
          event: event(),
          appEnvironment: environment,
          currentUid: 'owner-1',
        ),
        isFalse,
        reason: environment,
      );
    }
  });

  test('does not promote for non-owner or missing owner identity', () {
    expect(
      shouldPromoteStatisticsEligibleOnAdopt(
        event: event(),
        appEnvironment: 'prod',
        currentUid: 'other-user',
      ),
      isFalse,
    );
    expect(
      shouldPromoteStatisticsEligibleOnAdopt(
        event: event(ownerUid: null),
        appEnvironment: 'prod',
        currentUid: 'owner-1',
      ),
      isFalse,
    );
    expect(
      shouldPromoteStatisticsEligibleOnAdopt(
        event: event(),
        appEnvironment: 'prod',
        currentUid: null,
      ),
      isFalse,
    );
  });

  test('does not request another promotion when already eligible', () {
    expect(
      shouldPromoteStatisticsEligibleOnAdopt(
        event: event(statisticsEligible: true),
        appEnvironment: 'prod',
        currentUid: 'owner-1',
      ),
      isFalse,
    );
  });
}
