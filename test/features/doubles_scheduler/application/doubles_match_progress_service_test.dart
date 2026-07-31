import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/doubles_match_progress_service.dart';
import 'package:srp_lanske/features/schedule_progress/application/schedule_progress_repository.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';

void main() {
  group('buildUpdate', () {
    test('starts a scheduled match at the supplied current time', () {
      final now = DateTime(2026, 7, 31, 15, 24);

      final update = buildUpdate(
        current: _match(status: ScheduleMatchStatus.scheduled),
        input: const DoublesMatchProgressInput(
          status: ScheduleMatchStatus.inProgress,
          side1Score: null,
          side2Score: null,
          note: '',
          startedAt: null,
          finishedAt: null,
        ),
        now: now,
      );

      expect(update.status, ScheduleMatchStatus.inProgress);
      expect(update.startedAt, now);
      expect(update.finishedAt, isNull);
    });

    test('completes a match while preserving its start time', () {
      final startedAt = DateTime(2026, 7, 31, 15, 24);
      final now = DateTime(2026, 7, 31, 15, 41);

      final update = buildUpdate(
        current: _match(
          status: ScheduleMatchStatus.inProgress,
          startedAt: startedAt,
        ),
        input: const DoublesMatchProgressInput(
          status: ScheduleMatchStatus.completed,
          side1Score: 4,
          side2Score: 2,
          note: 'final',
          startedAt: null,
          finishedAt: null,
        ),
        now: now,
      );

      expect(update.startedAt, startedAt);
      expect(update.finishedAt, now);
      expect(update.result?.type, ScheduleMatchResultSummary.simpleScoreType);
      expect(update.result?.sideScores, <int>[4, 2]);
      expect(update.note, 'final');
    });

    test('clears the finish time when returning to in progress', () {
      final startedAt = DateTime(2026, 7, 31, 15, 24);
      final finishedAt = DateTime(2026, 7, 31, 15, 41);

      final update = buildUpdate(
        current: _match(
          status: ScheduleMatchStatus.completed,
          startedAt: startedAt,
          finishedAt: finishedAt,
        ),
        input: DoublesMatchProgressInput(
          status: ScheduleMatchStatus.inProgress,
          side1Score: 4,
          side2Score: 2,
          note: '',
          startedAt: startedAt,
          finishedAt: finishedAt,
        ),
        now: DateTime(2026, 7, 31, 15, 50),
      );

      expect(update.startedAt, startedAt);
      expect(update.finishedAt, isNull);
    });

    test('clears times when returning to scheduled', () {
      final update = buildUpdate(
        current: _match(
          status: ScheduleMatchStatus.completed,
          startedAt: DateTime(2026, 7, 31, 15, 24),
          finishedAt: DateTime(2026, 7, 31, 15, 41),
        ),
        input: DoublesMatchProgressInput(
          status: ScheduleMatchStatus.scheduled,
          side1Score: null,
          side2Score: null,
          note: '',
          startedAt: DateTime(2026, 7, 31, 15, 24),
          finishedAt: DateTime(2026, 7, 31, 15, 41),
        ),
        now: DateTime(2026, 7, 31, 15, 50),
      );

      expect(update.startedAt, isNull);
      expect(update.finishedAt, isNull);
    });

    test('allows completed status without scores', () {
      final update = buildUpdate(
        current: _match(status: ScheduleMatchStatus.scheduled),
        input: const DoublesMatchProgressInput(
          status: ScheduleMatchStatus.completed,
          side1Score: null,
          side2Score: null,
          note: '',
          startedAt: null,
          finishedAt: null,
        ),
        now: DateTime(2026, 7, 31, 15, 41),
      );

      expect(update.result, isNull);
      expect(update.status, ScheduleMatchStatus.completed);
    });

    test('rejects a score entered on one side only', () {
      expect(
        () => buildUpdate(
          current: _match(status: ScheduleMatchStatus.scheduled),
          input: const DoublesMatchProgressInput(
            status: ScheduleMatchStatus.completed,
            side1Score: 4,
            side2Score: null,
            note: '',
            startedAt: null,
            finishedAt: null,
          ),
          now: DateTime(2026, 7, 31, 15, 41),
        ),
        throwsA(isA<DoublesMatchIncompleteScoreException>()),
      );
    });

    test('rejects scores outside zero through nine', () {
      expect(
        () => buildUpdate(
          current: _match(status: ScheduleMatchStatus.scheduled),
          input: const DoublesMatchProgressInput(
            status: ScheduleMatchStatus.completed,
            side1Score: 10,
            side2Score: 0,
            note: '',
            startedAt: null,
            finishedAt: null,
          ),
          now: DateTime(2026, 7, 31, 15, 41),
        ),
        throwsA(isA<DoublesMatchScoreRangeException>()),
      );
    });

    test('rejects an end time earlier than the start time', () {
      expect(
        () => buildUpdate(
          current: _match(status: ScheduleMatchStatus.completed),
          input: DoublesMatchProgressInput(
            status: ScheduleMatchStatus.completed,
            side1Score: 4,
            side2Score: 2,
            note: '',
            startedAt: DateTime(2026, 7, 31, 15, 41),
            finishedAt: DateTime(2026, 7, 31, 15, 24),
          ),
          now: DateTime(2026, 7, 31, 15, 50),
        ),
        throwsA(isA<DoublesMatchTimeOrderException>()),
      );
    });
  });

  test('save uses the latest match revision and returns the summary', () async {
    final current = _match(
      status: ScheduleMatchStatus.inProgress,
      revision: 3,
      startedAt: DateTime(2026, 7, 31, 15, 24),
    );
    final repository = _FakeScheduleProgressRepository(
      savedMatch: _match(
        status: ScheduleMatchStatus.completed,
        revision: 4,
        startedAt: DateTime(2026, 7, 31, 15, 24),
        finishedAt: DateTime(2026, 7, 31, 15, 41),
      ),
      summary: _summary(revision: 2),
    );
    final service = DoublesMatchProgressService(
      repository: repository,
      clock: () => DateTime(2026, 7, 31, 15, 41),
    );

    final result = await service.save(
      scope: _scope(),
      current: current,
      input: const DoublesMatchProgressInput(
        status: ScheduleMatchStatus.completed,
        side1Score: 4,
        side2Score: 2,
        note: '',
        startedAt: null,
        finishedAt: null,
      ),
      totalMatchCount: 15,
    );

    expect(repository.expectedRevision, 3);
    expect(repository.totalMatchCount, 15);
    expect(result.match.revision, 4);
    expect(result.summary.revision, 2);
  });

  group('countDoublesScheduleMatches', () {
    test('counts all courts in all rounds', () {
      expect(
        countDoublesScheduleMatches(<String, dynamic>{
          'rounds': <Map<String, dynamic>>[
            <String, dynamic>{'courts': <Object>[{}, {}]},
            <String, dynamic>{'courts': <Object>[{}]},
          ],
        }),
        3,
      );
    });

    test('returns zero for missing schedule data', () {
      expect(countDoublesScheduleMatches(null), 0);
      expect(countDoublesScheduleMatches(const <String, dynamic>{}), 0);
    });
  });
}

