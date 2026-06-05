import '../infrastructure/generated_schedule_api_client.dart';
import '../presentation/models/event_draft.dart';

class GeneratedScheduleService {
  GeneratedScheduleService(this._apiClient);

  final GeneratedScheduleApiClient _apiClient;

  Future<Map<String, dynamic>> generateFromDraft(EventDraft draft) {
    final request = <String, dynamic>{
      'schedule_type': 'doubles',
      'courts': draft.courts,
      'players': draft.players
          .map(
            (player) => <String, dynamic>{
              'player_id': player.id,
              // TODO: core の OpenAPI に合わせて必要項目があればここへ追加
              // 例: display_name, level, gender など
            },
          )
          .toList(growable: false),
    };

    return _apiClient.generate(body: request);
  }

  Future<Map<String, dynamic>> getById(String generatedScheduleId) {
    return _apiClient.getById(generatedScheduleId);
  }

  Future<Map<String, dynamic>> adopt(String generatedScheduleId) {
    // Adoption is represented by the web event/view state.
    // The backend generated schedule snapshot is not mutated here.
    return Future.value(<String, dynamic>{
      'generated_schedule_id': generatedScheduleId,
      'adopted': true,
    });
  }
}
