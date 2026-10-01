import 'dart:convert';

import 'package:uuid/uuid.dart';

import 'player_source_metadata.dart';

final _uuid = Uuid();

class PlayerDraft {
  PlayerDraft({
    required this.id,
    required this.displayName,
    this.sourceText,
    this.externalIdentity,
    this.sourceProfileSnapshot,
  });

  factory PlayerDraft.create({
    required String displayName,
    String? sourceText,
    PlayerExternalIdentity? externalIdentity,
    PlayerSourceProfileSnapshot? sourceProfileSnapshot,
  }) {
    return PlayerDraft(
      id: _uuid.v4(),
      displayName: displayName,
      sourceText: sourceText,
      externalIdentity: externalIdentity,
      sourceProfileSnapshot: sourceProfileSnapshot,
    );
  }

  final String id;
  final String displayName;
  final String? sourceText;
  final PlayerExternalIdentity? externalIdentity;
  final PlayerSourceProfileSnapshot? sourceProfileSnapshot;

  PlayerDraft copyWith({
    String? id,
    String? displayName,
  }) {
    return PlayerDraft(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      sourceText: sourceText,
      externalIdentity: externalIdentity,
      sourceProfileSnapshot: sourceProfileSnapshot,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'sourceText': sourceText,
      'externalIdentity': externalIdentity?.toJson(),
      'sourceProfileSnapshot': sourceProfileSnapshot?.toJson(),
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
