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
}
