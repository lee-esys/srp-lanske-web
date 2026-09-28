abstract interface class EventOwnershipTransferRepository {
  Future<void> prepare({
    required String sourceUid,
    required String handoffSecret,
    required DateTime expiresAt,
  });

  Future<void> accept({
    required String sourceUid,
    required String handoffSecret,
    required String targetUid,
    required DateTime acceptedExpiresAt,
  });

  Future<void> complete({
    required String sourceUid,
    required String targetUid,
  });
}
