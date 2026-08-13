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

  test('retains the 20 most recently opened items', () async {
    final store = LocalScheduleHistoryStore();

    for (var i = 0; i < 21; i += 1) {
      await store.upsert(
        _item(
          publicId: 'ID$i',
          createdAt: DateTime(2026, 8, 1).add(Duration(days: i)),
          lastOpenedAt: DateTime(2026, 8, 1).add(Duration(hours: i)),
        ),
      );
    }

    final items = await store.findAll();

    expect(items, hasLength(20));
    expect(items.any((item) => item.publicId == 'ID0'), isFalse);
  });

  test('upsert preserves progress for the same generated schedule', () async {
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
  });

  test('upsert clears stale progress when generated schedule changes', () async {
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
  );
}
