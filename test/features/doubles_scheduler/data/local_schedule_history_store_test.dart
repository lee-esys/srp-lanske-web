import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srp_lanske/features/doubles_scheduler/data/local_schedule_history_item.dart';
import 'package:srp_lanske/features/doubles_scheduler/data/local_schedule_history_store.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(const {});
  });

  test('findAll sorts by createdAt instead of lastOpenedAt', () async {
    final store = LocalScheduleHistoryStore();
    await store.upsert(
      _item(
        publicId: 'OLDER',
        createdAt: DateTime(2026, 8, 10),
        lastOpenedAt: DateTime(2026, 8, 14),
      ),
    );
    await store.upsert(
      _item(
        publicId: 'NEWER',
        createdAt: DateTime(2026, 8, 13),
        lastOpenedAt: DateTime(2026, 8, 13),
      ),
    );

    final items = await store.findAll();

    expect(items.map((item) => item.publicId), ['NEWER', 'OLDER']);
  });

  test('shows 20 items while retaining older history for later display', () async {
    final store = LocalScheduleHistoryStore();
    await store.upsert(
      _item(
        publicId: 'CONFIRMED',
        createdAt: DateTime(2026, 8, 1),
        lastOpenedAt: DateTime(2026, 8, 1),
        isAdopted: true,
      ),
    );

    for (var i = 0; i < 20; i += 1) {
      await store.upsert(
        _item(
          publicId: 'UNCONFIRMED$i',
          createdAt: DateTime(2026, 8, 2).add(Duration(hours: i)),
          lastOpenedAt: DateTime(2026, 8, 2).add(Duration(hours: i)),
          isAdopted: false,
        ),
      );
    }

    final visible = await store.findAll();
    expect(visible, hasLength(20));
    expect(visible.any((item) => item.publicId == 'CONFIRMED'), isFalse);

    await store.setPendingRemovalForPublicIds(
      visible.map((item) => item.publicId),
      isPendingRemoval: true,
    );
    expect((await store.findAll()).every((item) => item.isPendingRemoval), isTrue);

    final suppressedCount = await store.suppressPendingRemoval();
    expect(suppressedCount, 20);

    final remaining = await store.findAll();
    expect(remaining, hasLength(1));
    expect(remaining.single.publicId, 'CONFIRMED');
  });

  test('upsert preserves progress and pending state for the same schedule',
      () async {
    final store = LocalScheduleHistoryStore();
    await store.upsert(
      _item(
        publicId: 'ABCDEFGH',
        createdAt: DateTime(2026, 8, 10),
        lastOpenedAt: DateTime(2026, 8, 10),
        generatedScheduleId: 'schedule-1',
        isAdopted: true,
        completedMatchCount: 4,
        totalMatchCount: 12,
      ),
    );
    await store.setPendingRemoval(
      publicId: 'ABCDEFGH',
      isPendingRemoval: true,
    );

    await store.upsert(
      _item(
        publicId: 'ABCDEFGH',
        createdAt: DateTime(2026, 8, 10),
        lastOpenedAt: DateTime(2026, 8, 11),
        generatedScheduleId: 'schedule-1',
        isAdopted: true,
      ),
    );

    final item = (await store.findAll()).single;
    expect(item.completedMatchCount, 4);
    expect(item.totalMatchCount, 12);
    expect(item.isPendingRemoval, isTrue);
  });

  test('upsert clears stale progress but preserves pending state after regeneration',
      () async {
    final store = LocalScheduleHistoryStore();
    await store.upsert(
      _item(
        publicId: 'ABCDEFGH',
        createdAt: DateTime(2026, 8, 10),
        lastOpenedAt: DateTime(2026, 8, 10),
        generatedScheduleId: 'schedule-1',
        isAdopted: false,
        completedMatchCount: 4,
        totalMatchCount: 12,
        isPendingRemoval: true,
      ),
    );

    await store.upsert(
      _item(
        publicId: 'ABCDEFGH',
        createdAt: DateTime(2026, 8, 10),
        lastOpenedAt: DateTime(2026, 8, 11),
        generatedScheduleId: 'schedule-2',
        isAdopted: false,
      ),
    );

    final item = (await store.findAll()).single;
    expect(item.generatedScheduleId, 'schedule-2');
    expect(item.completedMatchCount, isNull);
    expect(item.totalMatchCount, isNull);
    expect(item.isPendingRemoval, isTrue);
  });

  test('updateProgress updates matching schedule without changing metadata',
      () async {
    final store = LocalScheduleHistoryStore();
    final createdAt = DateTime(2026, 8, 10);
    final firstSavedAt = DateTime(2026, 8, 10, 1);
    await store.upsert(
      _item(
        publicId: 'ABCDEFGH',
        createdAt: createdAt,
        firstSavedAt: firstSavedAt,
        lastOpenedAt: DateTime(2026, 8, 10, 2),
        generatedScheduleId: 'schedule-1',
        isAdopted: true,
        completedMatchCount: 0,
        totalMatchCount: 12,
        isPendingRemoval: true,
      ),
    );

    final updatedAt = DateTime(2026, 8, 10, 3);
    await store.updateProgress(
      publicId: 'ABCDEFGH',
      generatedScheduleId: 'schedule-1',
      completedMatchCount: 5,
      totalMatchCount: 12,
      lastOpenedAt: updatedAt,
    );

    final item = (await store.findAll()).single;
    expect(item.createdAt, createdAt);
    expect(item.firstSavedAt, firstSavedAt);
    expect(item.lastOpenedAt, updatedAt);
    expect(item.completedMatchCount, 5);
    expect(item.totalMatchCount, 12);
    expect(item.isAdopted, isTrue);
    expect(item.isPendingRemoval, isTrue);
  });

  test('updateProgress ignores a stale generated schedule', () async {
    final store = LocalScheduleHistoryStore();
    await store.upsert(
      _item(
        publicId: 'ABCDEFGH',
        createdAt: DateTime(2026, 8, 10),
        lastOpenedAt: DateTime(2026, 8, 10),
        generatedScheduleId: 'schedule-2',
        isAdopted: false,
      ),
    );

    await store.updateProgress(
      publicId: 'ABCDEFGH',
      generatedScheduleId: 'schedule-1',
      completedMatchCount: 5,
      totalMatchCount: 12,
    );

    final item = (await store.findAll()).single;
    expect(item.generatedScheduleId, 'schedule-2');
    expect(item.completedMatchCount, isNull);
    expect(item.totalMatchCount, isNull);
    expect(item.isAdopted, isFalse);
  });

  test('suppressed history is not restored by normal upsert', () async {
    final store = LocalScheduleHistoryStore();
    final item = _item(
      publicId: 'ABCDEFGH',
      createdAt: DateTime(2026, 8, 10),
      lastOpenedAt: DateTime(2026, 8, 10),
      isAdopted: false,
    );
    await store.upsert(item);
    await store.setPendingRemoval(
      publicId: item.publicId,
      isPendingRemoval: true,
    );
    expect(await store.suppressPendingRemoval(), 1);
    expect(await store.findAll(), isEmpty);

    await store.upsert(
      _item(
        publicId: 'ABCDEFGH',
        createdAt: DateTime(2026, 8, 10),
        lastOpenedAt: DateTime(2026, 8, 14),
        isAdopted: true,
      ),
    );

    expect(await store.findAll(), isEmpty);
  });

  test('clearExceptPublicId keeps current history and suppresses the others',
      () async {
    final store = LocalScheduleHistoryStore();
    await store.upsert(
      _item(
        publicId: 'KEEP',
        createdAt: DateTime(2026, 8, 10),
        lastOpenedAt: DateTime(2026, 8, 10),
      ),
    );
    await store.upsert(
      _item(
        publicId: 'OTHER',
        createdAt: DateTime(2026, 8, 11),
        lastOpenedAt: DateTime(2026, 8, 11),
      ),
    );

    await store.clearExceptPublicId('KEEP');

    final remaining = await store.findAll();
    expect(remaining.map((item) => item.publicId), ['KEEP']);

    await store.upsert(
      _item(
        publicId: 'OTHER',
        createdAt: DateTime(2026, 8, 11),
        lastOpenedAt: DateTime(2026, 8, 14),
      ),
    );
    expect((await store.findAll()).map((item) => item.publicId), ['KEEP']);
  });
}

LocalScheduleHistoryItem _item({
  required String publicId,
  required DateTime createdAt,
  required DateTime lastOpenedAt,
  DateTime? firstSavedAt,
  String? generatedScheduleId,
  bool? isAdopted,
  int? completedMatchCount,
  int? totalMatchCount,
  bool isPendingRemoval = false,
}) {
  return LocalScheduleHistoryItem(
    publicId: publicId,
    title: publicId,
    courtCount: 2,
    playerCount: 8,
    createdAt: createdAt,
    firstSavedAt: firstSavedAt ?? createdAt,
    lastOpenedAt: lastOpenedAt,
    generatedScheduleId: generatedScheduleId,
    isAdopted: isAdopted,
    completedMatchCount: completedMatchCount,
    totalMatchCount: totalMatchCount,
    isPendingRemoval: isPendingRemoval,
  );
}
