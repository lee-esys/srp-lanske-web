import '../../external_identity/application/external_identity_user_reader.dart';
import '../../external_identity/domain/external_identity.dart';
import '../domain/participation_history_entry.dart';
import 'participation_history_repository.dart';

/// Resolves approved identity before reading its private history.
class ParticipationHistoryService {
  const ParticipationHistoryService({
    required ExternalIdentityUserReader identityReader,
    required ParticipationHistoryRepository historyRepository,
  })  : _identityReader = identityReader,
        _historyRepository = historyRepository;

  final ExternalIdentityUserReader _identityReader;
  final ParticipationHistoryRepository _historyRepository;

  Future<List<ParticipationHistoryEntry>> listForUser({
    required String lanskeUserId,
    int limit = 20,
  }) async {
    final mapping = await _identityReader.getActiveMapping(
      lanskeUserId: lanskeUserId,
      sourceType: ExternalIdentitySourceType.tennisbear,
    );
    if (mapping == null) return const <ParticipationHistoryEntry>[];
    return _historyRepository.listByMappingId(
      mappingId: mapping.id,
      limit: limit,
    );
  }
}
