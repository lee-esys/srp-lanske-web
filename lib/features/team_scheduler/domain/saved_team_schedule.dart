import 'dart:convert';

class SavedTeamSchedule {
  const SavedTeamSchedule({
    required this.schemaVersion,
    required this.shareId,
    required this.status,
    required this.scheduleType,
    required this.createdAt,
    required this.updatedAt,
    required this.setup,
    required this.display,
    required this.snapshot,
    required this.scores,
  });

  static const int currentSchemaVersion = 1;
  static const String teamScheduleType = 'team';

  factory SavedTeamSchedule.fromJson(Map<String, dynamic> json) {
    return SavedTeamSchedule(
      schemaVersion: _readInt(json, 'schema_version', defaultValue: 1),
      shareId: _readString(json, 'share_id'),
      status: _readString(json, 'status', defaultValue: 'active'),
      scheduleType: _readString(
        json,
        'schedule_type',
        defaultValue: teamScheduleType,
      ),
      createdAt: _readDateTime(json, 'created_at'),
      updatedAt: _readDateTime(json, 'updated_at'),
      setup: SavedTeamScheduleSetup.fromJson(_readObject(json, 'setup')),
      display: SavedTeamScheduleDisplay.fromJson(_readObject(json, 'display')),
      snapshot: _readObject(json, 'snapshot'),
      scores: _readObject(json, 'scores'),
    );
  }

  final int schemaVersion;
  final String shareId;
  final String status;
  final String scheduleType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SavedTeamScheduleSetup setup;
  final SavedTeamScheduleDisplay display;
  final Map<String, dynamic> snapshot;
  final Map<String, dynamic> scores;

  SavedTeamSchedule copyWith({
    int? schemaVersion,
    String? shareId,
    String? status,
    String? scheduleType,
    DateTime? createdAt,
    DateTime? updatedAt,
    SavedTeamScheduleSetup? setup,
    SavedTeamScheduleDisplay? display,
    Map<String, dynamic>? snapshot,
    Map<String, dynamic>? scores,
  }) {
    return SavedTeamSchedule(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      shareId: shareId ?? this.shareId,
      status: status ?? this.status,
      scheduleType: scheduleType ?? this.scheduleType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      setup: setup ?? this.setup,
      display: display ?? this.display,
      snapshot: snapshot ?? this.snapshot,
      scores: scores ?? this.scores,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schema_version': schemaVersion,
      'share_id': shareId,
      'status': status,
      'schedule_type': scheduleType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'setup': setup.toJson(),
      'display': display.toJson(),
      'snapshot': _copyObject(snapshot),
      'scores': _copyObject(scores),
    };
  }
}

class SavedTeamScheduleSetup {
  const SavedTeamScheduleSetup({
    required this.concurrentMatchCount,
    required this.participantCount,
    required this.preferredTeamSize,
    required this.teamsPerMatch,
    required this.roundCount,
  });

  factory SavedTeamScheduleSetup.fromJson(Map<String, dynamic> json) {
    return SavedTeamScheduleSetup(
      concurrentMatchCount: _readInt(json, 'concurrent_match_count'),
      participantCount: _readInt(json, 'participant_count'),
      preferredTeamSize: _readInt(json, 'preferred_team_size'),
      teamsPerMatch: _readInt(json, 'teams_per_match'),
      roundCount: _readInt(json, 'round_count'),
    );
  }

  final int concurrentMatchCount;
  final int participantCount;
  final int preferredTeamSize;
  final int teamsPerMatch;
  final int roundCount;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'concurrent_match_count': concurrentMatchCount,
      'participant_count': participantCount,
      'preferred_team_size': preferredTeamSize,
      'teams_per_match': teamsPerMatch,
      'round_count': roundCount,
    };
  }
}

class SavedTeamScheduleDisplay {
  const SavedTeamScheduleDisplay({
    required this.eventTitle,
    required this.teamNames,
    required this.memberNames,
  });

  factory SavedTeamScheduleDisplay.fromJson(Map<String, dynamic> json) {
    return SavedTeamScheduleDisplay(
      eventTitle: _readString(json, 'event_title'),
      teamNames: _readIntStringMap(json, 'team_names'),
      memberNames: _readIntStringMap(json, 'member_names'),
    );
  }

  final String eventTitle;
  final Map<int, String> teamNames;
  final Map<int, String> memberNames;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'event_title': eventTitle,
      'team_names': _writeIntStringMap(teamNames),
      'member_names': _writeIntStringMap(memberNames),
    };
  }
}

String _readString(
  Map<String, dynamic> json,
  String key, {
  String defaultValue = '',
}) {
  final value = json[key];
  if (value == null) {
    return defaultValue;
  }

  return value.toString();
}

int _readInt(
  Map<String, dynamic> json,
  String key, {
  int defaultValue = 0,
}) {
  return _tryReadInt(json[key]) ?? defaultValue;
}

int? _tryReadInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value);
  }

  return null;
}

DateTime _readDateTime(Map<String, dynamic> json, String key) {
  final value = json[key];

  if (value is DateTime) {
    return value;
  }

  if (value is String && value.isNotEmpty) {
    return DateTime.parse(value);
  }

  try {
    final dynamic converted = value.toDate();
    if (converted is DateTime) {
      return converted;
    }
  } catch (_) {
    // Ignore non-Firestore timestamp-like values.
  }

  throw FormatException('invalid datetime: $key');
}

Map<String, dynamic> _readObject(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is Map) {
    return _copyObject(Map<String, dynamic>.from(value));
  }

  return const <String, dynamic>{};
}

Map<int, String> _readIntStringMap(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! Map) {
    return const <int, String>{};
  }

  final result = <int, String>{};
  for (final entry in value.entries) {
    final parsedKey = _tryReadInt(entry.key);
    final rawValue = entry.value;
    if (parsedKey != null && rawValue != null) {
      result[parsedKey] = rawValue.toString();
    }
  }

  return Map<int, String>.unmodifiable(result);
}

Map<String, String> _writeIntStringMap(Map<int, String> source) {
  return Map<String, String>.unmodifiable(
    source.map((key, value) => MapEntry(key.toString(), value)),
  );
}

Map<String, dynamic> _copyObject(Map<String, dynamic> source) {
  return jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
}
