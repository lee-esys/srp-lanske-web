enum TeamScheduleSport {
  none,
  boccia,
}

extension TeamScheduleSportJson on TeamScheduleSport {
  String? toJsonValue() {
    return switch (this) {
      TeamScheduleSport.none => null,
      TeamScheduleSport.boccia => 'boccia',
    };
  }

  static TeamScheduleSport fromJsonValue(Object? value) {
    return switch (value?.toString()) {
      'boccia' => TeamScheduleSport.boccia,
      _ => TeamScheduleSport.none,
    };
  }
}

class TeamScheduleScores {
  const TeamScheduleScores({
    required this.selectedSport,
    required this.boccia,
  });

  const TeamScheduleScores.empty()
      : selectedSport = TeamScheduleSport.none,
        boccia = const BocciaScoreSheet.empty();

  factory TeamScheduleScores.fromJson(Map<String, dynamic> json) {
    return TeamScheduleScores(
      selectedSport: TeamScheduleSportJson.fromJsonValue(
        json['selected_sport'],
      ),
      boccia: BocciaScoreSheet.fromJson(_readObject(json['boccia'])),
    );
  }

  final TeamScheduleSport selectedSport;
  final BocciaScoreSheet boccia;

  TeamScheduleScores copyWith({
    TeamScheduleSport? selectedSport,
    BocciaScoreSheet? boccia,
  }) {
    return TeamScheduleScores(
      selectedSport: selectedSport ?? this.selectedSport,
      boccia: boccia ?? this.boccia,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'selected_sport': selectedSport.toJsonValue(),
      'boccia': boccia.toJson(),
    };
  }
}

class BocciaScoreSheet {
  const BocciaScoreSheet({
    required this.matches,
  });

  const BocciaScoreSheet.empty() : matches = const <int, BocciaMatchScore>{};

  factory BocciaScoreSheet.fromJson(Map<String, dynamic> json) {
    final matchesJson = json['matches'];
    if (matchesJson is! Map) {
      return const BocciaScoreSheet.empty();
    }

    final matches = <int, BocciaMatchScore>{};

    for (final entry in matchesJson.entries) {
      final value = entry.value;
      if (value is! Map) {
        continue;
      }

      final matchNoFromKey = _readInt(entry.key);
      final parsed = BocciaMatchScore.fromJson(_readObject(value));
      final matchNo = parsed.matchNo > 0 ? parsed.matchNo : matchNoFromKey;

      if (matchNo <= 0) {
        continue;
      }

      matches[matchNo] = parsed.copyWith(matchNo: matchNo);
    }

    return BocciaScoreSheet(
      matches: Map<int, BocciaMatchScore>.unmodifiable(matches),
    );
  }

  final Map<int, BocciaMatchScore> matches;

  BocciaMatchScore? matchScore(int matchNo) {
    return matches[matchNo];
  }

  BocciaMatchScore initialMatchScore({
    required int matchNo,
    required List<int> teamSlots,
  }) {
    if (teamSlots.length != 2) {
      throw ArgumentError.value(
        teamSlots,
        'teamSlots',
        'Boccia score input supports two-team matches only.',
      );
    }

    return BocciaMatchScore.initial(
      matchNo: matchNo,
      redTeamSlot: teamSlots[0],
      blueTeamSlot: teamSlots[1],
    );
  }

  BocciaMatchScore matchScoreOrInitial({
    required int matchNo,
    required List<int> teamSlots,
  }) {
    return matchScore(matchNo) ??
        initialMatchScore(
          matchNo: matchNo,
          teamSlots: teamSlots,
        );
  }

  BocciaScoreSheet upsertMatch(BocciaMatchScore score) {
    return BocciaScoreSheet(
      matches: Map<int, BocciaMatchScore>.unmodifiable(
        <int, BocciaMatchScore>{
          ...matches,
          score.matchNo: score,
        },
      ),
    );
  }

  Map<String, dynamic> toJson() {
    final sortedMatchNos = matches.keys.toList(growable: false)..sort();

    return <String, dynamic>{
      'matches': <String, dynamic>{
        for (final matchNo in sortedMatchNos)
          matchNo.toString(): matches[matchNo]!.toJson(),
      },
    };
  }
}

class BocciaMatchScore {
  const BocciaMatchScore({
    required this.matchNo,
    required this.redTeamSlot,
    required this.blueTeamSlot,
    required this.endScores,
    required this.throwLogs,
  });

  factory BocciaMatchScore.initial({
    required int matchNo,
    required int redTeamSlot,
    required int blueTeamSlot,
    int endCount = 6,
  }) {
    return BocciaMatchScore(
      matchNo: matchNo,
      redTeamSlot: redTeamSlot,
      blueTeamSlot: blueTeamSlot,
      endScores: List<BocciaEndScore>.unmodifiable(
        List<BocciaEndScore>.generate(
          endCount,
          (index) => BocciaEndScore.empty(endNo: index + 1),
        ),
      ),
      throwLogs: const <Map<String, dynamic>>[],
    );
  }

