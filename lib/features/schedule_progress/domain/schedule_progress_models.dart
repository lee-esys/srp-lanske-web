enum ScheduleProgressScheduleType {
  doubles('doubles'),
  team('team');

  const ScheduleProgressScheduleType(this.value);

  final String value;

  static ScheduleProgressScheduleType fromValue(String value) {
    return ScheduleProgressScheduleType.values.firstWhere(
      (candidate) => candidate.value == value,
      orElse: () => throw FormatException(
        'invalid schedule progress schedule type: $value',
      ),
    );
  }
}

enum ScheduleMatchStatus {
  scheduled('scheduled'),
  inProgress('in_progress'),
  completed('completed');

  const ScheduleMatchStatus(this.value);

  final String value;

  static ScheduleMatchStatus fromValue(String value) {
    return ScheduleMatchStatus.values.firstWhere(
      (candidate) => candidate.value == value,
      orElse: () => throw FormatException(
        'invalid schedule match status: $value',
      ),
    );
  }
}

enum ScheduleOverallProgressStatus {
  notStarted,
  inProgress,
  completed,
}

class ScheduleProgressScope {
  ScheduleProgressScope({
    required this.scheduleType,
    required this.shareId,
    required this.generatedScheduleId,
  }) {
    if (shareId.isEmpty) {
      throw ArgumentError.value(shareId, 'shareId', 'must not be empty');
    }
    if (generatedScheduleId.isEmpty) {
      throw ArgumentError.value(
        generatedScheduleId,
        'generatedScheduleId',
        'must not be empty',
      );
    }
  }

  final ScheduleProgressScheduleType scheduleType;
  final String shareId;
  final String generatedScheduleId;

  String get storageKey {
    return '${scheduleType.value}:$shareId:$generatedScheduleId';
  }
}

class ScheduleMatchKey implements Comparable<ScheduleMatchKey> {
  ScheduleMatchKey({
    required this.roundNo,
    required this.courtNo,
  }) {
    if (roundNo <= 0) {
      throw ArgumentError.value(roundNo, 'roundNo', 'must be positive');
    }
    if (courtNo <= 0) {
      throw ArgumentError.value(courtNo, 'courtNo', 'must be positive');
    }
  }

  final int roundNo;
  final int courtNo;

  String get value => 'r${roundNo}_c$courtNo';

  @override
  int compareTo(ScheduleMatchKey other) {
    final roundComparison = roundNo.compareTo(other.roundNo);
    if (roundComparison != 0) {
      return roundComparison;
    }

    return courtNo.compareTo(other.courtNo);
  }

  @override
  bool operator ==(Object other) {
    return other is ScheduleMatchKey &&
        other.roundNo == roundNo &&
        other.courtNo == courtNo;
  }

  @override
  int get hashCode => Object.hash(roundNo, courtNo);

  @override
  String toString() => value;
}

class ScheduleMatchResultSummary {
  ScheduleMatchResultSummary({
    required this.type,
    required List<int> sideScores,
  }) : sideScores = List<int>.unmodifiable(sideScores) {
    if (type.isEmpty) {
      throw ArgumentError.value(type, 'type', 'must not be empty');
    }
    if (sideScores.length < 2) {
      throw ArgumentError.value(
        sideScores,
        'sideScores',
        'must contain at least two scores',
      );
    }
    if (sideScores.any((score) => score < 0)) {
      throw ArgumentError.value(
        sideScores,
        'sideScores',
        'must not contain negative scores',
      );
    }
  }

  static const String simpleScoreType = 'simple_score';

  factory ScheduleMatchResultSummary.simpleScore(List<int> sideScores) {
    return ScheduleMatchResultSummary(
      type: simpleScoreType,
      sideScores: sideScores,
    );
  }

  factory ScheduleMatchResultSummary.fromJson(Map<String, dynamic> json) {
    return ScheduleMatchResultSummary(
      type: _readString(json, 'type'),
      sideScores: _readIntList(json, 'side_scores'),
    );
  }

  final String type;
  final List<int> sideScores;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'type': type,
      'side_scores': List<int>.from(sideScores),
    };
  }
}

class ScheduleMatchProgress {
  ScheduleMatchProgress({
    required this.schemaVersion,
    required this.scheduleType,
    required this.generatedScheduleId,
    required this.roundNo,
    required this.courtNo,
    required this.matchNo,
    required this.status,
    required this.result,
    required this.note,
    required this.startedAt,
    required this.finishedAt,
    required this.createdAt,
    required this.updatedAt,
    required this.revision,
  }) {
    ScheduleMatchKey(roundNo: roundNo, courtNo: courtNo);
    if (generatedScheduleId.isEmpty) {
      throw ArgumentError.value(
        generatedScheduleId,
        'generatedScheduleId',
        'must not be empty',
      );
    }
    if (matchNo != null && matchNo! <= 0) {
      throw ArgumentError.value(matchNo, 'matchNo', 'must be positive');
    }
    if (revision < 0) {
      throw ArgumentError.value(revision, 'revision', 'must not be negative');
    }
    if (revision == 0 && (createdAt != null || updatedAt != null)) {
      throw ArgumentError('unpersisted match must not have timestamps');
    }
    if (revision > 0 && (createdAt == null || updatedAt == null)) {
      throw ArgumentError('persisted match must have timestamps');
    }
  }

