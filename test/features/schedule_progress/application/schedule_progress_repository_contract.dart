import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/schedule_progress/application/schedule_progress_repository.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';

typedef ScheduleProgressRepositoryFactory = ScheduleProgressRepository Function();

void runScheduleProgressRepositoryContractTests({
  required String name,
  required ScheduleProgressRepositoryFactory createRepository,
}) {
  group(name, () {
    ScheduleProgressScope buildScope({
      ScheduleProgressScheduleType scheduleType =
          ScheduleProgressScheduleType.doubles,
      String shareId = 'PUBLIC01',
      String generatedScheduleId = 'generated-1',
    }) {
      return ScheduleProgressScope(
        scheduleType: scheduleType,
        shareId: shareId,
        generatedScheduleId: generatedScheduleId,
      );
    }

    ScheduleMatchProgressUpdate buildUpdate({
      int roundNo = 1,
      int courtNo = 1,
      int? matchNo,
      ScheduleMatchStatus status = ScheduleMatchStatus.inProgress,
      ScheduleMatchResultSummary? result,
      String note = '',
    }) {
      return ScheduleMatchProgressUpdate(
        roundNo: roundNo,
        courtNo: courtNo,
        matchNo: matchNo,
        status: status,
        result: result,
        note: note,
      );
    }

    test('initializes not-started progress summary', () async {
      final repository = createRepository();
      final scope = buildScope();

      final summary = await repository.ensureSummary(
        scope: scope,
        totalMatchCount: 10,
      );
      final repeated = await repository.ensureSummary(
        scope: scope,
        totalMatchCount: 10,
      );

      expect(summary.totalMatchCount, 10);
      expect(summary.completedMatchCount, 0);
      expect(summary.inProgressMatchCount, 0);
      expect(summary.scheduledMatchCount, 10);
      expect(summary.overallStatus, ScheduleOverallProgressStatus.notStarted);
      expect(summary.revision, 1);
      expect(repeated.revision, 1);
    });

    test('returns scheduled placeholder when match is not saved', () async {
      final repository = createRepository();
      final scope = buildScope();

      final match = await repository.findMatch(
        scope: scope,
        roundNo: 2,
        courtNo: 1,
      );

      expect(match.status, ScheduleMatchStatus.scheduled);
      expect(match.revision, 0);
      expect(match.isPersisted, isFalse);
      expect(match.key.value, 'r2_c1');
      expect(await repository.findSummary(scope), isNull);
    });

    test('saves match and creates progress summary', () async {
      final repository = createRepository();
      final scope = buildScope();

      final saved = await repository.saveMatch(
        scope: scope,
        update: buildUpdate(note: '開始'),
        totalMatchCount: 10,
        expectedRevision: 0,
      );

      expect(saved.status, ScheduleMatchStatus.inProgress);
      expect(saved.note, '開始');
      expect(saved.revision, 1);
      expect(saved.isPersisted, isTrue);

      final summary = await repository.findSummary(scope);
      expect(summary, isNotNull);
      expect(summary!.totalMatchCount, 10);
      expect(summary.completedMatchCount, 0);
      expect(summary.inProgressMatchCount, 1);
      expect(summary.scheduledMatchCount, 9);
      expect(summary.overallStatus, ScheduleOverallProgressStatus.inProgress);
      expect(summary.revision, 1);
    });

    test('updates match and summary counts', () async {
      final repository = createRepository();
      final scope = buildScope();

      final started = await repository.saveMatch(
        scope: scope,
        update: buildUpdate(),
        totalMatchCount: 10,
        expectedRevision: 0,
      );
      final completed = await repository.saveMatch(
        scope: scope,
        update: buildUpdate(
          status: ScheduleMatchStatus.completed,
          result: ScheduleMatchResultSummary.simpleScore([4, 2]),
        ),
        totalMatchCount: 10,
        expectedRevision: started.revision,
      );

      expect(completed.status, ScheduleMatchStatus.completed);
      expect(completed.result!.sideScores, [4, 2]);
      expect(completed.revision, 2);
      expect(completed.createdAt, started.createdAt);

      final summary = await repository.findSummary(scope);
      expect(summary!.completedMatchCount, 1);
      expect(summary.inProgressMatchCount, 0);
      expect(summary.scheduledMatchCount, 9);
      expect(summary.revision, 2);
    });

    test('rejects stale revision without overwriting match', () async {
      final repository = createRepository();
      final scope = buildScope();

      final saved = await repository.saveMatch(
        scope: scope,
        update: buildUpdate(),
        totalMatchCount: 10,
        expectedRevision: 0,
      );

      expect(
        () => repository.saveMatch(
          scope: scope,
          update: buildUpdate(
            status: ScheduleMatchStatus.completed,
          ),
          totalMatchCount: 10,
          expectedRevision: 0,
        ),
        throwsA(
          isA<ScheduleProgressConflictException>()
              .having(
                (error) => error.expectedRevision,
                'expectedRevision',
                0,
              )
              .having(
                (error) => error.actualRevision,
                'actualRevision',
                saved.revision,
              ),
        ),
      );

      final found = await repository.findMatch(
        scope: scope,
        roundNo: 1,
        courtNo: 1,
      );
      expect(found.status, ScheduleMatchStatus.inProgress);
      expect(found.revision, 1);
    });

    test('tracks multiple matches and lists them in display order', () async {
      final repository = createRepository();
      final scope = buildScope();

      await repository.saveMatch(
        scope: scope,
        update: buildUpdate(
          roundNo: 2,
          courtNo: 1,
          status: ScheduleMatchStatus.completed,
        ),
        totalMatchCount: 4,
        expectedRevision: 0,
      );
      await repository.saveMatch(
        scope: scope,
        update: buildUpdate(
          roundNo: 1,
          courtNo: 2,
          status: ScheduleMatchStatus.inProgress,
        ),
        totalMatchCount: 4,
        expectedRevision: 0,
      );
      await repository.saveMatch(
        scope: scope,
        update: buildUpdate(
          roundNo: 1,
          courtNo: 1,
          status: ScheduleMatchStatus.completed,
        ),
        totalMatchCount: 4,
        expectedRevision: 0,
      );

      final matches = await repository.listMatches(scope);
      expect(matches.map((match) => match.key.value), [
        'r1_c1',
        'r1_c2',
        'r2_c1',
      ]);

      final summary = await repository.findSummary(scope);
      expect(summary!.completedMatchCount, 2);
      expect(summary.inProgressMatchCount, 1);
      expect(summary.scheduledMatchCount, 1);
    });

    test('keeps doubles, team, and generated schedules separated', () async {
      final repository = createRepository();
      final doublesScope = buildScope();
      final teamScope = buildScope(
        scheduleType: ScheduleProgressScheduleType.team,
      );
      final regeneratedScope = buildScope(
        generatedScheduleId: 'generated-2',
      );

      await repository.saveMatch(
        scope: doublesScope,
        update: buildUpdate(status: ScheduleMatchStatus.completed),
        totalMatchCount: 5,
        expectedRevision: 0,
      );

      final teamMatch = await repository.findMatch(
        scope: teamScope,
        roundNo: 1,
        courtNo: 1,
      );
      final regeneratedMatch = await repository.findMatch(
        scope: regeneratedScope,
        roundNo: 1,
        courtNo: 1,
      );

      expect(teamMatch.revision, 0);
      expect(regeneratedMatch.revision, 0);
      expect(await repository.findSummary(teamScope), isNull);
      expect(await repository.findSummary(regeneratedScope), isNull);
    });

    test('rejects a changed total match count for the same schedule', () async {
      final repository = createRepository();
      final scope = buildScope();

      await repository.saveMatch(
        scope: scope,
        update: buildUpdate(),
        totalMatchCount: 10,
        expectedRevision: 0,
      );

      expect(
        () => repository.saveMatch(
          scope: scope,
          update: buildUpdate(roundNo: 1, courtNo: 2),
          totalMatchCount: 11,
          expectedRevision: 0,
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
