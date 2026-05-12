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
      currentGeneratedScheduleId: currentGeneratedScheduleId ?? this.currentGeneratedScheduleId,
      adoptedGeneratedScheduleId: adoptedGeneratedScheduleId ?? this.adoptedGeneratedScheduleId,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class SavedEventParticipant {
  SavedEventParticipant({
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
    this.parsedParticipantsJson,
    this.confirmedAt,
  });

  final String id;
  final String eventId;
  final EventSourceType sourceType;
  final String? sourceUrl;
  final String? pastedText;
  final Map<String, dynamic>? parsedEventJson;
  final List<Map<String, dynamic>>? parsedParticipantsJson;
  final DateTime? confirmedAt;
  final DateTime createdAt;
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
}

class SavedEventAggregate {
  SavedEventAggregate({
    required this.event,
    required this.participants,
    required this.share,
    this.importRecord,
  });

  final SavedEvent event;
  final List<SavedEventParticipant> participants;
  final SavedEventShare share;
  final SavedEventImport? importRecord;
}
