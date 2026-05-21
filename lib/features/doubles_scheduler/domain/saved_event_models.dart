const savedEventAggregateSchemaVersion = 1;

enum EventSourceType {
  tennisbear,
  tennisoff,
  manual,
  unknown,
}

enum SavedEventStatus {
  draft,
  generated,
  adopted,
}

class SavedEvent {
  SavedEvent({
    required this.id,
    required this.publicId,
    required this.title,
    required this.courtCount,
    required this.sourceType,
    required this.sourceUrl,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.eventDate,
    this.startTime,
    this.endTime,
    this.location,
    this.currentGeneratedScheduleId,
    this.adoptedGeneratedScheduleId,
  });

  final String id;
  final String publicId;
  final String title;
  final DateTime? eventDate;
  final String? startTime;
  final String? endTime;
  final String? location;
  final int courtCount;
  final EventSourceType sourceType;
  final String? sourceUrl;
  final SavedEventStatus status;
  final String? currentGeneratedScheduleId;
  final String? adoptedGeneratedScheduleId;
  final DateTime createdAt;
  final DateTime updatedAt;

  String? get displayGeneratedScheduleId {
    return adoptedGeneratedScheduleId ?? currentGeneratedScheduleId;
  }

  bool get hasAdoptedSchedule {
    return status == SavedEventStatus.adopted ||
        adoptedGeneratedScheduleId != null;
  }

  SavedEvent copyWith({
    String? title,
    DateTime? eventDate,
    String? startTime,
    String? endTime,
    String? location,
    int? courtCount,
    EventSourceType? sourceType,
    String? sourceUrl,
    SavedEventStatus? status,
    String? currentGeneratedScheduleId,
    String? adoptedGeneratedScheduleId,
    DateTime? updatedAt,
  }) {
    return SavedEvent(
      id: id,
      publicId: publicId,
      title: title ?? this.title,
      eventDate: eventDate ?? this.eventDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      location: location ?? this.location,
      courtCount: courtCount ?? this.courtCount,
      sourceType: sourceType ?? this.sourceType,
      sourceUrl: sourceUrl ?? this.sourceUrl,
      status: status ?? this.status,
      currentGeneratedScheduleId:
          currentGeneratedScheduleId ?? this.currentGeneratedScheduleId,
      adoptedGeneratedScheduleId:
          adoptedGeneratedScheduleId ?? this.adoptedGeneratedScheduleId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'publicId': publicId,
      'title': title,
      'eventDate': _nullableDateTimeToJson(eventDate),
      'startTime': startTime,
      'endTime': endTime,
      'location': location,
      'courtCount': courtCount,
      'sourceType': sourceType.name,
      'sourceUrl': sourceUrl,
      'status': status.name,
      'currentGeneratedScheduleId': currentGeneratedScheduleId,
      'adoptedGeneratedScheduleId': adoptedGeneratedScheduleId,
      'createdAt': _dateTimeToJson(createdAt),
      'updatedAt': _dateTimeToJson(updatedAt),
    };
  }

  factory SavedEvent.fromJson(Map<String, dynamic> json) {
    return SavedEvent(
      id: json['id'].toString(),
      publicId: json['publicId'].toString(),
      title: json['title'].toString(),
      eventDate: _nullableDateTimeFromJson(json['eventDate']),
      startTime: json['startTime']?.toString(),
      endTime: json['endTime']?.toString(),
      location: json['location']?.toString(),
      courtCount: _intFromJson(json['courtCount']),
      sourceType: _eventSourceTypeFromJson(json['sourceType']),
      sourceUrl: json['sourceUrl']?.toString(),
      status: _savedEventStatusFromJson(json['status']),
      currentGeneratedScheduleId:
          json['currentGeneratedScheduleId']?.toString(),
      adoptedGeneratedScheduleId:
          json['adoptedGeneratedScheduleId']?.toString(),
      createdAt: _dateTimeFromJson(json['createdAt']),
      updatedAt: _dateTimeFromJson(json['updatedAt']),
    );
  }
}

class SavedEventPlayer {
  SavedEventPlayer({
    required this.id,
    required this.eventId,
    required this.displayName,
    required this.orderNo,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.sourceText,
  });

  final String id;
  final String eventId;
  final String displayName;
  final int orderNo;
  final String status;
  final String? sourceText;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'displayName': displayName,
      'orderNo': orderNo,
      'status': status,
      'sourceText': sourceText,
      'createdAt': _dateTimeToJson(createdAt),
      'updatedAt': _dateTimeToJson(updatedAt),
    };
  }

  factory SavedEventPlayer.fromJson(Map<String, dynamic> json) {
    return SavedEventPlayer(
      id: json['id'].toString(),
      eventId: json['eventId'].toString(),
      displayName: json['displayName'].toString(),
      orderNo: _intFromJson(json['orderNo']),
      status: json['status']?.toString() ?? 'active',
      sourceText: json['sourceText']?.toString(),
      createdAt: _dateTimeFromJson(json['createdAt']),
      updatedAt: _dateTimeFromJson(json['updatedAt']),
    );
  }
}

class SavedEventImport {
  SavedEventImport({
    required this.id,
    required this.eventId,
    required this.sourceType,
    required this.createdAt,
    this.sourceUrl,
    this.pastedText,
    this.parsedEventJson,
    this.parsedPlayersJson,
    this.confirmedAt,
  });

