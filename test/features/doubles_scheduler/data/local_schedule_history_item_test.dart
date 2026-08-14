import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/data/local_schedule_history_item.dart';

void main() {
  test('round trips schedule list metadata', () {
    final item = LocalScheduleHistoryItem(
      publicId: 'ABCDEFGH',
      title: 'Test event',
      courtCount: 2,
      playerCount: 8,
      createdAt: DateTime.utc(2026, 8, 10, 1),
      firstSavedAt: DateTime.utc(2026, 8, 10, 2),
      lastOpenedAt: DateTime.utc(2026, 8, 10, 3),
      generatedScheduleId: 'schedule-1',
      isAdopted: true,
      completedMatchCount: 8,
      totalMatchCount: 12,
      isPendingRemoval: true,
    );

    final restored = LocalScheduleHistoryItem.fromJson(item.toJson());

    expect(restored.generatedScheduleId, 'schedule-1');
    expect(restored.isAdopted, isTrue);
    expect(restored.completedMatchCount, 8);
    expect(restored.totalMatchCount, 12);
    expect(restored.createdAt, item.createdAt);
    expect(restored.isPendingRemoval, isTrue);
  });

  test('keeps new metadata compatible for legacy history', () {
    final restored = LocalScheduleHistoryItem.fromJson({
      'public_id': 'ABCDEFGH',
      'title': 'Legacy event',
      'court_count': 1,
      'player_count': 6,
      'created_at': '2026-08-10T01:00:00.000Z',
      'first_saved_at': '2026-08-10T02:00:00.000Z',
      'last_opened_at': '2026-08-10T03:00:00.000Z',
    });

    expect(restored.generatedScheduleId, isNull);
    expect(restored.isAdopted, isNull);
    expect(restored.completedMatchCount, isNull);
    expect(restored.totalMatchCount, isNull);
    expect(restored.isPendingRemoval, isFalse);
  });

  test('uses last opened time as stable legacy created-at fallback', () {
    final restored = LocalScheduleHistoryItem.fromJson({
      'public_id': 'ABCDEFGH',
      'title': 'Legacy event',
      'court_count': 1,
      'participant_count': 6,
      'last_opened_at': '2026-08-10T03:00:00.000Z',
    });

    final expected = DateTime.parse('2026-08-10T03:00:00.000Z');
    expect(restored.createdAt, expected);
    expect(restored.firstSavedAt, expected);
    expect(restored.lastOpenedAt, expected);
    expect(restored.playerCount, 6);
  });
}
