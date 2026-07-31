import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/doubles_schedule_refresh_service.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/event_repository.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/saved_event_models.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/models/event_draft.dart';
import 'package:srp_lanske/features/schedule_progress/application/schedule_progress_repository.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';

void main() {
  group('DoublesScheduleRefreshService', () {
    test('loads schedule without creating progress summary', () async {
      final eventRepository = _FakeEventRepository(
        aggregate: _buildAggregate(generatedScheduleId: 'generated-1'),
      );
      final progressRepository = _FakeProgressRepository();
      var scheduleLoadCount = 0;
      final service = DoublesScheduleRefreshService(
        eventRepository: eventRepository,
        progressRepository: progressRepository,
        loadGeneratedSchedule: (generatedScheduleId) async {
          scheduleLoadCount += 1;
          return <String, dynamic>{
            'generated_schedule_id': generatedScheduleId,
          };
        },
      );

      final snapshot = await service.loadLatestByPublicId(publicId: 'ABC123');

      expect(scheduleLoadCount, 1);
      expect(progressRepository.ensureSummaryCallCount, 0);
      expect(progressRepository.findSummaryCallCount, 1);
      expect(progressRepository.listMatchesCallCount, 0);
      expect(snapshot.progressSummary, isNull);
      expect(snapshot.matches, isEmpty);
      expect(snapshot.progressText, '- / -');
    });

    test('reuses schedule and matches when revisions are unchanged', () async {
      final aggregate = _buildAggregate(generatedScheduleId: 'generated-1');
      final scope = _scope('generated-1');
      final summary = _summary(revision: 2);
      final match = _match(revision: 3);
      final current = DoublesScheduleRefreshSnapshot(
        aggregate: aggregate,
        scheduleResponse: const <String, dynamic>{
          'generated_schedule_id': 'generated-1',
        },
        progressScope: scope,
        progressSummary: summary,
        matches: <ScheduleMatchProgress>[match],
        eventChanged: false,
        scheduleChanged: false,
        progressChanged: false,
      );
      final progressRepository = _FakeProgressRepository(summary: summary);
      var scheduleLoadCount = 0;
      final service = DoublesScheduleRefreshService(
        eventRepository: _FakeEventRepository(aggregate: aggregate),
        progressRepository: progressRepository,
        loadGeneratedSchedule: (generatedScheduleId) async {
          scheduleLoadCount += 1;
          return <String, dynamic>{
            'generated_schedule_id': generatedScheduleId,
          };
        },
      );

      final snapshot = await service.loadLatestByPublicId(
        publicId: 'ABC123',
        current: current,
      );

      expect(scheduleLoadCount, 0);
      expect(progressRepository.listMatchesCallCount, 0);
      expect(snapshot.eventChanged, isFalse);
      expect(snapshot.scheduleChanged, isFalse);
      expect(snapshot.progressChanged, isFalse);
      expect(snapshot.matches.single.revision, 3);
    });

    test('reloads matches when progress summary revision changes', () async {
      final aggregate = _buildAggregate(generatedScheduleId: 'generated-1');
      final current = DoublesScheduleRefreshSnapshot(
        aggregate: aggregate,
        scheduleResponse: const <String, dynamic>{
          'generated_schedule_id': 'generated-1',
        },
        progressScope: _scope('generated-1'),
        progressSummary: _summary(revision: 1),
        matches: <ScheduleMatchProgress>[_match(revision: 1)],
        eventChanged: false,
        scheduleChanged: false,
        progressChanged: false,
      );
      final latestMatch = _match(revision: 2);
      final progressRepository = _FakeProgressRepository(
        summary: _summary(revision: 2),
        matches: <ScheduleMatchProgress>[latestMatch],
      );
      final service = DoublesScheduleRefreshService(
        eventRepository: _FakeEventRepository(aggregate: aggregate),
        progressRepository: progressRepository,
        loadGeneratedSchedule: (_) async =>
            throw StateError('schedule must be reused'),
      );

      final snapshot = await service.loadLatestByPublicId(
        publicId: 'ABC123',
        current: current,
      );

      expect(progressRepository.listMatchesCallCount, 1);
      expect(snapshot.progressChanged, isTrue);
      expect(snapshot.matches.single.revision, 2);
      expect(snapshot.progressText, '0 / 15');
    });

    test('reloads generated schedule when display id changes', () async {
      final current = DoublesScheduleRefreshSnapshot(
        aggregate: _buildAggregate(generatedScheduleId: 'generated-1'),
        scheduleResponse: const <String, dynamic>{
          'generated_schedule_id': 'generated-1',
        },
        progressScope: _scope('generated-1'),
        progressSummary: null,
        matches: const <ScheduleMatchProgress>[],
        eventChanged: false,
        scheduleChanged: false,
        progressChanged: false,
      );
      var loadedId = '';
      final service = DoublesScheduleRefreshService(
        eventRepository: _FakeEventRepository(
          aggregate: _buildAggregate(
            generatedScheduleId: 'generated-2',
            revision: 2,
          ),
        ),
        progressRepository: _FakeProgressRepository(),
        loadGeneratedSchedule: (generatedScheduleId) async {
          loadedId = generatedScheduleId;
          return <String, dynamic>{
            'generated_schedule_id': generatedScheduleId,
          };
        },
      );

      final snapshot = await service.loadLatestByPublicId(
        publicId: 'ABC123',
        current: current,
      );

      expect(loadedId, 'generated-2');
      expect(snapshot.eventChanged, isTrue);
      expect(snapshot.scheduleChanged, isTrue);
      expect(snapshot.generatedScheduleId, 'generated-2');
    });

    test('throws not found when event does not exist', () async {
      final service = DoublesScheduleRefreshService(
        eventRepository: _FakeEventRepository(aggregate: null),
        progressRepository: _FakeProgressRepository(),
        loadGeneratedSchedule: (_) async => const <String, dynamic>{},
      );

      expect(
        () => service.loadLatestByPublicId(publicId: 'ABC123'),
        throwsA(isA<DoublesScheduleNotFoundException>()),
      );
    });
  });
}

