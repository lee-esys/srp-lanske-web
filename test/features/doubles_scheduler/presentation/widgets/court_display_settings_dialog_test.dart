import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/event_repository.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/saved_event_models.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/models/event_draft.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/widgets/court_display_settings_dialog.dart';
import 'package:srp_lanske/l10n/l10n.dart';

void main() {
  testWidgets('saves court settings with the supplied fragment revision',
      (tester) async {
    final aggregate = _aggregate();
    final repository = _FakeEventRepository(aggregate);
    SavedEventAggregate? result;

    await _openDialog(
      tester,
      repository,
      aggregate,
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('A / B'));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, '決定'));
    await tester.pumpAndSettle();

    expect(repository.expectedRevisions, <int>[1]);
    expect(result, isNotNull);
    expect(
      result!.courtSettings.map((setting) => setting.displayLabel),
      <String>['A', 'B'],
    );
  });

  testWidgets('keeps draft and retries with latest revision after conflict',
      (tester) async {
    final aggregate = _aggregate();
    final repository = _FakeEventRepository(
      aggregate,
      conflictOnFirstUpdate: true,
    );
    SavedEventAggregate? result;

    await _openDialog(
      tester,
      repository,
      aggregate,
      onResult: (value) => result = value,
    );

    await tester.tap(find.text('任意'));
    await tester.pump();

    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), '左');
    await tester.enterText(fields.at(1), '右');

    await tester.tap(find.widgetWithText(FilledButton, '決定'));
    await tester.pumpAndSettle();

    expect(find.byType(CourtDisplaySettingsDialog), findsOneWidget);
    expect(find.text('左'), findsOneWidget);
    expect(find.text('右'), findsOneWidget);
    expect(
      find.textContaining('別の端末でコート表示が更新されていました'),
      findsOneWidget,
    );
    expect(repository.expectedRevisions, <int>[1]);

    await tester.tap(find.widgetWithText(FilledButton, '決定'));
    await tester.pumpAndSettle();

    expect(repository.expectedRevisions, <int>[1, 2]);
    expect(result, isNotNull);
    expect(
      result!.courtSettings.map((setting) => setting.displayLabel),
      <String>['左', '右'],
    );
  });
}

Future<void> _openDialog(
  WidgetTester tester,
  EventRepository repository,
  SavedEventAggregate aggregate, {
  ValueChanged<SavedEventAggregate?>? onResult,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ja'),
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () async {
                final result = await showDialog<SavedEventAggregate>(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => CourtDisplaySettingsDialog(
                    initialAggregate: aggregate,
                    repository: repository,
                  ),
                );
                onResult?.call(result);
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    ),
  );

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

SavedEventAggregate _aggregate() {
  final now = DateTime.utc(2026, 9, 29, 1);
  final event = SavedEvent(
    id: 'event-1',
    publicId: 'ABCD1234',
    title: 'イベント',
    courtCount: 2,
    sourceType: EventSourceType.manual,
    sourceUrl: null,
    status: SavedEventStatus.generated,
    currentGeneratedScheduleId: 'generated-1',
    createdAt: now,
    updatedAt: now,
  );

  return SavedEventAggregate(
    event: event,
    players: const <SavedEventPlayer>[],
    share: SavedEventShare(
      publicId: event.publicId,
      eventId: event.id,
      createdAt: now,
      updatedAt: now,
    ),
    revisions: const SavedEventRevisions.initial(),
    courtSettings: <SavedEventCourtSetting>[
      SavedEventCourtSetting(courtNumber: 1, displayLabel: '1'),
      SavedEventCourtSetting(courtNumber: 2, displayLabel: '2'),
    ],
  );
}

class _FakeEventRepository extends EventRepository {
  _FakeEventRepository(
    this.current, {
    this.conflictOnFirstUpdate = false,
  });

  SavedEventAggregate current;
  final bool conflictOnFirstUpdate;
  final List<int> expectedRevisions = <int>[];
  int updateCallCount = 0;

  @override
  Future<SavedEventAggregate?> findByPublicId(String publicId) async {
    return current;
  }

  @override
  Future<SavedEventAggregate> updateCourtSettingsWithRevision({
    required String publicId,
    required int expectedCourtSettingsRevision,
    required List<SavedEventCourtSetting> courtSettings,
  }) async {
    updateCallCount += 1;
    expectedRevisions.add(expectedCourtSettingsRevision);

    if (conflictOnFirstUpdate && updateCallCount == 1) {
      current = _copyCourtSettings(
        current,
        <SavedEventCourtSetting>[
          SavedEventCourtSetting(courtNumber: 1, displayLabel: 'A'),
          SavedEventCourtSetting(courtNumber: 2, displayLabel: 'B'),
        ],
      );
      throw EventRevisionConflictException(
        eventId: current.event.id,
        expectedRevision: expectedCourtSettingsRevision,
        actualRevision: current.revisions.courtSettings,
      );
    }

    current = _copyCourtSettings(current, courtSettings);
    return current;
  }

  @override
  Future<SavedEventAggregate> createFromDraft(
    EventDraft draft, {
    required String ownerUid,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<SavedEventPlayer>> listPlayers(String publicId) {
    throw UnimplementedError();
  }

  @override
  Future<SavedEvent> updateCurrentGeneratedScheduleId({
    required String publicId,
    required String generatedScheduleId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SavedEvent> updateAdoptedGeneratedScheduleId({
    required String publicId,
    required String generatedScheduleId,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<SavedEventAggregate> updateCourtSettings({
    required String publicId,
    required List<SavedEventCourtSetting> courtSettings,
  }) {
    throw UnimplementedError();
  }
}

SavedEventAggregate _copyCourtSettings(
  SavedEventAggregate source,
  List<SavedEventCourtSetting> courtSettings,
) {
  return SavedEventAggregate(
    event: source.event.copyWith(
      revision: source.event.revision + 1,
      updatedAt: source.event.updatedAt.add(const Duration(minutes: 1)),
    ),
    players: source.players,
    share: source.share,
    importRecord: source.importRecord,
    revisions: source.revisions.copyWith(
      courtSettings: source.revisions.courtSettings + 1,
    ),
    courtSettings: courtSettings,
  );
}
