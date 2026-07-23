import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srp_lanske/app/config/app_config.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/public_id.dart';
import 'package:srp_lanske/features/doubles_scheduler/infrastructure/generated_schedule_api_client.dart';
import 'package:srp_lanske/l10n/l10n.dart';
import 'package:srp_lanske/shared/repositories/app_repositories.dart';

import '../application/team_generated_schedule_service.dart';
import '../data/local_team_schedule_history_item.dart';
import '../data/local_team_schedule_history_store.dart';
import '../domain/boccia_score.dart';
import '../domain/saved_team_schedule.dart';
import '../domain/team_generated_schedule.dart';
import 'models/team_setup_draft.dart';
import 'team_navigation_drawer.dart';
import 'widgets/boccia_score_dialog.dart';

enum _TeamSchedulePageMode {
  create,
  restore,
}

class TeamSchedulePage extends StatefulWidget {
  const TeamSchedulePage.create({
    required TeamSetupDraft draft,
    super.key,
  })  : _mode = _TeamSchedulePageMode.create,
        _draft = draft,
        _shareId = null;

  const TeamSchedulePage.restore({
    required String shareId,
    super.key,
  })  : _mode = _TeamSchedulePageMode.restore,
        _draft = null,
        _shareId = shareId;

  final _TeamSchedulePageMode _mode;
  final TeamSetupDraft? _draft;
  final String? _shareId;

  @override
  State<TeamSchedulePage> createState() => _TeamSchedulePageState();
}

class _TeamSchedulePageState extends State<TeamSchedulePage> {
  late final TeamGeneratedScheduleService _service;
  final LocalTeamScheduleHistoryStore _historyStore =
      LocalTeamScheduleHistoryStore();

  _TeamScheduleViewData? _schedule;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isSavingDisplay = false;
  String? _displaySaveErrorMessage;

  TeamScheduleScores _scores = const TeamScheduleScores.empty();
  bool _isSavingScores = false;
  bool _isRefreshingScores = false;
  String? _scoresSaveErrorMessage;

  String _eventTitle = '';
  String _memo = '';
  Map<int, String> _teamDisplayNames = const {};
  Map<int, String> _memberDisplayNames = const {};
  int? _selectedTeamSlot;
  String? _shareId;
  String? _shareUrl;

  bool get _isRestoreMode => widget._mode == _TeamSchedulePageMode.restore;

