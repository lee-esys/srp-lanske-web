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

enum BocciaThrowingSide {
  red,
  blue,
}

extension BocciaThrowingSideJson on BocciaThrowingSide {
  String toJsonValue() {
    return switch (this) {
      BocciaThrowingSide.red => 'red',
      BocciaThrowingSide.blue => 'blue',
    };
  }

  static BocciaThrowingSide fromJsonValue(Object? value) {
    return switch (value?.toString()) {
      'blue' => BocciaThrowingSide.blue,
      _ => BocciaThrowingSide.red,
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
    List<int> redPlayerSlots = const <int>[],
    List<int> bluePlayerSlots = const <int>[],
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
      redPlayerSlots: redPlayerSlots,
      bluePlayerSlots: bluePlayerSlots,
    );
  }

  BocciaMatchScore matchScoreOrInitial({
    required int matchNo,
    required List<int> teamSlots,
    List<int> redPlayerSlots = const <int>[],
    List<int> bluePlayerSlots = const <int>[],
  }) {
    return matchScore(matchNo) ??
        initialMatchScore(
          matchNo: matchNo,
          teamSlots: teamSlots,
          redPlayerSlots: redPlayerSlots,
          bluePlayerSlots: bluePlayerSlots,
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
    required this.throwingBoxAssignments,
    required this.throwLogs,
  });

  factory BocciaMatchScore.initial({
    required int matchNo,
    required int redTeamSlot,
    required int blueTeamSlot,
    int endCount = 6,
    List<int> redPlayerSlots = const <int>[],
    List<int> bluePlayerSlots = const <int>[],
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
      throwingBoxAssignments: _initialThrowingBoxAssignments(
        redPlayerSlots: redPlayerSlots,
        bluePlayerSlots: bluePlayerSlots,
      ),
      throwLogs: const <BocciaThrowLog>[],
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
      throwingBoxAssignments: _normalizeThrowingBoxAssignments(
        _readThrowingBoxAssignments(json['throwing_box_assignments']),
      ),
      throwLogs: _readThrowLogs(json['throw_logs']),
    );
  }

  final int matchNo;
  final int redTeamSlot;
  final int blueTeamSlot;
  final List<BocciaEndScore> endScores;
  final List<BocciaThrowingBoxAssignment> throwingBoxAssignments;
  final List<BocciaThrowLog> throwLogs;

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

  bool get hasAnyThrowLog {
    return throwLogs.isNotEmpty;
  }

  bool get canEditThrowingBoxAssignments {
    return !hasAnyThrowLog;
  }

  List<BocciaThrowLog> throwLogsForEnd(int endNo) {
    return throwLogs.where((log) => log.endNo == endNo).toList(growable: false);
  }

  int throwLogCountForEnd(int endNo) {
    return throwLogsForEnd(endNo).length;
  }

  int throwLogCountForEndSide({
    required int endNo,
    required BocciaThrowingSide side,
  }) {
    return throwLogs
        .where((log) => log.endNo == endNo)
        .where((log) => log.side == side)
        .length;
  }

  int throwLogCountForEndBox({
    required int endNo,
    required int boxNo,
  }) {
    final normalizedBoxNo = _normalizeThrowingBoxNo(boxNo);
    if (normalizedBoxNo == null) {
      return 0;
    }

    return throwLogs
        .where((log) => log.endNo == endNo)
        .where((log) => log.boxNo == normalizedBoxNo)
        .length;
  }

  bool canAddThrowLogForEnd(int endNo) {
    return throwLogCountForEnd(endNo) < 12;
  }

  BocciaThrowingBoxAssignment? throwingBoxAssignment(int boxNo) {
    final normalizedBoxNo = _normalizeThrowingBoxNo(boxNo);
    if (normalizedBoxNo == null) {
      return null;
    }

    for (final assignment in throwingBoxAssignments) {
      if (assignment.boxNo == normalizedBoxNo) {
        return assignment;
      }
    }

    return BocciaThrowingBoxAssignment.empty(boxNo: normalizedBoxNo);
  }

  List<BocciaThrowingBoxAssignment> get redThrowingBoxAssignments {
    return throwingBoxAssignments
        .where((assignment) => assignment.side == BocciaThrowingSide.red)
        .toList(growable: false);
  }