  factory BocciaMatchScore.fromJson(Map<String, dynamic> json) {
    final parsedEndScores = _readEndScores(json['end_scores']);
    final endCount = _readInt(
      json['end_count'],
      defaultValue: parsedEndScores.isEmpty ? 6 : parsedEndScores.length,
    );

    return BocciaMatchScore(
      matchNo: _readInt(json['match_no']),
      redTeamSlot: _readInt(json['red_team_slot']),
      blueTeamSlot: _readInt(json['blue_team_slot']),
      endScores: _normalizeEndScores(
        parsedEndScores,
        endCount: endCount,
      ),
      throwLogs: _readObjectList(json['throw_logs']),
    );
  }

  final int matchNo;
  final int redTeamSlot;
  final int blueTeamSlot;
  final List<BocciaEndScore> endScores;
  final List<Map<String, dynamic>> throwLogs;

  int get endCount => endScores.length;

  int get totalRedScore {
    return endScores.fold<int>(
      0,
      (sum, endScore) => sum + endScore.red,
    );
  }

  int get totalBlueScore {
    return endScores.fold<int>(
      0,
      (sum, endScore) => sum + endScore.blue,
    );
  }

  bool get hasAnyScore {
    return endScores.any((endScore) => endScore.red > 0 || endScore.blue > 0);
  }

  BocciaMatchScore copyWith({
    int? matchNo,
    int? redTeamSlot,
    int? blueTeamSlot,
    List<BocciaEndScore>? endScores,
    List<Map<String, dynamic>>? throwLogs,
  }) {
    return BocciaMatchScore(
      matchNo: matchNo ?? this.matchNo,
      redTeamSlot: redTeamSlot ?? this.redTeamSlot,
      blueTeamSlot: blueTeamSlot ?? this.blueTeamSlot,
      endScores: List<BocciaEndScore>.unmodifiable(
        endScores ?? this.endScores,
      ),
      throwLogs: List<Map<String, dynamic>>.unmodifiable(
        throwLogs ?? this.throwLogs,
      ),
    );
  }

  BocciaMatchScore replaceEndScore({
    required int endNo,
    int? red,
    int? blue,
  }) {
    return copyWith(
      endScores: endScores.map((endScore) {
        if (endScore.endNo != endNo) {
          return endScore;
        }

        return endScore.copyWith(
          red: red,
          blue: blue,
        );
      }).toList(growable: false),
    );
  }

  BocciaMatchScore swapped() {
    return copyWith(
      redTeamSlot: blueTeamSlot,
      blueTeamSlot: redTeamSlot,
      endScores: endScores
          .map((endScore) => endScore.swapped())
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'match_no': matchNo,
      'red_team_slot': redTeamSlot,
      'blue_team_slot': blueTeamSlot,
      'end_count': endCount,
      'end_scores': endScores.map((endScore) => endScore.toJson()).toList(),
      'throw_logs': throwLogs,
    };
  }
}

class BocciaEndScore {
  const BocciaEndScore({
    required this.endNo,
    required this.red,
    required this.blue,
  });

  const BocciaEndScore.empty({
    required this.endNo,
  })  : red = 0,
        blue = 0;

  factory BocciaEndScore.fromJson(Map<String, dynamic> json) {
    return BocciaEndScore(
      endNo: _readInt(json['end_no']),
      red: _clampScore(_readInt(json['red'])),
      blue: _clampScore(_readInt(json['blue'])),
    );
  }

  final int endNo;
  final int red;
  final int blue;

  BocciaEndScore copyWith({
    int? endNo,
    int? red,
    int? blue,
  }) {
    return BocciaEndScore(
      endNo: endNo ?? this.endNo,
      red: red == null ? this.red : _clampScore(red),
      blue: blue == null ? this.blue : _clampScore(blue),
    );
  }

  BocciaEndScore swapped() {
    return copyWith(
      red: blue,
      blue: red,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'end_no': endNo,
      'red': red,
      'blue': blue,
    };
  }
}

List<BocciaEndScore> _readEndScores(Object? value) {
  if (value is! List) {
    return const <BocciaEndScore>[];
  }

  return value
      .whereType<Map>()
      .map((json) => BocciaEndScore.fromJson(_readObject(json)))
      .where((endScore) => endScore.endNo > 0)
      .toList(growable: false);
}

List<BocciaEndScore> _normalizeEndScores(
  List<BocciaEndScore> source, {
  required int endCount,
}) {
  final sourceByEndNo = <int, BocciaEndScore>{
    for (final endScore in source) endScore.endNo: endScore,
  };

  return List<BocciaEndScore>.unmodifiable(
    List<BocciaEndScore>.generate(
      endCount,
      (index) {
        final endNo = index + 1;
        return sourceByEndNo[endNo] ?? BocciaEndScore.empty(endNo: endNo);
      },
    ),
  );
}

Map<String, dynamic> _readObject(Object? value) {
  if (value is! Map) {
    return const <String, dynamic>{};
  }

  return <String, dynamic>{
    for (final entry in value.entries) entry.key.toString(): entry.value,
  };
}

List<Map<String, dynamic>> _readObjectList(Object? value) {
  if (value is! List) {
    return const <Map<String, dynamic>>[];
  }

  return List<Map<String, dynamic>>.unmodifiable(
    value.whereType<Map>().map(_readObject),
  );
}

int _readInt(Object? value, {int defaultValue = 0}) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  if (value is String) {
    return int.tryParse(value) ?? defaultValue;
  }

  return defaultValue;
}

int _clampScore(int value) {
  return value.clamp(0, 6).toInt();
}
