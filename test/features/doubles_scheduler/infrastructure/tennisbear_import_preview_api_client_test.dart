import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/infrastructure/tennisbear_import_preview_api_client.dart';

void main() {
  test('parses partial import warning codes from preview response', () {
    final response = TennisbearImportPreviewResponse.fromJson(
      <String, dynamic>{
        'source_type': 'tennisbear',
        'source_url': 'https://www.tennisbear.net/event/1645753/info',
        'source_event_id': '1645753',
        'participant_candidates': <Object?>[],
        'warnings': <Object?>[
          <String, dynamic>{
            'code': tennisbearImportWarningEventTitleMissing,
            'message': 'failed to import tennisbear event title',
            'target': 'https://www.tennisbear.net/event/1645753/info',
          },
          <String, dynamic>{
            'code': tennisbearImportWarningParticipantDisplayNamesMissing,
            'message':
                'failed to import all tennisbear participant display names',
            'target': 'https://www.tennisbear.net/event/1645753/info',
          },
        ],
      },
    );

    expect(
      response.warnings.map((warning) => warning.code),
      <String>[
        tennisbearImportWarningEventTitleMissing,
        tennisbearImportWarningParticipantDisplayNamesMissing,
      ],
    );
  });

  test('parses participant identity and profile metadata', () {
    final response = TennisbearImportPreviewResponse.fromJson(
      <String, dynamic>{
        'source_type': 'tennisbear',
        'source_url': 'https://www.tennisbear.net/event/1645753/info',
        'source_event_id': '1645753',
        'participant_candidates': <Object?>[
          <String, dynamic>{
            'display_name': 'Ryosuke',
            'order_no': 2,
            'status': 'active',
            'user_id': '59169',
            'profile_url': 'https://www.tennisbear.net/user/59169/info',
            'image_url': 'https://example.com/59169.jpg',
            'level_id': 4,
            'level_name': '初中級',
            'gender': '男性',
            'age_group': '30代',
            'pickleball_level_name': '非公開',
            'source_status': 'APPROVE',
            'is_guest': false,
            'source_text': 'Ryosuke',
          },
        ],
      },
    );

    expect(response.participantCandidates, hasLength(1));

    final participant = response.participantCandidates.single;
    expect(participant.displayName, 'Ryosuke');
    expect(participant.userId, '59169');
    expect(
      participant.profileUrl,
      'https://www.tennisbear.net/user/59169/info',
    );
    expect(participant.imageUrl, 'https://example.com/59169.jpg');
    expect(participant.levelId, 4);
    expect(participant.levelName, '初中級');
    expect(participant.gender, '男性');
    expect(participant.ageGroup, '30代');
    expect(participant.pickleballLevelId, isNull);
    expect(participant.pickleballLevelName, '非公開');
    expect(participant.sourceStatus, 'APPROVE');
    expect(participant.isGuest, isFalse);
    expect(participant.sourceText, 'Ryosuke');
  });

  test('keeps optional participant metadata nullable when missing', () {
    final response = TennisbearImportPreviewResponse.fromJson(
      <String, dynamic>{
        'source_type': 'tennisbear',
        'source_url': 'https://www.tennisbear.net/event/1645753/info',
        'source_event_id': '1645753',
        'participant_candidates': <Object?>[
          <String, dynamic>{
            'display_name': 'Guest',
            'order_no': 1,
            'status': 'active',
          },
        ],
      },
    );

    final participant = response.participantCandidates.single;
    expect(participant.userId, isEmpty);
    expect(participant.profileUrl, isEmpty);
    expect(participant.levelId, isNull);
    expect(participant.pickleballLevelId, isNull);
    expect(participant.isGuest, isNull);
  });
}
