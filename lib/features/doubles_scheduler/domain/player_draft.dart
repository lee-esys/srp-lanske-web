import 'dart:convert';

import 'package:uuid/uuid.dart';

final _uuid = Uuid();

class PlayerDraft {
  PlayerDraft({
    required this.id,
    required this.displayName,
  });

  factory PlayerDraft.create({
    required String displayName,
  }) {
    return PlayerDraft(
      id: _uuid.v4(),
      displayName: displayName,
    );
  }

  final String id;
  final String displayName;

  PlayerDraft copyWith({
    String? id,
    String? displayName,
  }) {
    return PlayerDraft(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
    };
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
