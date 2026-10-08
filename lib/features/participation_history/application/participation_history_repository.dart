import '../domain/participation_history_entry.dart';

/// Callers resolve an approved mapping first. Firestore Rules independently
/// check the active mapping for every document read or collection query.
abstract class ParticipationHistoryRepository {
  Future<List<ParticipationHistoryEntry>> listByMappingId({
    required String mappingId,
    int limit = 20,
  });
}
