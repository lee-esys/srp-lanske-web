class LocalScheduleHistoryItem {
  const LocalScheduleHistoryItem({
    required this.publicId,
    required this.title,
    required this.courtCount,
    required this.playerCount,
    required this.firstSavedAt,
    required this.lastOpenedAt,
  });

  final String publicId;
  final String title;
  final int courtCount;
  final int playerCount;
  final DateTime firstSavedAt;
  final DateTime lastOpenedAt;

  Map<String, dynamic> toJson() {
    return {
      'public_id': publicId,
      'title': title,
      'court_count': courtCount,
      'player_count': playerCount,
      'first_saved_at': firstSavedAt.toIso8601String(),
      'last_opened_at': lastOpenedAt.toIso8601String(),
    };
  }

  static LocalScheduleHistoryItem fromJson(Map<String, dynamic> json) {
    return LocalScheduleHistoryItem(
      publicId: json['public_id'] as String? ?? '',
      title: json['title'] as String? ?? '無題の対戦表',
      courtCount: json['court_count'] as int? ?? 0,
      playerCount: json['player_count'] as int? ??
          json['participant_count'] as int? ??
          0,
      firstSavedAt:
          DateTime.tryParse(json['first_saved_at'] as String? ?? '') ??
              DateTime.now(),
      lastOpenedAt:
          DateTime.tryParse(json['last_opened_at'] as String? ?? '') ??
              DateTime.now(),
    );
  }
}
