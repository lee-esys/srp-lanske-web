import 'dart:convert';

import '../../domain/player_draft.dart';

class EventDraft {
  EventDraft({
    required this.url,
    required this.courts,
    required this.eventName,
    required this.players,
  });

  final String url;
  final int courts;
  final String eventName;
  final List<PlayerDraft> players;

  int get playerCount => players.length;

  List<String> get displayNames =>
      players.map((e) => e.displayName).toList(growable: false);

  EventDraft copyWith({
    String? url,
    int? courts,
    String? eventName,
    List<PlayerDraft>? players,
  }) {
    return EventDraft(
      url: url ?? this.url,
      courts: courts ?? this.courts,
      eventName: eventName ?? this.eventName,
      players: players ?? this.players.map((e) => e.copyWith()).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'courts': courts,
      'eventName': eventName,
      'playerCount': playerCount,
      'players': players.map((e) => e.toJson()).toList(),
    };
  }

  @override
  String toString() {
    return const JsonEncoder.withIndent('  ').convert(toJson());
  }
}