  final String id;
  final String eventId;
  final EventSourceType sourceType;
  final String? sourceUrl;
  final String? pastedText;
  final Map<String, dynamic>? parsedEventJson;
  final List<Map<String, dynamic>>? parsedPlayersJson;
  final DateTime? confirmedAt;
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventId': eventId,
      'sourceType': sourceType.name,
      'sourceUrl': sourceUrl,
      'pastedText': pastedText,
      'parsedEventJson': parsedEventJson,
      'parsedPlayersJson': parsedPlayersJson,
      'confirmedAt': _nullableDateTimeToJson(confirmedAt),
      'createdAt': _dateTimeToJson(createdAt),
    };
  }

  factory SavedEventImport.fromJson(Map<String, dynamic> json) {
    return SavedEventImport(
      id: json['id'].toString(),
      eventId: json['eventId'].toString(),
      sourceType: _eventSourceTypeFromJson(json['sourceType']),
      sourceUrl: json['sourceUrl']?.toString(),
      pastedText: json['pastedText']?.toString(),
      parsedEventJson: _nullableMapFromJson(json['parsedEventJson']),
      parsedPlayersJson: _nullableMapListFromJson(
        // TODO(ver0.2): Remove the legacy parsedParticipantsJson fallback.
        json['parsedPlayersJson'] ?? json['parsedParticipantsJson'],
      ),
      confirmedAt: _nullableDateTimeFromJson(json['confirmedAt']),
      createdAt: _dateTimeFromJson(json['createdAt']),
    );
  }
}

class SavedEventShare {
  SavedEventShare({
    required this.publicId,
    required this.eventId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String publicId;
  final String eventId;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'publicId': publicId,
      'eventId': eventId,
      'createdAt': _dateTimeToJson(createdAt),
      'updatedAt': _dateTimeToJson(updatedAt),
    };
  }

  factory SavedEventShare.fromJson(Map<String, dynamic> json) {
    return SavedEventShare(
      publicId: json['publicId'].toString(),
      eventId: json['eventId'].toString(),
      createdAt: _dateTimeFromJson(json['createdAt']),
      updatedAt: _dateTimeFromJson(json['updatedAt']),
    );
  }
}

class SavedEventAggregate {
  SavedEventAggregate({
    required this.event,
    required this.players,
    required this.share,
    this.importRecord,
  });

  final SavedEvent event;
  final List<SavedEventPlayer> players;
  final SavedEventShare share;
  final SavedEventImport? importRecord;

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': savedEventAggregateSchemaVersion,
      'event': event.toJson(),
      'players': players.map((player) {
        return player.toJson();
      }).toList(growable: false),
      'share': share.toJson(),
      'importRecord': importRecord?.toJson(),
    };
  }

  factory SavedEventAggregate.fromJson(Map<String, dynamic> json) {
    final eventJson = _nullableMapFromJson(json['event']);
    final shareJson = _nullableMapFromJson(json['share']);

    if (eventJson == null) {
      throw const FormatException('event is required');
    }

    if (shareJson == null) {
      throw const FormatException('share is required');
    }

    // TODO(ver0.2): Remove the legacy participants fallback.
    final playersValue = json['players'] ?? json['participants'];
    if (playersValue is! List) {
      throw const FormatException('players is required');
    }

    final importRecordJson = _nullableMapFromJson(json['importRecord']);

    return SavedEventAggregate(
      event: SavedEvent.fromJson(eventJson),
      players: playersValue.map((item) {
        if (item is! Map) {
          throw FormatException('invalid player item: $item');
        }

        return SavedEventPlayer.fromJson(
          item.map((key, value) => MapEntry(key.toString(), value)),
        );
      }).toList(growable: false),
      share: SavedEventShare.fromJson(shareJson),
      importRecord: importRecordJson == null
          ? null
          : SavedEventImport.fromJson(importRecordJson),
    );
  }
}

DateTime _dateTimeFromJson(Object? value) {
  if (value == null) {
    throw const FormatException('DateTime value is required');
  }

  return DateTime.parse(value.toString());
}

DateTime? _nullableDateTimeFromJson(Object? value) {
  if (value == null) return null;
  return DateTime.parse(value.toString());
}

String _dateTimeToJson(DateTime value) {
  return value.toUtc().toIso8601String();
}

String? _nullableDateTimeToJson(DateTime? value) {
  if (value == null) return null;
  return value.toUtc().toIso8601String();
}

int _intFromJson(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();

  final parsed = int.tryParse(value.toString());
  if (parsed == null) {
    throw FormatException('invalid int value: $value');
  }

  return parsed;
}

Map<String, dynamic>? _nullableMapFromJson(Object? value) {
  if (value == null) return null;
  if (value is! Map) {
    throw FormatException('invalid map value: $value');
  }

  return value.map(
    (key, value) => MapEntry(key.toString(), value),
  );
}

List<Map<String, dynamic>>? _nullableMapListFromJson(Object? value) {
  if (value == null) return null;
  if (value is! List) {
    throw FormatException('invalid map list value: $value');
  }

  return value.map((item) {
    if (item is! Map) {
      throw FormatException('invalid map list item: $item');
    }

    return item.map(
      (key, value) => MapEntry(key.toString(), value),
    );
  }).toList(growable: false);
}

EventSourceType _eventSourceTypeFromJson(Object? value) {
  return EventSourceType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => EventSourceType.unknown,
  );
}

SavedEventStatus _savedEventStatusFromJson(Object? value) {
  return SavedEventStatus.values.firstWhere(
    (status) => status.name == value,
    orElse: () => SavedEventStatus.draft,
  );
}