  @override
  void initState() {
    super.initState();

    _service = TeamGeneratedScheduleService(
      GeneratedScheduleApiClient(
        baseUrl: AppConfig.coreApiBaseUrl,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }

      if (_isRestoreMode) {
        _restoreSchedule();
      } else {
        _generateSchedule();
      }
    });
  }

  Map<int, _TeamViewData> get _teamBySlot {
    final schedule = _schedule;
    if (schedule == null) {
      return const {};
    }

    return {
      for (final team in schedule.teams) team.teamSlot: team,
    };
  }

  Map<int, _TeamMemberViewData> get _memberBySlot {
    final schedule = _schedule;
    if (schedule == null) {
      return const {};
    }

    return {
      for (final member in schedule.members) member.playerSlot: member,
    };
  }

  _TeamViewData get _selectedTeam {
    final schedule = _schedule!;
    final selectedTeamSlot = _selectedTeamSlot;

    if (selectedTeamSlot == null) {
      return schedule.teams.first;
    }

    return _teamBySlot[selectedTeamSlot] ?? schedule.teams.first;
  }

  Future<void> _generateSchedule() async {
    final draft = widget._draft;
    if (draft == null) {
      setState(() {
        _errorMessage = 'missing team setup draft';
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _displaySaveErrorMessage = null;
    });

    try {
      final generated = await _service.generateFromDraft(draft);

      if (!mounted) {
        return;
      }

      final l10n = AppLocalizations.of(context);
      final schedule = _buildViewData(
        generated: generated,
        l10n: l10n,
        draft: draft,
      );

      final teamNames = {
        for (final team in schedule.teams) team.teamSlot: team.displayName,
      };
      final memberNames = {
        for (final member in schedule.members)
          member.playerSlot: member.displayName,
      };

      final saved = await appTeamScheduleRepository.createFromGenerated(
        draft: draft,
        generated: generated,
        eventTitle: schedule.eventTitle,
        teamNames: teamNames,
        memberNames: memberNames,
      );

      if (!mounted) {
        return;
      }

      await _upsertLocalHistory(saved: saved, schedule: schedule);

      if (!mounted) {
        return;
      }

      setState(() {
        _schedule = schedule;
        _eventTitle = saved.display.eventTitle;
        _memo = saved.display.memo;
        _teamDisplayNames = saved.display.teamNames;
        _memberDisplayNames = saved.display.memberNames;
        _selectedTeamSlot = schedule.teams.first.teamSlot;
        _shareId = saved.shareId;
        _shareUrl = _buildShareUrl(saved.shareId);
        _scores = TeamScheduleScores.fromJson(saved.scores);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _formatError(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _restoreSchedule() async {
    final rawShareId = widget._shareId?.trim().toUpperCase() ?? '';

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _displaySaveErrorMessage = null;
    });

    try {
      if (!isValidPublicId(rawShareId)) {
        throw FormatException('invalid share id: $rawShareId');
      }

      final saved = await appTeamScheduleRepository.findByShareId(rawShareId);
      if (saved == null) {
        throw StateError('team schedule not found: $rawShareId');
      }

      final generated = TeamGeneratedSchedule.fromJson(saved.snapshot);

      if (!mounted) {
        return;
      }

      final schedule = _buildViewData(
        generated: generated,
        l10n: AppLocalizations.of(context),
        savedSetup: saved.setup,
      );

      await _upsertLocalHistory(saved: saved, schedule: schedule);

      if (!mounted) {
        return;
      }

      setState(() {
        _schedule = schedule;
        _eventTitle = saved.display.eventTitle.isEmpty
            ? schedule.eventTitle
            : saved.display.eventTitle;
        _memo = saved.display.memo;
        _teamDisplayNames = saved.display.teamNames.isEmpty
            ? {
                for (final team in schedule.teams)
                  team.teamSlot: team.displayName,
              }
            : saved.display.teamNames;
        _memberDisplayNames = saved.display.memberNames.isEmpty
            ? {
                for (final member in schedule.members)
                  member.playerSlot: member.displayName,
              }
            : saved.display.memberNames;
        _selectedTeamSlot = schedule.teams.first.teamSlot;
        _shareId = saved.shareId;
        _shareUrl = _buildShareUrl(saved.shareId);
        _scores = TeamScheduleScores.fromJson(saved.scores);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = _formatError(error);
        _isLoading = false;
      });
    }
  }

  String _formatError(Object error) {
    if (error is CoreApiException) {
      return 'HTTP ${error.statusCode}: ${error.message}';
    }

    return error.toString();
  }

  String _buildShareUrl(String shareId) {
    final base = Uri.base;

    return base
        .replace(
          path: '/team/schedules/$shareId',
          queryParameters: const <String, String>{},
          fragment: '',
        )
        .toString();
  }

  Future<void> _upsertLocalHistory({
    required SavedTeamSchedule saved,
    required _TeamScheduleViewData schedule,
  }) async {
    final eventTitle = saved.display.eventTitle.trim().isEmpty
        ? schedule.eventTitle
        : saved.display.eventTitle.trim();

    await _historyStore.upsert(
      LocalTeamScheduleHistoryItem(
        shareId: saved.shareId,
        eventTitle: eventTitle,
        teamCount: schedule.teams.length,
        memberCount: schedule.members.length,
        hasMemo: saved.display.memo.trim().isNotEmpty,
        createdAt: saved.createdAt,
        firstSavedAt: saved.createdAt,
        updatedAt: saved.updatedAt,
      ),
    );
  }

  _TeamScheduleViewData _buildViewData({
    required TeamGeneratedSchedule generated,
    required AppLocalizations l10n,
    TeamSetupDraft? draft,
    SavedTeamScheduleSetup? savedSetup,
  }) {
    final sortedGeneratedTeams = generated.teams.toList(growable: false)
      ..sort((a, b) => a.teamSlot.compareTo(b.teamSlot));

    if (sortedGeneratedTeams.isEmpty) {
      throw const FormatException('team generate response has no teams');
    }

    final playerSlots = generated.players
        .map((player) => player.playerSlot)
        .where((slot) => slot > 0)
        .toSet()
        .toList(growable: false)
      ..sort();

    final fallbackPlayerCount = generated.playerCount > 0
        ? generated.playerCount
        : draft?.participantCount ?? savedSetup?.participantCount ?? 0;

    final effectivePlayerSlots = playerSlots.isEmpty
        ? List<int>.generate(
            fallbackPlayerCount,
            (index) => index + 1,
            growable: false,
          )
        : playerSlots;

    final members = effectivePlayerSlots.map((playerSlot) {
      return _TeamMemberViewData(
        playerSlot: playerSlot,
        displayName: _initialMemberName(playerSlot, l10n, draft),
      );
    }).toList(growable: false);

    final assignmentMemberSlotsByTeam = <int, List<int>>{};
    for (final assignment in generated.assignments) {
      assignmentMemberSlotsByTeam
          .putIfAbsent(assignment.teamSlot, () => <int>[])
          .add(assignment.playerSlot);
    }

    for (final memberSlots in assignmentMemberSlotsByTeam.values) {
      memberSlots.sort();
    }

    final teams = sortedGeneratedTeams.map((team) {
      final memberPlayerSlots = team.memberPlayerSlots.isNotEmpty
          ? team.memberPlayerSlots.toList(growable: false)
          : assignmentMemberSlotsByTeam[team.teamSlot] ?? const <int>[];

      return _TeamViewData(
        teamSlot: team.teamSlot,
        displayName: l10n.defaultTeamName(team.teamSlot),
        memberPlayerSlots: memberPlayerSlots,
      );
    }).toList(growable: false);

    final sortedGeneratedRounds = generated.rounds.toList(growable: false)
      ..sort((a, b) => a.roundNo.compareTo(b.roundNo));

    final rounds = sortedGeneratedRounds.map((round) {
      final sortedCourts = round.courts.toList(growable: false)
        ..sort((a, b) {
          final courtCompare = a.courtNo.compareTo(b.courtNo);
          if (courtCompare != 0) {
            return courtCompare;
          }

          return a.matchNo.compareTo(b.matchNo);
        });

      return _TeamRoundViewData(
        roundNo: round.roundNo,
        matches: sortedCourts.map((court) {
          return _TeamMatchViewData(
            courtNo: court.courtNo,
            matchNo: court.matchNo,
            teamSlots: court.teamSlots,
          );
        }).toList(growable: false),
      );
    }).toList(growable: false);

    if (rounds.isEmpty) {
      throw const FormatException('team generate response has no rounds');
    }

    return _TeamScheduleViewData(
      generatedScheduleId: generated.generatedScheduleId,
      eventTitle: l10n.defaultTeamScheduleEventTitle,
      members: members,
      teams: teams,
      rounds: rounds,
      nextRoundNo: rounds.first.roundNo,
      concurrentMatchCount: generated.courts > 0
          ? generated.courts
          : draft?.concurrentMatchCount ??
              savedSetup?.concurrentMatchCount ??
              1,
    );
  }

  String _initialMemberName(
    int playerSlot,
    AppLocalizations l10n,
    TeamSetupDraft? draft,
  ) {
    final names = draft?.participantNames ?? const <String>[];
    final index = playerSlot - 1;
    if (index >= 0 && index < names.length) {
      final name = names[index].trim();
      if (name.isNotEmpty) {
        return name;
      }
    }

    return l10n.defaultTeamMemberName(playerSlot);
  }

  String _teamName(int teamSlot) {
    return _teamDisplayNames[teamSlot] ??
        _teamBySlot[teamSlot]?.displayName ??
        'Team $teamSlot';
  }

  String _memberName(int playerSlot) {
    return _memberDisplayNames[playerSlot] ??
        _memberBySlot[playerSlot]?.displayName ??
        'Participant $playerSlot';
  }

  _TeamViewData? _teamOrNull(int teamSlot) {
    return _teamBySlot[teamSlot];
  }

  List<int> _teamMemberSlots(int teamSlot) {
    final team = _teamOrNull(teamSlot);
    if (team == null) {
      return const <int>[];
    }

    return team.memberPlayerSlots;
  }

  List<BocciaScorePlayerOption> _bocciaPlayerOptions(int teamSlot) {
    return _teamMemberSlots(teamSlot).map((playerSlot) {
      return BocciaScorePlayerOption(
        playerSlot: playerSlot,
        displayName: _memberName(playerSlot),
      );
    }).toList(growable: false);
  }

  SavedTeamScheduleDisplay _currentDisplay() {
    return SavedTeamScheduleDisplay(
      eventTitle: _eventTitle,
      teamNames: Map<int, String>.unmodifiable(_teamDisplayNames),
      memberNames: Map<int, String>.unmodifiable(_memberDisplayNames),
      memo: _memo,
    );
  }

  Future<SavedTeamSchedule?> _saveCurrentDisplay() async {
    final shareId = _shareId;
    if (shareId == null || shareId.isEmpty) {
      return null;
    }

    setState(() {
      _isSavingDisplay = true;
      _displaySaveErrorMessage = null;
    });

    try {
      final saved = await appTeamScheduleRepository.updateDisplay(
        shareId: shareId,
        display: _currentDisplay(),
      );

      if (!mounted) {
        return saved;
      }

      setState(() {
        _eventTitle = saved.display.eventTitle;
        _memo = saved.display.memo;
        _teamDisplayNames = saved.display.teamNames;
        _memberDisplayNames = saved.display.memberNames;
        _isSavingDisplay = false;
      });

      return saved;
    } catch (error) {
      if (!mounted) {
        return null;
      }

      setState(() {
        _displaySaveErrorMessage = _formatError(error);
        _isSavingDisplay = false;
      });

      return null;
    }
  }

  Future<TeamScheduleScores> _saveScores(TeamScheduleScores scores) async {
    final shareId = _shareId;
    if (shareId == null || shareId.isEmpty) {
      setState(() {
        _scores = scores;
        _scoresSaveErrorMessage = null;
      });
      return scores;
    }

    setState(() {
      _isSavingScores = true;
      _scoresSaveErrorMessage = null;
    });

    try {
      final saved = await appTeamScheduleRepository.updateScores(
        shareId: shareId,
        scores: scores.toJson(),
      );

      final savedScores = TeamScheduleScores.fromJson(saved.scores);

      if (!mounted) {
        return savedScores;
      }

      setState(() {
        _scores = savedScores;
        _isSavingScores = false;
      });

      return savedScores;
    } catch (error) {
      if (mounted) {
        setState(() {
          _scoresSaveErrorMessage = _formatError(error);
          _isSavingScores = false;
        });
      }

      rethrow;
    }
  }

  Future<TeamScheduleScores?> _refreshScores() async {
    final shareId = _shareId;
    if (shareId == null || shareId.isEmpty || _isRefreshingScores) {
      return null;
    }

    setState(() {
      _isRefreshingScores = true;
      _scoresSaveErrorMessage = null;
    });

    try {
      final saved = await appTeamScheduleRepository.findByShareId(shareId);
      if (saved == null) {
        throw StateError('team schedule not found: $shareId');
      }

      final latestScores = TeamScheduleScores.fromJson(saved.scores);

      if (!mounted) {
        return latestScores;
      }

      setState(() {
        _scores = latestScores;
        _isRefreshingScores = false;
      });

      return latestScores;
    } catch (error) {
      if (mounted) {
        setState(() {
          _scoresSaveErrorMessage = _formatError(error);
          _isRefreshingScores = false;
        });
      }

      return null;
    }
  }

  Future<void> _selectSport(TeamScheduleSport? sport) async {
    if (sport == null ||
        sport == _scores.selectedSport ||
        _isSavingScores ||
        _isRefreshingScores) {
      return;
    }

    try {
      await _saveScores(_scores.copyWith(selectedSport: sport));
    } catch (_) {
      // Error message is shown in the header card.
    }
  }

  Future<BocciaMatchScore> _saveBocciaMatchScore(
    BocciaMatchScore score,
  ) async {
    final nextScores = _scores.copyWith(
      selectedSport: TeamScheduleSport.boccia,
      boccia: _scores.boccia.upsertMatch(score),
    );

    final savedScores = await _saveScores(nextScores);

    return savedScores.boccia.matchScore(score.matchNo) ?? score;
  }

  Future<BocciaMatchScore?> _refreshBocciaMatchScore(
    BocciaMatchScore fallbackScore,
  ) async {
    final latestScores = await _refreshScores();
    if (latestScores == null) {
      return null;
    }

    return latestScores.boccia.matchScore(fallbackScore.matchNo) ??
        fallbackScore;
  }

  Future<void> _openBocciaScoreDialog(_TeamMatchViewData match) async {
    final l10n = AppLocalizations.of(context);

    if (_scores.selectedSport == TeamScheduleSport.none) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectSportBeforeScoreInputMessage)),
      );
      return;
    }

    if (_scores.selectedSport != TeamScheduleSport.boccia) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.selectSportBeforeScoreInputMessage)),
      );
      return;
    }

    if (match.teamSlots.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.unsupportedBocciaMatchMessage)),
      );
      return;
    }

    final redTeamSlot = match.teamSlots[0];
    final blueTeamSlot = match.teamSlots[1];
    final redPlayerSlots = _teamMemberSlots(redTeamSlot);
    final bluePlayerSlots = _teamMemberSlots(blueTeamSlot);

    final initialScore = _scores.boccia.matchScoreOrInitial(
      matchNo: match.matchNo,
      teamSlots: match.teamSlots,
      redPlayerSlots: redPlayerSlots,
      bluePlayerSlots: bluePlayerSlots,
    );

    await showDialog<BocciaMatchScore>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return BocciaScoreDialog(
          initialScore: initialScore,
          redTeamName: _teamName(initialScore.redTeamSlot),
          blueTeamName: _teamName(initialScore.blueTeamSlot),
          redPlayerOptions: _bocciaPlayerOptions(initialScore.redTeamSlot),
          bluePlayerOptions: _bocciaPlayerOptions(initialScore.blueTeamSlot),
          onSave: _saveBocciaMatchScore,
          onRefresh: () {
            return _refreshBocciaMatchScore(initialScore);
          },
        );
      },
    );
  }

  String _sportLabel(TeamScheduleSport sport) {
    final l10n = AppLocalizations.of(context);

    return switch (sport) {
      TeamScheduleSport.none => l10n.teamScheduleSportNoneLabel,
      TeamScheduleSport.boccia => l10n.teamScheduleSportBocciaLabel,
    };
  }

  String _matchTitle(BuildContext context, _TeamMatchViewData match) {
    final l10n = AppLocalizations.of(context);
    final teamNames = match.teamSlots.map(_teamName).toList(growable: false);

    if (teamNames.length == 2) {
      return teamNames.join(l10n.teamMatchVsSeparator);
    }

    return teamNames.join(l10n.teamMatchGroupSeparator);
  }

  void _selectTeam(int teamSlot) {
    setState(() {
      _selectedTeamSlot = teamSlot;
    });
  }

  Future<void> _copyShareUrl() async {
    final l10n = AppLocalizations.of(context);
    final shareUrl = _shareUrl;
    if (shareUrl == null || shareUrl.isEmpty) {
      return;
    }

    await Clipboard.setData(ClipboardData(text: shareUrl));

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.teamScheduleShareUrlCopiedMessage)),
    );
  }

  Future<void> _editDisplayName({
    required String dialogTitle,
    required String initialValue,
    required ValueChanged<String> onSaved,
  }) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: initialValue);

    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(dialogTitle),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(
              labelText: l10n.displayNameInputLabel,
            ),
            textInputAction: TextInputAction.done,
            onSubmitted: (value) {
              Navigator.of(context).pop(value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancelDisplayNameEditButton),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Text(l10n.saveDisplayNameEditButton),
            ),
          ],
        );
      },
    );

    controller.dispose();

    final trimmed = result?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return;
    }

    setState(() {
      onSaved(trimmed);
    });

    await _saveCurrentDisplay();
  }

  Future<_TeamScheduleBulkEditResult?> _showBulkEditDialog(
    BuildContext context, {
    required _TeamScheduleViewData schedule,
  }) {
    final l10n = AppLocalizations.of(context);

    final eventTitleController = TextEditingController(text: _eventTitle);
    final memoController = TextEditingController(text: _memo);

    final teamControllers = <int, TextEditingController>{
      for (final team in schedule.teams)
        team.teamSlot: TextEditingController(
          text: _teamDisplayNames[team.teamSlot] ?? team.displayName,
        ),
    };

    final memberControllers = <int, TextEditingController>{
      for (final member in schedule.members)
        member.playerSlot: TextEditingController(
          text: _memberDisplayNames[member.playerSlot] ?? member.displayName,
        ),
    };

    return showDialog<_TeamScheduleBulkEditResult>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);

        return AlertDialog(
          title: Text(l10n.teamScheduleBulkEditTitle),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: eventTitleController,
                    decoration: InputDecoration(
                      labelText: l10n.teamScheduleEventTitleLabel,
                    ),
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: memoController,
                    decoration: InputDecoration(
                      labelText: l10n.teamScheduleMemoLabel,
                      alignLabelWithHint: true,
                    ),
                    minLines: 3,
                    maxLines: 6,
                  ),
                  const SizedBox(height: 24),
                  for (final team in schedule.teams) ...[
                    Text(
                      _teamName(team.teamSlot),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: teamControllers[team.teamSlot],
                      decoration: InputDecoration(
                        labelText: l10n.teamScheduleTeamNameLabel(
                          team.teamSlot,
                        ),
                      ),
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 12),
                    for (final playerSlot in team.memberPlayerSlots) ...[
                      TextField(
                        controller: memberControllers[playerSlot],
                        decoration: InputDecoration(
                          labelText: _memberName(playerSlot),
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (team != schedule.teams.last) ...[
                      const SizedBox(height: 4),
                      const Divider(),
                      const SizedBox(height: 16),
                    ],
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(
                  _TeamScheduleBulkEditResult(
                    eventTitle: eventTitleController.text.trim(),
                    memo: memoController.text.trim(),
                    teamNames: {
                      for (final entry in teamControllers.entries)
                        entry.key: entry.value.text.trim(),
                    },
                    memberNames: {
                      for (final entry in memberControllers.entries)
                        entry.key: entry.value.text.trim(),
                    },
                  ),
                );
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    ).whenComplete(() {
      eventTitleController.dispose();
      memoController.dispose();

      for (final controller in teamControllers.values) {
        controller.dispose();
      }
      for (final controller in memberControllers.values) {
        controller.dispose();
      }
    });
  }

  Future<void> _editTeamScheduleDetails() async {
    final schedule = _schedule;
    if (schedule == null || _isSavingDisplay) {
      return;
    }

    final result = await _showBulkEditDialog(
      context,
      schedule: schedule,
    );

    if (result == null) {
      return;
    }

    setState(() {
      _eventTitle =
          result.eventTitle.isEmpty ? schedule.eventTitle : result.eventTitle;
      _memo = result.memo;
      _teamDisplayNames = Map<int, String>.unmodifiable(result.teamNames);
      _memberDisplayNames = Map<int, String>.unmodifiable(result.memberNames);
    });

    final saved = await _saveCurrentDisplay();

    if (saved != null) {
      await _upsertLocalHistory(
        saved: saved,
        schedule: schedule,
      );
    }
  }

  Future<void> _editTeamName(int teamSlot) async {
    final l10n = AppLocalizations.of(context);

    await _editDisplayName(
      dialogTitle: l10n.editTeamNameDialogTitle(_teamName(teamSlot)),
      initialValue: _teamName(teamSlot),
      onSaved: (value) {
        _teamDisplayNames = {
          ..._teamDisplayNames,
          teamSlot: value,
        };
      },
    );
  }

  Future<void> _editMemberName(int playerSlot) async {
    final l10n = AppLocalizations.of(context);

    await _editDisplayName(
      dialogTitle: l10n.editTeamMemberNameDialogTitle(_memberName(playerSlot)),
      initialValue: _memberName(playerSlot),
      onSaved: (value) {
        _memberDisplayNames = {
          ..._memberDisplayNames,
          playerSlot: value,
        };
      },
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    final schedule = _schedule!;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    _eventTitle,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _isSavingDisplay ? null : _editTeamScheduleDetails,
                  icon: Icon(
                    _memo.trim().isEmpty
                        ? Icons.edit_outlined
                        : Icons.edit_note_outlined,
                  ),
                  label: Text(l10n.teamScheduleBulkEditButton),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              l10n.teamScheduleSummary(
                teamCount: schedule.teams.length,
                memberCount: schedule.members.length,
                concurrentMatchCount: schedule.concurrentMatchCount,
              ),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            _buildSportSelector(context),
            if (_isSavingDisplay || _displaySaveErrorMessage != null) ...[
              const SizedBox(height: 8),
              _buildDisplaySaveStatus(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDisplaySaveStatus(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final error = _displaySaveErrorMessage;

    if (_isSavingDisplay) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            l10n.savingTeamScheduleDisplayMessage,
            style: theme.textTheme.bodySmall,
          ),
        ],
      );
    }

    if (error != null && error.isNotEmpty) {
      return Text(
        l10n.teamScheduleDisplaySaveFailedMessage(error),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildScoreSaveStatus(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final error = _scoresSaveErrorMessage;

    if (_isSavingScores) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            l10n.savingTeamScheduleScoresMessage,
            style: theme.textTheme.bodySmall,
          ),
        ],
      );
    }

    if (_isRefreshingScores) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            l10n.refreshingTeamScheduleScoresMessage,
            style: theme.textTheme.bodySmall,
          ),
        ],
      );
    }

    if (error != null && error.isNotEmpty) {
      return Text(
        l10n.teamScheduleScoresSaveFailedMessage(error),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildSportSelector(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              l10n.teamScheduleSportSectionTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<TeamScheduleSport>(
                initialValue: _scores.selectedSport,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                onChanged: _isSavingScores || _isRefreshingScores
                    ? null
                    : _selectSport,
                items: [
                  for (final sport in TeamScheduleSport.values)
                    DropdownMenuItem<TeamScheduleSport>(
                      value: sport,
                      child: Text(_sportLabel(sport)),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (_isSavingScores ||
            _isRefreshingScores ||
            _scoresSaveErrorMessage != null) ...[
          const SizedBox(height: 8),
          _buildScoreSaveStatus(context),
        ],
      ],
    );
  }

  Widget _buildShareCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final shareId = _shareId;
    final shareUrl = _shareUrl;

    if (shareId == null || shareUrl == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.tonalIcon(
              onPressed: _copyShareUrl,
              icon: const Icon(Icons.copy),
              label: Text(l10n.copyTeamScheduleShareUrlButton),
            ),
            FilledButton.tonalIcon(
              onPressed: _isRefreshingScores ? null : _refreshScores,
              icon: const Icon(Icons.refresh),
              label: Text(l10n.refreshLatestTeamScheduleButton),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamListCard(BuildContext context) {
    final schedule = _schedule!;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.teamListTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final team in schedule.teams)
                  _buildTeamSelectionChip(context, team),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSelectionChip(BuildContext context, _TeamViewData team) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isSelected = team.teamSlot == _selectedTeamSlot;

    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: isSelected ? Colors.blue.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _selectTeam(team.teamSlot),
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(Icons.check, size: 18),
                const SizedBox(width: 4),
              ],
              Text(
                l10n.teamChoiceLabel(
                  teamName: _teamName(team.teamSlot),
                  memberCount: team.memberPlayerSlots.length,
                ),
                style: theme.textTheme.bodyMedium,
              ),
              IconButton(
                tooltip: l10n.editTeamNameTooltip,
                visualDensity: VisualDensity.compact,
                onPressed: () => _editTeamName(team.teamSlot),
                icon: const Icon(Icons.edit_outlined, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedTeamMembersCard(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final team = _selectedTeam;

    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.selectedTeamMembersTitle(_teamName(team.teamSlot)),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            for (final playerSlot in team.memberPlayerSlots)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline),
                title: Text(_memberName(playerSlot)),
                trailing: IconButton(
                  tooltip: l10n.editTeamMemberNameTooltip,
                  onPressed: () => _editMemberName(playerSlot),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundList(BuildContext context) {
    final schedule = _schedule!;

    return Column(
      children: [
        for (final round in schedule.rounds) ...[
          _buildRoundCard(context, round),
          if (round != schedule.rounds.last) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildRoundCard(BuildContext context, _TeamRoundViewData round) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  l10n.teamRoundTitle(round.roundNo),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (final match in round.matches) ...[
              _buildMatchRow(context, match),
              if (match != round.matches.last) const Divider(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMatchScoreAction(
    BuildContext context,
    _TeamMatchViewData match,
  ) {
    final l10n = AppLocalizations.of(context);
    final score = _scores.boccia.matchScore(match.matchNo);
    final hasScore = score?.hasAnyScore ?? false;

    return FilledButton.tonalIcon(
      onPressed: _isSavingScores || _isRefreshingScores
          ? null
          : () {
              _openBocciaScoreDialog(match);
            },
      icon: const Icon(Icons.edit_note),
      label: Text(
        hasScore ? l10n.editBocciaScoreButton : l10n.inputBocciaScoreButton,
      ),
    );
  }

  ({int firstTeamSlot, int secondTeamSlot, int? firstScore, int? secondScore})
      _matchDisplayOrder(_TeamMatchViewData match) {
    final score = _scores.boccia.matchScore(match.matchNo);

    if (_scores.selectedSport == TeamScheduleSport.boccia &&
        score != null &&
        match.teamSlots.length == 2) {
      return (
        firstTeamSlot: score.redTeamSlot,
        secondTeamSlot: score.blueTeamSlot,
        firstScore: score.totalRedScore,
        secondScore: score.totalBlueScore,
      );
    }

    return (
      firstTeamSlot: match.teamSlots[0],
      secondTeamSlot:
          match.teamSlots.length > 1 ? match.teamSlots[1] : match.teamSlots[0],
      firstScore: null,
      secondScore: null,
    );
  }

  Widget _buildMatchTeamPill(
    BuildContext context, {
    required int teamSlot,
  }) {
    final theme = Theme.of(context);
    final isSelected = teamSlot == _selectedTeamSlot;

    return ActionChip(
      label: Text(
        _teamName(teamSlot),
        overflow: TextOverflow.ellipsis,
      ),
      avatar: isSelected ? const Icon(Icons.check, size: 18) : null,
      onPressed: () => _selectTeam(teamSlot),
      backgroundColor: isSelected ? Colors.blue.shade50 : null,
      side: BorderSide(
        color: isSelected ? Colors.blue.shade300 : Colors.grey.shade300,
      ),
      labelStyle: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: isSelected ? FontWeight.w600 : null,
      ),
    );
  }

  Widget _buildMatchScorePill(
    BuildContext context, {
    required int? score,
  }) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minWidth: 36),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: Text(
          score?.toString() ?? '-',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildMatchRow(BuildContext context, _TeamMatchViewData match) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final display = _matchDisplayOrder(match);
    final supportsInlineScore = match.teamSlots.length == 2;

    if (!supportsInlineScore) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.teamCourtTitle(match.courtNo),
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 6),
          Text(
            _matchTitle(context, match),
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final teamSlot in match.teamSlots)
                _buildMatchTeamPill(context, teamSlot: teamSlot),
            ],
          ),
          const SizedBox(height: 12),
          _buildMatchScoreAction(context, match),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.teamCourtTitle(match.courtNo),
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _buildMatchTeamPill(
              context,
              teamSlot: display.firstTeamSlot,
            ),
            _buildMatchScorePill(
              context,
              score: display.firstScore,
            ),
            Text(
              'vs',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            _buildMatchScorePill(
              context,
              score: display.secondScore,
            ),
            _buildMatchTeamPill(
              context,
              teamSlot: display.secondTeamSlot,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildMatchScoreAction(context, match),
      ],
    );
  }

  Widget _buildLoadingBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final message = _isRestoreMode
        ? l10n.restoringTeamScheduleMessage
        : l10n.creatingTeamScheduleMessage;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBody(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final message = _errorMessage ?? '';

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          elevation: 0,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isRestoreMode
                      ? l10n.teamScheduleRestoreFailedTitle
                      : l10n.teamScheduleGenerateFailedTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _isRestoreMode
                      ? l10n.teamScheduleRestoreFailedBody(message)
                      : l10n.teamScheduleGenerateFailedBody(message),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed:
                      _isRestoreMode ? _restoreSchedule : _generateSchedule,
                  icon: const Icon(Icons.refresh),
                  label: Text(
                    _isRestoreMode
                        ? l10n.retryTeamScheduleRestoreButton
                        : l10n.retryTeamScheduleGenerateButton,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleBody(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildHeaderCard(context),
        const SizedBox(height: 12),
        _buildShareCard(context),
        const SizedBox(height: 12),
        _buildTeamListCard(context),
        const SizedBox(height: 12),
        _buildSelectedTeamMembersCard(context),
        const SizedBox(height: 16),
        _buildRoundList(context),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingBody(context);
    }

    if (_errorMessage != null || _schedule == null) {
      return _buildErrorBody(context);
    }

    return _buildScheduleBody(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: Colors.blue.shade50,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.teamScheduleTitle),
          backgroundColor: Colors.blue.shade100,
          foregroundColor: Colors.black87,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          actions: [
            Builder(
              builder: (context) {
                return IconButton(
                  tooltip: l10n.teamNavigationMenuTooltip,
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                  icon: const Icon(Icons.menu),
                );
              },
            ),
          ],
        ),
        endDrawer: TeamNavigationDrawer(
          showHomeLink: true,
          onRefreshLatestInfo: _refreshScores,
        ),
        body: SafeArea(
          child: _buildBody(context),
        ),
      ),
    );
  }
}

class _TeamScheduleViewData {
  const _TeamScheduleViewData({
    required this.generatedScheduleId,
    required this.eventTitle,
    required this.members,
    required this.teams,
    required this.rounds,
    required this.nextRoundNo,
    required this.concurrentMatchCount,
  });

  final String generatedScheduleId;
  final String eventTitle;
  final List<_TeamMemberViewData> members;
  final List<_TeamViewData> teams;
  final List<_TeamRoundViewData> rounds;
  final int nextRoundNo;
  final int concurrentMatchCount;
}

class _TeamMemberViewData {
  const _TeamMemberViewData({
    required this.playerSlot,
    required this.displayName,
  });

  final int playerSlot;
  final String displayName;
}

class _TeamScheduleBulkEditResult {
  const _TeamScheduleBulkEditResult({
    required this.eventTitle,
    required this.memo,
    required this.teamNames,
    required this.memberNames,
  });

  final String eventTitle;
  final String memo;
  final Map<int, String> teamNames;
  final Map<int, String> memberNames;
}

class _TeamViewData {
  const _TeamViewData({
    required this.teamSlot,
    required this.displayName,
    required this.memberPlayerSlots,
  });

  final int teamSlot;
  final String displayName;
  final List<int> memberPlayerSlots;
}

class _TeamRoundViewData {
  const _TeamRoundViewData({
    required this.roundNo,
    required this.matches,
  });

  final int roundNo;
  final List<_TeamMatchViewData> matches;
}

class _TeamMatchViewData {
  const _TeamMatchViewData({
    required this.courtNo,
    required this.matchNo,
    required this.teamSlots,
  });

  final int courtNo;
  final int matchNo;
  final List<int> teamSlots;
}