  static const int currentSchemaVersion = 1;

  factory ScheduleMatchProgress.scheduledPlaceholder({
    required ScheduleProgressScope scope,
    required int roundNo,
    required int courtNo,
    int? matchNo,
  }) {
    return ScheduleMatchProgress(
      schemaVersion: currentSchemaVersion,
      scheduleType: scope.scheduleType,
      generatedScheduleId: scope.generatedScheduleId,
      roundNo: roundNo,
      courtNo: courtNo,
      matchNo: matchNo,
      status: ScheduleMatchStatus.scheduled,
      result: null,
      note: '',
      startedAt: null,
      finishedAt: null,
      createdAt: null,
      updatedAt: null,
      revision: 0,
    );
  }

  factory ScheduleMatchProgress.fromJson(Map<String, dynamic> json) {
    final resultJson = _readOptionalObject(json, 'result');

    return ScheduleMatchProgress(
      schemaVersion: _readInt(
        json,
        'schema_version',
        defaultValue: currentSchemaVersion,
      ),
      scheduleType: ScheduleProgressScheduleType.fromValue(
        _readString(json, 'schedule_type'),
      ),
      generatedScheduleId: _readString(json, 'generated_schedule_id'),
      roundNo: _readInt(json, 'round_no'),
      courtNo: _readInt(json, 'court_no'),
      matchNo: _readOptionalInt(json, 'match_no'),
      status: ScheduleMatchStatus.fromValue(_readString(json, 'status')),
      result: resultJson == null
          ? null
          : ScheduleMatchResultSummary.fromJson(resultJson),
      note: _readString(json, 'note', defaultValue: ''),
      startedAt: _readOptionalDateTime(json, 'started_at'),
      finishedAt: _readOptionalDateTime(json, 'finished_at'),
      createdAt: _readDateTime(json, 'created_at'),
      updatedAt: _readDateTime(json, 'updated_at'),
      revision: _readInt(json, 'revision'),
    );
  }

  final int schemaVersion;
  final ScheduleProgressScheduleType scheduleType;
  final String generatedScheduleId;
  final int roundNo;
  final int courtNo;
  final int? matchNo;
  final ScheduleMatchStatus status;
  final ScheduleMatchResultSummary? result;
  final String note;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int revision;

  ScheduleMatchKey get key {
    return ScheduleMatchKey(roundNo: roundNo, courtNo: courtNo);
  }

  bool get isPersisted => revision > 0;

  Map<String, dynamic> toJson() {
    final persistedCreatedAt = createdAt;
    final persistedUpdatedAt = updatedAt;
    if (!isPersisted ||
        persistedCreatedAt == null ||
        persistedUpdatedAt == null) {
      throw StateError('unpersisted match progress cannot be serialized');
    }

    return <String, dynamic>{
      'schema_version': schemaVersion,
      'schedule_type': scheduleType.value,
      'generated_schedule_id': generatedScheduleId,
      'round_no': roundNo,
      'court_no': courtNo,
      'match_no': matchNo,
      'status': status.value,
      'result': result?.toJson(),
      'note': note,
      'started_at': startedAt?.toIso8601String(),
      'finished_at': finishedAt?.toIso8601String(),
      'created_at': persistedCreatedAt.toIso8601String(),
      'updated_at': persistedUpdatedAt.toIso8601String(),
      'revision': revision,
    };
  }
}

class ScheduleMatchProgressUpdate {
  ScheduleMatchProgressUpdate({
    required this.roundNo,
    required this.courtNo,
    this.matchNo,
    required this.status,
    this.result,
    this.note = '',
    this.startedAt,
    this.finishedAt,
  }) {
    ScheduleMatchKey(roundNo: roundNo, courtNo: courtNo);
    if (matchNo != null && matchNo! <= 0) {
      throw ArgumentError.value(matchNo, 'matchNo', 'must be positive');
    }
  }

  final int roundNo;
  final int courtNo;
  final int? matchNo;
  final ScheduleMatchStatus status;
  final ScheduleMatchResultSummary? result;
  final String note;
  final DateTime? startedAt;
  final DateTime? finishedAt;

  ScheduleMatchKey get key {
    return ScheduleMatchKey(roundNo: roundNo, courtNo: courtNo);
  }
}

