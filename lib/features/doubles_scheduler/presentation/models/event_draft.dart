import 'dart:convert';

import '../../domain/participant_draft.dart';

class EventDraft {
  EventDraft({
    required this.url,
    required this.courts,
    required this.eventName,
    required this.participants,
  });

  final String url;
  final int courts;
  final String eventName;
  final List<ParticipantDraft> participants;

  int get players => participants.length;

  List<String> get displayNames =>
      participants.map((e) => e.displayName).toList(growable: false);

  EventDraft copyWith({
    String? url,
    int? courts,
    String? eventName,
    List<ParticipantDraft>? participants,
  }) {
    return EventDraft(
      url: url ?? this.url,
      courts: courts ?? this.courts,
      eventName: eventName ?? this.eventName,
      participants:
          participants ?? this.participants.map((e) => e.copyWith()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'courts': courts,
      'eventName': eventName,
      'players': players,
      'participants': participants.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }
}
