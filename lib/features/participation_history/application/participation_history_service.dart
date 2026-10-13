import '../../external_identity/application/external_identity_user_reader.dart';
import '../../external_identity/domain/external_identity.dart';
import '../domain/participation_history_entry.dart';
import 'participation_history_repository.dart';

class ParticipationHistoryResult {
  const ParticipationHistoryResult.unlinked()
      : linked = false,
        entries = const [];
  const ParticipationHistoryResult.linked(this.entries) : linked = true;

  final bool linked;
  final List<ParticipationHistoryEntry> entries;
}

/// Resolves approved identity before reading its private history.
class ParticipationHistoryService {
  const ParticipationHistoryService({
    required ExternalIdentityUserReader identityReader,
    required ParticipationHistoryRepository historyRepository,
  })  : _identityReader = identityReader,
        _historyRepository = historyRepository;

  final ExternalIdentityUserReader _identityReader;
  final ParticipationHistoryRepository _historyRepository;

  Future<ParticipationHistoryResult> loadForUser({
    required String lanskeUserId,
    int limit = 20,
  }) async {
    final mapping = await _identityReader.getActiveMapping(
      lanskeUserId: lanskeUserId,
      sourceType: ExternalIdentitySourceType.tennisbear,
    );
    if (mapping == null) return const ParticipationHistoryResult.unlinked();
    final entries = await _historyRepository.listByMappingId(
      mappingId: mapping.id,
      limit: limit,
    );
    return ParticipationHistoryResult.linked(entries);
  }

  Future<List<ParticipationHistoryEntry>> listForUser({
    required String lanskeUserId,
    int limit = 20,
  }) async {
    return (await loadForUser(lanskeUserId: lanskeUserId, limit: limit))
        .entries;
  }
}
