import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/participation_history/infrastructure/firestore_participation_history_repository.dart';

void main() {
  final updatedAt = Timestamp.fromDate(DateTime.utc(2026, 10, 8));
  Map<String, dynamic> valid() => <String, dynamic>{
        'schemaVersion': 1,
        'eventId': 'event-uuid',
        'sourceType': 'tennisbear',
        'sourceUserId': '899212',
        'eventDate': null,
        'selfSnapshot': <String, dynamic>{
          'sourceDisplayName': 'Guest B',
          'levelId': 4,
          'levelName': 'Lv4',
          'observedAt': updatedAt,
        },
        'statisticsEligible': false,
        'updatedAt': updatedAt,
      };

  test('parses privacy-safe history without share or owner fields', () {
    final entry = parseParticipationHistoryEntry(
      eventId: 'event-uuid',
      mappingId: 'tennisbear_899212',
      data: valid(),
    );
    expect(entry.eventId, 'event-uuid');
    expect(entry.selfSnapshot?.sourceDisplayName, 'Guest B');
    expect(entry.eventDate, isNull);
    expect(entry.statisticsEligible, isFalse);
  });

  test('rejects share capability and unrelated fields', () {
    final data = valid()..['publicId'] = 'SHAREID1';
    expect(
      () => parseParticipationHistoryEntry(
        eventId: 'event-uuid',
        mappingId: 'tennisbear_899212',
        data: data,
      ),
      throwsFormatException,
    );
  });

  test('rejects identity mismatch and invalid nested snapshot', () {
    final mismatch = valid()..['sourceUserId'] = '1234';
    expect(
      () => parseParticipationHistoryEntry(
        eventId: 'event-uuid',
        mappingId: 'tennisbear_899212',
        data: mismatch,
      ),
      throwsFormatException,
    );

    final snapshot = valid()
      ..['selfSnapshot'] = {'sourceDisplayName': 'B', 'imageUrl': 'secret'};
    expect(
      () => parseParticipationHistoryEntry(
        eventId: 'event-uuid',
        mappingId: 'tennisbear_899212',
        data: snapshot,
      ),
      throwsFormatException,
    );
  });
}
