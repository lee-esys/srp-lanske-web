enum EventOwnershipTransferState {
  pending,
  accepted,
  completed,
}

class EventOwnershipTransferHandoff {
  const EventOwnershipTransferHandoff({
    required this.sourceUid,
    required this.handoffSecret,
    required this.expiresAt,
  });

  final String sourceUid;
  final String handoffSecret;
  final DateTime expiresAt;

  bool isExpired(DateTime now) => !expiresAt.isAfter(now);

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'sourceUid': sourceUid,
      'handoffSecret': handoffSecret,
      'expiresAt': expiresAt.toUtc().toIso8601String(),
    };
  }

  factory EventOwnershipTransferHandoff.fromJson(
    Map<String, dynamic> json,
  ) {
    return EventOwnershipTransferHandoff(
      sourceUid: json['sourceUid']?.toString() ?? '',
      handoffSecret: json['handoffSecret']?.toString() ?? '',
      expiresAt: DateTime.parse(json['expiresAt'].toString()).toUtc(),
    );
  }
}

class EventOwnershipTransferResult {
  const EventOwnershipTransferResult({
    required this.sourceUid,
    required this.targetUid,
    required this.transferredEventCount,
  });

  final String sourceUid;
  final String targetUid;
  final int transferredEventCount;
}

class EventOwnershipTransferRequiredException implements Exception {
  const EventOwnershipTransferRequiredException(this.message);

  final String message;

  @override
  String toString() => 'EventOwnershipTransferRequiredException($message)';
}