  List<BocciaThrowingBoxAssignment> get blueThrowingBoxAssignments {
    return throwingBoxAssignments
        .where((assignment) => assignment.side == BocciaThrowingSide.blue)
        .toList(growable: false);
  }

  BocciaMatchScore copyWith({
    int? matchNo,
    int? redTeamSlot,
    int? blueTeamSlot,
    List<BocciaEndScore>? endScores,
    List<BocciaThrowingBoxAssignment>? throwingBoxAssignments,
    List<BocciaThrowLog>? throwLogs,
  }) {
    return BocciaMatchScore(
      matchNo: matchNo ?? this.matchNo,
      redTeamSlot: redTeamSlot ?? this.redTeamSlot,
      blueTeamSlot: blueTeamSlot ?? this.blueTeamSlot,
      endScores: List<BocciaEndScore>.unmodifiable(
        endScores ?? this.endScores,
      ),
      throwingBoxAssignments: _normalizeThrowingBoxAssignments(
        throwingBoxAssignments ?? this.throwingBoxAssignments,
      ),
      throwLogs: List<BocciaThrowLog>.unmodifiable(
        _normalizeThrowLogs(throwLogs ?? this.throwLogs),
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

  BocciaMatchScore replaceThrowingBoxPlayer({
    required int boxNo,
    int? playerSlot,
  }) {
    if (!canEditThrowingBoxAssignments) {
      return this;
    }

    final normalizedBoxNo = _normalizeThrowingBoxNo(boxNo);
    if (normalizedBoxNo == null) {
      return this;
    }

    final normalizedPlayerSlot = _normalizePlayerSlot(playerSlot);
    final currentAssignment = throwingBoxAssignment(normalizedBoxNo);
    final currentPlayerSlot = currentAssignment?.playerSlot;

    final duplicatedAssignment = normalizedPlayerSlot == null
        ? null
        : throwingBoxAssignments
            .where((assignment) => assignment.boxNo != normalizedBoxNo)
            .where(
                (assignment) => assignment.playerSlot == normalizedPlayerSlot)
            .firstOrNull;

    return copyWith(
      throwingBoxAssignments: throwingBoxAssignments.map((assignment) {
        if (assignment.boxNo == normalizedBoxNo) {
          return assignment.copyWith(
            playerSlot: normalizedPlayerSlot,
          );
        }

        if (duplicatedAssignment != null &&
            assignment.boxNo == duplicatedAssignment.boxNo) {
          return assignment.copyWith(
            playerSlot: currentPlayerSlot,
          );
        }

        return assignment;
      }).toList(growable: false),
    );
  }

  BocciaMatchScore clearThrowingBoxPlayer({
    required int boxNo,
  }) {
    return replaceThrowingBoxPlayer(boxNo: boxNo);
  }

  BocciaMatchScore addThrowLog({
    required int endNo,
    required int boxNo,
  }) {
    if (!canAddThrowLogForEnd(endNo)) {
      return this;
    }

    final normalizedBoxNo = _normalizeThrowingBoxNo(boxNo);
    if (normalizedBoxNo == null) {
      return this;
    }

    final assignment = throwingBoxAssignment(normalizedBoxNo);
    final playerSlot = assignment?.playerSlot;
    if (playerSlot == null) {
      return this;
    }

    final nextThrowNo = throwLogCountForEnd(endNo) + 1;

    return copyWith(
      throwLogs: <BocciaThrowLog>[
        ...throwLogs,
        BocciaThrowLog(
          endNo: endNo,
          throwNo: nextThrowNo,
          side: assignment!.side,
          boxNo: normalizedBoxNo,
          teamSlot: assignment.side == BocciaThrowingSide.red
              ? redTeamSlot
              : blueTeamSlot,
          playerSlot: playerSlot,
        ),
      ],
    );
  }

  BocciaMatchScore removeLastThrowLog({
    required int endNo,
  }) {
    final endLogs = throwLogsForEnd(endNo);
    if (endLogs.isEmpty) {
      return this;
    }

    final lastEndLog = endLogs.last;

    return copyWith(
      throwLogs: throwLogs
          .where((log) => !(log.endNo == lastEndLog.endNo &&
              log.throwNo == lastEndLog.throwNo))
          .toList(growable: false),
    );
  }

  BocciaMatchScore clearThrowLogsForEnd({
    required int endNo,
  }) {
    return copyWith(
      throwLogs:
          throwLogs.where((log) => log.endNo != endNo).toList(growable: false),
    );
  }

  BocciaMatchScore swapped() {
    return copyWith(
      redTeamSlot: blueTeamSlot,
      blueTeamSlot: redTeamSlot,
      endScores: endScores
          .map((endScore) => endScore.swapped())
          .toList(growable: false),
      throwingBoxAssignments: _swapThrowingBoxAssignments(
        throwingBoxAssignments,
      ),
      throwLogs: throwLogs
          .map((log) => log.swapped(
                redTeamSlot: blueTeamSlot,
                blueTeamSlot: redTeamSlot,
              ))
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
      'throwing_box_assignments': throwingBoxAssignments
          .map((assignment) => assignment.toJson())
          .toList(),
      'throw_logs': throwLogs.map((log) => log.toJson()).toList(),
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

class BocciaThrowLog {
  const BocciaThrowLog({
    required this.endNo,
    required this.throwNo,
    required this.side,
    required this.boxNo,
    required this.teamSlot,
    required this.playerSlot,
  });

  factory BocciaThrowLog.fromJson(Map<String, dynamic> json) {
    final boxNo = _normalizeThrowingBoxNo(json['box_no']) ?? 1;
    final side = BocciaThrowingSideJson.fromJsonValue(
      json['team_color'] ?? json['side'],
    );

    return BocciaThrowLog(
      endNo: _readInt(json['end_no']),
      throwNo: _readInt(json['throw_no']),
      side: side,
      boxNo: boxNo,
      teamSlot: _readInt(json['team_slot']),
      playerSlot: _readInt(json['player_slot']),
    );
  }

  final int endNo;
  final int throwNo;
  final BocciaThrowingSide side;
  final int boxNo;
  final int teamSlot;
  final int playerSlot;

  BocciaThrowLog copyWith({
    int? endNo,
    int? throwNo,
    BocciaThrowingSide? side,
    int? boxNo,
    int? teamSlot,
    int? playerSlot,
  }) {
    final normalizedBoxNo = _normalizeThrowingBoxNo(boxNo ?? this.boxNo) ??
        _normalizeThrowingBoxNo(this.boxNo) ??
        this.boxNo;

    return BocciaThrowLog(
      endNo: endNo ?? this.endNo,
      throwNo: throwNo ?? this.throwNo,
      side: side ?? this.side,
      boxNo: normalizedBoxNo,
      teamSlot: teamSlot ?? this.teamSlot,
      playerSlot: playerSlot ?? this.playerSlot,
    );
  }

  BocciaThrowLog swapped({
    required int redTeamSlot,
    required int blueTeamSlot,
  }) {
    final nextBoxNo = _swappedThrowingBoxNo(boxNo);
    final nextSide = _throwingSideForBoxNo(nextBoxNo);

    return copyWith(
      side: nextSide,
      boxNo: nextBoxNo,
      teamSlot: nextSide == BocciaThrowingSide.red ? redTeamSlot : blueTeamSlot,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'end_no': endNo,
      'throw_no': throwNo,
      'team_color': side.toJsonValue(),
      'box_no': boxNo,
      'team_slot': teamSlot,
      'player_slot': playerSlot,
    };
  }
}

class BocciaThrowingBoxAssignment {
  const BocciaThrowingBoxAssignment({
    required this.boxNo,
    required this.side,
    required this.playerSlot,
  });

  factory BocciaThrowingBoxAssignment.empty({
    required int boxNo,
  }) {
    final normalizedBoxNo = _normalizeThrowingBoxNo(boxNo) ?? boxNo;

    return BocciaThrowingBoxAssignment(
      boxNo: normalizedBoxNo,
      side: _throwingSideForBoxNo(normalizedBoxNo),
      playerSlot: null,
    );
  }

  factory BocciaThrowingBoxAssignment.fromJson(Map<String, dynamic> json) {
    final boxNo = _normalizeThrowingBoxNo(_readInt(json['box_no'])) ?? 1;

    return BocciaThrowingBoxAssignment(
      boxNo: boxNo,
      side: _throwingSideForBoxNo(boxNo),
      playerSlot: _normalizePlayerSlot(json['player_slot']),
    );
  }

  final int boxNo;
  final BocciaThrowingSide side;
  final int? playerSlot;

  bool get hasPlayer => playerSlot != null;
  BocciaThrowingBoxAssignment copyWith({
    int? boxNo,
    BocciaThrowingSide? side,
    Object? playerSlot = _unsetPlayerSlot,
  }) {
    final normalizedBoxNo = _normalizeThrowingBoxNo(boxNo ?? this.boxNo) ??
        _normalizeThrowingBoxNo(this.boxNo) ??
        this.boxNo;
    final normalizedSide = _throwingSideForBoxNo(normalizedBoxNo);

    return BocciaThrowingBoxAssignment(
      boxNo: normalizedBoxNo,
      side: side ?? normalizedSide,
      playerSlot: identical(playerSlot, _unsetPlayerSlot)
          ? this.playerSlot
          : _normalizePlayerSlot(playerSlot),
    );
  }

  BocciaThrowingBoxAssignment swapped() {
    final nextBoxNo = _swappedThrowingBoxNo(boxNo);

    return BocciaThrowingBoxAssignment(
      boxNo: nextBoxNo,
      side: _throwingSideForBoxNo(nextBoxNo),
      playerSlot: playerSlot,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'box_no': boxNo,
      'side': side.toJsonValue(),
      'player_slot': playerSlot,
    };
  }
}

const Object _unsetPlayerSlot = Object();

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

List<BocciaThrowingBoxAssignment> _readThrowingBoxAssignments(Object? value) {
  if (value is! List) {
    return const <BocciaThrowingBoxAssignment>[];
  }

  return value
      .whereType<Map>()
      .map((json) => BocciaThrowingBoxAssignment.fromJson(_readObject(json)))
      .where((assignment) => _normalizeThrowingBoxNo(assignment.boxNo) != null)
      .toList(growable: false);
}

List<BocciaThrowLog> _readThrowLogs(Object? value) {
  if (value is! List) {
    return const <BocciaThrowLog>[];
  }

  return _normalizeThrowLogs(
    value
        .whereType<Map>()
        .map((json) => BocciaThrowLog.fromJson(_readObject(json)))
        .where((log) => log.endNo > 0)
        .where((log) => _normalizeThrowingBoxNo(log.boxNo) != null)
        .where((log) => log.teamSlot > 0)
        .where((log) => log.playerSlot > 0)
        .toList(growable: false),
  );
}

List<BocciaThrowLog> _normalizeThrowLogs(List<BocciaThrowLog> source) {
  final grouped = <int, List<BocciaThrowLog>>{};

  for (final log in source) {
    if (log.endNo <= 0) {
      continue;
    }

    final normalizedBoxNo = _normalizeThrowingBoxNo(log.boxNo);
    if (normalizedBoxNo == null || log.teamSlot <= 0 || log.playerSlot <= 0) {
      continue;
    }

    grouped.putIfAbsent(log.endNo, () => <BocciaThrowLog>[]).add(
          log.copyWith(
            boxNo: normalizedBoxNo,
          ),
        );
  }

  final endNos = grouped.keys.toList(growable: false)..sort();
  final normalized = <BocciaThrowLog>[];

  for (final endNo in endNos) {
    final logs = grouped[endNo]!;
    for (var index = 0; index < logs.length && index < 12; index += 1) {
      normalized.add(
        logs[index].copyWith(
          endNo: endNo,
          throwNo: index + 1,
        ),
      );
    }
  }

  return List<BocciaThrowLog>.unmodifiable(normalized);
}

List<BocciaThrowingBoxAssignment> _initialThrowingBoxAssignments({
  required List<int> redPlayerSlots,
  required List<int> bluePlayerSlots,
}) {
  final assignments = _emptyThrowingBoxAssignments().toList(growable: true);

  void assign({
    required BocciaThrowingSide side,
    required List<int> playerSlots,
  }) {
    final normalizedPlayerSlots = playerSlots
        .map(_normalizePlayerSlot)
        .whereType<int>()
        .toList(growable: false);
    final boxNos = _preferredThrowingBoxNos(
      side: side,
      playerCount: normalizedPlayerSlots.length,
    );

    for (var index = 0;
        index < normalizedPlayerSlots.length && index < boxNos.length;
        index += 1) {
      final boxNo = boxNos[index];
      final assignmentIndex = assignments.indexWhere(
        (assignment) => assignment.boxNo == boxNo,
      );

      if (assignmentIndex < 0) {
        continue;
      }

      assignments[assignmentIndex] = assignments[assignmentIndex].copyWith(
        playerSlot: normalizedPlayerSlots[index],
      );
    }
  }

  assign(
    side: BocciaThrowingSide.red,
    playerSlots: redPlayerSlots,
  );
  assign(
    side: BocciaThrowingSide.blue,
    playerSlots: bluePlayerSlots,
  );

  return List<BocciaThrowingBoxAssignment>.unmodifiable(assignments);
}

List<BocciaThrowingBoxAssignment> _emptyThrowingBoxAssignments() {
  return List<BocciaThrowingBoxAssignment>.unmodifiable(
    List<BocciaThrowingBoxAssignment>.generate(
      6,
      (index) => BocciaThrowingBoxAssignment.empty(boxNo: index + 1),
    ),
  );
}

List<BocciaThrowingBoxAssignment> _normalizeThrowingBoxAssignments(
  List<BocciaThrowingBoxAssignment> source,
) {
  final sourceByBoxNo = <int, BocciaThrowingBoxAssignment>{
    for (final assignment in source)
      if (_normalizeThrowingBoxNo(assignment.boxNo) != null)
        assignment.boxNo: assignment,
  };

  return List<BocciaThrowingBoxAssignment>.unmodifiable(
    List<BocciaThrowingBoxAssignment>.generate(
      6,
      (index) {
        final boxNo = index + 1;
        final source = sourceByBoxNo[boxNo];

        if (source == null) {
          return BocciaThrowingBoxAssignment.empty(boxNo: boxNo);
        }

        return BocciaThrowingBoxAssignment(
          boxNo: boxNo,
          side: _throwingSideForBoxNo(boxNo),
          playerSlot: _normalizePlayerSlot(source.playerSlot),
        );
      },
    ),
  );
}

List<BocciaThrowingBoxAssignment> _swapThrowingBoxAssignments(
  List<BocciaThrowingBoxAssignment> source,
) {
  final normalized = _normalizeThrowingBoxAssignments(source);

  final nextRedPlayerSlots = normalized
      .where((assignment) => assignment.side == BocciaThrowingSide.blue)
      .map((assignment) => assignment.playerSlot)
      .whereType<int>()
      .toList(growable: false);

  final nextBluePlayerSlots = normalized
      .where((assignment) => assignment.side == BocciaThrowingSide.red)
      .map((assignment) => assignment.playerSlot)
      .whereType<int>()
      .toList(growable: false);

  return _initialThrowingBoxAssignments(
    redPlayerSlots: nextRedPlayerSlots,
    bluePlayerSlots: nextBluePlayerSlots,
  );
}

List<int> _preferredThrowingBoxNos({
  required BocciaThrowingSide side,
  required int playerCount,
}) {
  if (playerCount <= 0) {
    return const <int>[];
  }

  return switch (side) {
    BocciaThrowingSide.red => switch (playerCount) {
        1 => const <int>[3],
        2 => const <int>[3, 5],
        _ => const <int>[1, 3, 5],
      },
    BocciaThrowingSide.blue => switch (playerCount) {
        1 => const <int>[4],
        2 => const <int>[2, 4],
        _ => const <int>[2, 4, 6],
      },
  };
}

int _swappedThrowingBoxNo(int boxNo) {
  return switch (boxNo) {
    1 => 2,
    2 => 1,
    3 => 4,
    4 => 3,
    5 => 6,
    6 => 5,
    _ => boxNo,
  };
}

BocciaThrowingSide _throwingSideForBoxNo(int boxNo) {
  return boxNo.isOdd ? BocciaThrowingSide.red : BocciaThrowingSide.blue;
}

int? _normalizeThrowingBoxNo(Object? value) {
  final boxNo = _readInt(value);
  if (boxNo < 1 || boxNo > 6) {
    return null;
  }

  return boxNo;
}

int? _normalizePlayerSlot(Object? value) {
  final playerSlot = _readInt(value);
  if (playerSlot <= 0) {
    return null;
  }

  return playerSlot;
}

Map<String, dynamic> _readObject(Object? value) {
  if (value is! Map) {
    return const <String, dynamic>{};
  }

  return <String, dynamic>{
    for (final entry in value.entries) entry.key.toString(): entry.value,
  };
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