SavedEventAggregate _buildAggregate({
  required String generatedScheduleId,
  int revision = 1,
}) {
  final now = DateTime.utc(2026, 7, 31, 1);
  final event = SavedEvent(
    id: 'event-1',
    publicId: 'ABC123',
    title: 'Event',
    courtCount: 1,
    sourceType: EventSourceType.manual,
    sourceUrl: null,
    status: SavedEventStatus.generated,
    currentGeneratedScheduleId: generatedScheduleId,
    createdAt: now,
    updatedAt: now,
    revision: revision,
  );

  return SavedEventAggregate(
    event: event,
    players: <SavedEventPlayer>[
      SavedEventPlayer(
        id: 'player-1',
        eventId: event.id,
        displayName: 'Player 1',
        orderNo: 1,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      ),
    ],
    share: SavedEventShare(
      publicId: event.publicId,
      eventId: event.id,
      createdAt: now,
      updatedAt: now,
    ),
  );
}

ScheduleProgressScope _scope(String generatedScheduleId) {
  return ScheduleProgressScope(
    scheduleType: ScheduleProgressScheduleType.doubles,
    shareId: 'ABC123',
    generatedScheduleId: generatedScheduleId,
  );
}

ScheduleProgressSummary _summary({required int revision}) {
  final now = DateTime.utc(2026, 7, 31, 1);
  return ScheduleProgressSummary(
    schemaVersion: ScheduleProgressSummary.currentSchemaVersion,
    scheduleType: ScheduleProgressScheduleType.doubles,
    generatedScheduleId: 'generated-1',
    totalMatchCount: 15,
    completedMatchCount: 0,
    inProgressMatchCount: 0,
    createdAt: now,
    updatedAt: now,
    revision: revision,
  );
}

ScheduleMatchProgress _match({required int revision}) {
  final now = DateTime.utc(2026, 7, 31, 1);
  return ScheduleMatchProgress(
    schemaVersion: ScheduleMatchProgress.currentSchemaVersion,
    scheduleType: ScheduleProgressScheduleType.doubles,
    generatedScheduleId: 'generated-1',
    roundNo: 1,
    courtNo: 1,
    matchNo: 1,
    status: ScheduleMatchStatus.scheduled,
    result: null,
    note: '',
    startedAt: null,
    finishedAt: null,
    createdAt: now,
    updatedAt: now,
    revision: revision,
  );
}

class _FakeEventRepository implements EventRepository {
  _FakeEventRepository({required this.aggregate});

  final SavedEventAggregate? aggregate;

  @override
  Future<SavedEventAggregate?> findByPublicId(String publicId) async {
    return aggregate;
  }

  @override
  Future<SavedEventAggregate> createFromDraft(EventDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<List<SavedEventPlayer>> listPlayers(String eventId) {
    throw UnimplementedError();
  }

  @override
  Future<SavedEvent> updateAdoptedGeneratedScheduleId({
    required String eventId,
    required String generatedScheduleId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SavedEventAggregate> updateCourtSettings({
    required String eventId,
    required List<SavedEventCourtSetting> courtSettings,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SavedEvent> updateCurrentGeneratedScheduleId({
    required String eventId,
    required String generatedScheduleId,
  }) {
    throw UnimplementedError();
  }
}

class _FakeProgressRepository implements ScheduleProgressRepository {
  _FakeProgressRepository({
    this.summary,
    this.matches = const <ScheduleMatchProgress>[],
  });

  final ScheduleProgressSummary? summary;
  final List<ScheduleMatchProgress> matches;
  int ensureSummaryCallCount = 0;
  int findSummaryCallCount = 0;
  int listMatchesCallCount = 0;

  @override
  Future<ScheduleProgressSummary> ensureSummary({
    required ScheduleProgressScope scope,
    required int totalMatchCount,
  }) {
    ensureSummaryCallCount += 1;
    throw UnimplementedError();
  }

  @override
  Future<ScheduleProgressSummary?> findSummary(
    ScheduleProgressScope scope,
  ) async {
    findSummaryCallCount += 1;
    return summary;
  }

  @override
  Future<List<ScheduleMatchProgress>> listMatches(
    ScheduleProgressScope scope,
  ) async {
    listMatchesCallCount += 1;
    return matches;
  }

  @override
  Future<ScheduleMatchProgress> findMatch({
    required ScheduleProgressScope scope,
    required int roundNo,
    required int courtNo,
    int? matchNo,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<ScheduleMatchProgress> saveMatch({
    required ScheduleProgressScope scope,
    required ScheduleMatchProgressUpdate update,
    required int totalMatchCount,
    required int expectedRevision,
  }) {
    throw UnimplementedError();
  }
}