ScheduleProgressScope _scope() {
  return ScheduleProgressScope(
    scheduleType: ScheduleProgressScheduleType.doubles,
    shareId: 'ABC123',
    generatedScheduleId: 'generated-1',
  );
}

ScheduleMatchProgress _match({
  required ScheduleMatchStatus status,
  int revision = 1,
  DateTime? startedAt,
  DateTime? finishedAt,
}) {
  final createdAt = DateTime.utc(2026, 7, 31, 1);
  return ScheduleMatchProgress(
    schemaVersion: ScheduleMatchProgress.currentSchemaVersion,
    scheduleType: ScheduleProgressScheduleType.doubles,
    generatedScheduleId: 'generated-1',
    roundNo: 1,
    courtNo: 1,
    matchNo: null,
    status: status,
    result: null,
    note: '',
    startedAt: startedAt,
    finishedAt: finishedAt,
    createdAt: createdAt,
    updatedAt: createdAt,
    revision: revision,
  );
}

ScheduleProgressSummary _summary({required int revision}) {
  final now = DateTime.utc(2026, 7, 31, 1);
  return ScheduleProgressSummary(
    schemaVersion: ScheduleProgressSummary.currentSchemaVersion,
    scheduleType: ScheduleProgressScheduleType.doubles,
    generatedScheduleId: 'generated-1',
    totalMatchCount: 15,
    completedMatchCount: 1,
    inProgressMatchCount: 0,
    createdAt: now,
    updatedAt: now,
    revision: revision,
  );
}

class _FakeScheduleProgressRepository implements ScheduleProgressRepository {
  _FakeScheduleProgressRepository({
    required this.savedMatch,
    required this.summary,
  });

  final ScheduleMatchProgress savedMatch;
  final ScheduleProgressSummary summary;
  int? expectedRevision;
  int? totalMatchCount;

  @override
  Future<ScheduleProgressSummary?> findSummary(
    ScheduleProgressScope scope,
  ) async {
    return summary;
  }

  @override
  Future<ScheduleMatchProgress> saveMatch({
    required ScheduleProgressScope scope,
    required ScheduleMatchProgressUpdate update,
    required int totalMatchCount,
    required int expectedRevision,
  }) async {
    this.totalMatchCount = totalMatchCount;
    this.expectedRevision = expectedRevision;
    return savedMatch;
  }

  @override
  Future<ScheduleProgressSummary> ensureSummary({
    required ScheduleProgressScope scope,
    required int totalMatchCount,
  }) {
    throw UnimplementedError();
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
  Future<List<ScheduleMatchProgress>> listMatches(
    ScheduleProgressScope scope,
  ) {
    throw UnimplementedError();
  }
}
