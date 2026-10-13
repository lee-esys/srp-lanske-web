import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/external_identity/application/external_identity_user_reader.dart';
import 'package:srp_lanske/features/external_identity/domain/external_identity.dart';
import 'package:srp_lanske/features/external_identity/domain/external_identity_link_request.dart';
import 'package:srp_lanske/features/participation_history/application/participation_history_repository.dart';
import 'package:srp_lanske/features/participation_history/application/participation_history_service.dart';
import 'package:srp_lanske/features/participation_history/domain/participation_history_entry.dart';

class _Reader implements ExternalIdentityUserReader {
  _Reader(this.mapping);
  final ExternalIdentityMapping? mapping;

  @override
  Future<ExternalIdentityMapping?> getActiveMapping({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
  }) async => mapping;

  @override
  Future<ExternalIdentityLinkRequest?> getLatestRequest({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
  }) async => null;
}

class _Repository implements ParticipationHistoryRepository {
  _Repository(this.items);
  final List<ParticipationHistoryEntry> items;
  int calls = 0;
  String? mappingId;
  @override
  Future<List<ParticipationHistoryEntry>> listByMappingId({
    required String mappingId,
    int limit = 20,
  }) async {
    calls++;
    this.mappingId = mappingId;
    return items;
  }
}

void main() {
  test('unlinked identity never reads private history', () async {
    final repository = _Repository([]);
    final service = ParticipationHistoryService(
      identityReader: _Reader(null),
      historyRepository: repository,
    );
    final result = await service.loadForUser(lanskeUserId: 'user-1');
    expect(result.linked, isFalse);
    expect(result.entries, isEmpty);
    expect(repository.calls, 0);
  });

  test('approved mapping distinguishes linked empty and uses mapping id',
      () async {
    final now = DateTime.utc(2026, 10, 10);
    final mapping = ExternalIdentityMapping(
      id: 'tennisbear_899212',
      identity: const ExternalIdentity(
        sourceType: ExternalIdentitySourceType.tennisbear,
        sourceUserId: '899212',
        profileUrl: 'https://www.tennisbear.net/user/899212/info',
      ),
      lanskeUserId: 'user-1',
      requestId: 'request-1',
      approvedAt: now,
      createdAt: now,
      updatedAt: now,
    );
    final repository = _Repository([]);
    final service = ParticipationHistoryService(
      identityReader: _Reader(mapping),
      historyRepository: repository,
    );
    final result = await service.loadForUser(lanskeUserId: 'user-1');
    expect(result.linked, isTrue);
    expect(result.entries, isEmpty);
    expect(repository.calls, 1);
    expect(repository.mappingId, 'tennisbear_899212');
  });
}
