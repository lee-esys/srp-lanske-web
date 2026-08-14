class LocalScheduleHistoryItem {
  const LocalScheduleHistoryItem({
    required this.publicId,
    required this.title,
    required this.courtCount,
    required this.playerCount,
    required this.createdAt,
    required this.firstSavedAt,
    required this.lastOpenedAt,
    this.generatedScheduleId,
    this.isAdopted,
    this.completedMatchCount,
    this.totalMatchCount,
    this.isPendingRemoval = false,
  });

  final String publicId;
  final String title;
  final int courtCount;
  final int playerCount;
  final DateTime createdAt;
  final DateTime firstSavedAt;
  final DateTime lastOpenedAt;
  final String? generatedScheduleId;
  final bool? isAdopted;
  final int? completedMatchCount;
  final int? totalMatchCount;
  final bool isPendingRemoval;

  Map<String, dynamic> toJson() {
    return {
      'public_id': publicId,
      'title': title,
      'court_count': courtCount,
      'player_count': playerCount,
      'created_at': createdAt.toIso8601String(),
      'first_saved_at': firstSavedAt.toIso8601String(),
      'last_opened_at': lastOpenedAt.toIso8601String(),
      'generated_schedule_id': generatedScheduleId,
      'is_adopted': isAdopted,
      'completed_match_count': completedMatchCount,
      'total_match_count': totalMatchCount,
      'is_pending_removal': isPendingRemoval,
    };
  }

  static LocalScheduleHistoryItem fromJson(Map<String, dynamic> json) {
    final rawPlayerCount = json['player_count'] ?? json['participant_count'];
    final fallbackNow = DateTime.now();
    final lastOpenedAt =
        DateTime.tryParse(json['last_opened_at'] as String? ?? '') ??
            fallbackNow;
    final firstSavedAt =
        DateTime.tryParse(json['first_saved_at'] as String? ?? '') ??
            lastOpenedAt;
    final createdAt =
        DateTime.tryParse(json['created_at'] as String? ?? '') ?? firstSavedAt;
    final rawGeneratedScheduleId = json['generated_schedule_id'] as String?;
    final generatedScheduleId = rawGeneratedScheduleId?.trim();

    return LocalScheduleHistoryItem(
      publicId: json['public_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled match table',
      courtCount: json['court_count'] as int? ?? 0,
      playerCount: rawPlayerCount as int? ?? 0,
      createdAt: createdAt,
      firstSavedAt: firstSavedAt,
      lastOpenedAt: lastOpenedAt,
      generatedScheduleId:
          generatedScheduleId == null || generatedScheduleId.isEmpty
              ? null
              : generatedScheduleId,
      isAdopted: json['is_adopted'] as bool?,
      completedMatchCount: json['completed_match_count'] as int?,
      totalMatchCount: json['total_match_count'] as int?,
      isPendingRemoval: json['is_pending_removal'] as bool? ?? false,
    );
  }
}