class ScheduleProgressSummary {
  ScheduleProgressSummary({
    required this.schemaVersion,
    required this.scheduleType,
    required this.generatedScheduleId,
    required this.totalMatchCount,
    required this.completedMatchCount,
    required this.inProgressMatchCount,
    required this.createdAt,
    required this.updatedAt,
    required this.revision,
  }) {
    if (generatedScheduleId.isEmpty) {
      throw ArgumentError.value(
        generatedScheduleId,
        'generatedScheduleId',
        'must not be empty',
      );
    }
    if (totalMatchCount <= 0) {
      throw ArgumentError.value(
        totalMatchCount,
        'totalMatchCount',
        'must be positive',
      );
    }
    if (completedMatchCount < 0) {
      throw ArgumentError.value(
        completedMatchCount,
        'completedMatchCount',
        'must not be negative',
      );
    }
    if (inProgressMatchCount < 0) {
      throw ArgumentError.value(
        inProgressMatchCount,
        'inProgressMatchCount',
        'must not be negative',
      );
    }
    if (completedMatchCount + inProgressMatchCount > totalMatchCount) {
      throw ArgumentError(
        'completed and in-progress counts must not exceed total count',
      );
    }
    if (revision <= 0) {
      throw ArgumentError.value(revision, 'revision', 'must be positive');
    }
  }

  static const int currentSchemaVersion = 1;

  factory ScheduleProgressSummary.fromJson(Map<String, dynamic> json) {
    return ScheduleProgressSummary(
      schemaVersion: _readInt(
        json,
        'schema_version',
        defaultValue: currentSchemaVersion,
      ),
      scheduleType: ScheduleProgressScheduleType.fromValue(
        _readString(json, 'schedule_type'),
      ),
      generatedScheduleId: _readString(json, 'generated_schedule_id'),
      totalMatchCount: _readInt(json, 'total_match_count'),
      completedMatchCount: _readInt(json, 'completed_match_count'),
      inProgressMatchCount: _readInt(json, 'in_progress_match_count'),
      createdAt: _readDateTime(json, 'created_at'),
      updatedAt: _readDateTime(json, 'updated_at'),
      revision: _readInt(json, 'revision'),
    );
  }

  final int schemaVersion;
  final ScheduleProgressScheduleType scheduleType;
  final String generatedScheduleId;
  final int totalMatchCount;
  final int completedMatchCount;
  final int inProgressMatchCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int revision;

  int get scheduledMatchCount {
    return totalMatchCount - completedMatchCount - inProgressMatchCount;
  }

  ScheduleOverallProgressStatus get overallStatus {
    if (completedMatchCount == totalMatchCount) {
      return ScheduleOverallProgressStatus.completed;
    }
    if (completedMatchCount == 0 && inProgressMatchCount == 0) {
      return ScheduleOverallProgressStatus.notStarted;
    }

    return ScheduleOverallProgressStatus.inProgress;
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schema_version': schemaVersion,
      'schedule_type': scheduleType.value,
      'generated_schedule_id': generatedScheduleId,
      'total_match_count': totalMatchCount,
      'completed_match_count': completedMatchCount,
      'in_progress_match_count': inProgressMatchCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'revision': revision,
    };
  }
}

String _readString(
  Map<String, dynamic> json,
  String key, {
  String? defaultValue,
}) {
  final value = json[key];
  if (value == null) {
    if (defaultValue != null) {
      return defaultValue;
    }
    throw FormatException('missing string: $key');
  }

  return value.toString();
}

int _readInt(
  Map<String, dynamic> json,
  String key, {
  int? defaultValue,
}) {
  final value = _tryReadInt(json[key]);
  if (value != null) {
    return value;
  }
  if (defaultValue != null) {
    return defaultValue;
  }

  throw FormatException('invalid integer: $key');
}

int? _readOptionalInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }

  final parsed = _tryReadInt(value);
  if (parsed == null) {
    throw FormatException('invalid integer: $key');
  }

  return parsed;
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

List<int> _readIntList(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! List) {
    throw FormatException('invalid integer list: $key');
  }

  final result = <int>[];
  for (final item in value) {
    final parsed = _tryReadInt(item);
    if (parsed == null) {
      throw FormatException('invalid integer list item: $key');
    }
    result.add(parsed);
  }

  return result;
}

DateTime _readDateTime(Map<String, dynamic> json, String key) {
  final value = _readOptionalDateTime(json, key);
  if (value == null) {
    throw FormatException('invalid datetime: $key');
  }

  return value;
}

DateTime? _readOptionalDateTime(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) {
    return null;
  }
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

Map<String, dynamic>? _readOptionalObject(
  Map<String, dynamic> json,
  String key,
) {
  final value = json[key];
  if (value == null) {
    return null;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }

  throw FormatException('invalid object: $key');
}
