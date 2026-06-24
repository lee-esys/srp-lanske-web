class LocalTeamScheduleHistoryItem {
  const LocalTeamScheduleHistoryItem({
    required this.shareId,
    required this.eventTitle,
    required this.teamCount,
    required this.memberCount,
    required this.hasMemo,
    required this.createdAt,
    required this.firstSavedAt,
    required this.updatedAt,
  });

  final String shareId;
  final String eventTitle;
  final int teamCount;
  final int memberCount;
  final bool hasMemo;
  final DateTime createdAt;
  final DateTime firstSavedAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'share_id': shareId,
      'event_title': eventTitle,
      'team_count': teamCount,
      'member_count': memberCount,
      'has_memo': hasMemo,
      'created_at': createdAt.toIso8601String(),
      'first_saved_at': firstSavedAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static LocalTeamScheduleHistoryItem fromJson(Map<String, dynamic> json) {
    final firstSavedAt =
        DateTime.tryParse(json['first_saved_at'] as String? ?? '') ??
            DateTime.now();
    final updatedAt = DateTime.tryParse(json['updated_at'] as String? ?? '') ??
        DateTime.tryParse(json['last_opened_at'] as String? ?? '') ??
        DateTime.now();

    return LocalTeamScheduleHistoryItem(
      shareId: (json['share_id'] as String? ?? '').trim().toUpperCase(),
      eventTitle: json['event_title'] as String? ?? '',
      teamCount: json['team_count'] as int? ?? 0,
      memberCount: json['member_count'] as int? ?? 0,
      hasMemo: json['has_memo'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          firstSavedAt,
      firstSavedAt: firstSavedAt,
      updatedAt: updatedAt,
    );
  }

  LocalTeamScheduleHistoryItem copyWith({
    String? shareId,
    String? eventTitle,
    int? teamCount,
    int? memberCount,
    bool? hasMemo,
    DateTime? createdAt,
    DateTime? firstSavedAt,
    DateTime? updatedAt,
  }) {
    return LocalTeamScheduleHistoryItem(
      shareId: shareId ?? this.shareId,
      eventTitle: eventTitle ?? this.eventTitle,
      teamCount: teamCount ?? this.teamCount,
      memberCount: memberCount ?? this.memberCount,
      hasMemo: hasMemo ?? this.hasMemo,
      createdAt: createdAt ?? this.createdAt,
      firstSavedAt: firstSavedAt ?? this.firstSavedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
