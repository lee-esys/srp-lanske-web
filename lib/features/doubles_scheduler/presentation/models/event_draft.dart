import 'dart:convert';

import '../../domain/player_draft.dart';
import '../../domain/saved_event_models.dart';

class EventDraft {
  EventDraft({
    required this.url,
    required this.courts,
    required this.eventName,
    required this.players,
    this.sourceType = EventSourceType.unknown,
  });

  final String url;
  final int courts;
  final String eventName;
  final List<PlayerDraft> players;
  final EventSourceType sourceType;

  int get playerCount => players.length;

  List<String> get displayNames =>
      players.map((e) => e.displayName).toList(growable: false);

  EventDraft copyWith({
    String? url,
    int? courts,
    String? eventName,
    List<PlayerDraft>? players,
    EventSourceType? sourceType,
  }) {
    return EventDraft(
      url: url ?? this.url,
      courts: courts ?? this.courts,
      eventName: eventName ?? this.eventName,
      players: players ?? this.players.map((e) => e.copyWith()).toList(),
      sourceType: sourceType ?? this.sourceType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'courts': courts,
      'eventName': eventName,
      'playerCount': playerCount,
      'players': players.map((e) => e.toJson()).toList(),
      'sourceType': sourceType.name,
    };
  }

  @override
  String toString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }
}
