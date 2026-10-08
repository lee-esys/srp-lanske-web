/// Privacy-minimized participation history. This is not an event share grant.
class ParticipationHistoryEntry {
  const ParticipationHistoryEntry({
    required this.eventId,
    required this.sourceType,
    required this.sourceUserId,
    required this.statisticsEligible,
    required this.updatedAt,
    this.eventDate,
    this.selfSnapshot,
  });

  final String eventId;
  final String sourceType;
  final String sourceUserId;
  final DateTime? eventDate;
  final ParticipationSelfSnapshot? selfSnapshot;
  final bool statisticsEligible;
  final DateTime updatedAt;
}

class ParticipationSelfSnapshot {
  const ParticipationSelfSnapshot({
    required this.sourceDisplayName,
    this.levelId,
    this.levelName,
    this.observedAt,
  });

  final String sourceDisplayName;
  final int? levelId;
  final String? levelName;
  final DateTime? observedAt;
}
