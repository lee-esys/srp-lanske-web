import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srp_lanske/app/config/app_config.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/public_id.dart';
import 'package:srp_lanske/features/doubles_scheduler/infrastructure/generated_schedule_api_client.dart';
import 'package:srp_lanske/l10n/l10n.dart';
import 'package:srp_lanske/shared/repositories/app_repositories.dart';

import '../application/team_generated_schedule_service.dart';
import '../domain/saved_team_schedule.dart';
import '../domain/team_generated_schedule.dart';
import 'models/team_setup_draft.dart';

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

  _TeamScheduleViewData? _schedule;
  String? _errorMessage;
  bool _isLoading = true;
  bool _isSavingDisplay = false;
  String? _displaySaveErrorMessage;

  String _eventTitle = '';
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

      setState(() {
        _schedule = schedule;
        _eventTitle = saved.display.eventTitle;
        _teamDisplayNames = saved.display.teamNames;
        _memberDisplayNames = saved.display.memberNames;
        _selectedTeamSlot = schedule.teams.first.teamSlot;
        _shareId = saved.shareId;
        _shareUrl = _buildShareUrl(saved.shareId);
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

      setState(() {
        _schedule = schedule;
        _eventTitle = saved.display.eventTitle.isEmpty
            ? schedule.eventTitle
            : saved.display.eventTitle;
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

  SavedTeamScheduleDisplay _currentDisplay() {
    return SavedTeamScheduleDisplay(
      eventTitle: _eventTitle,
      teamNames: Map<int, String>.unmodifiable(_teamDisplayNames),
      memberNames: Map<int, String>.unmodifiable(_memberDisplayNames),
    );
  }

  Future<void> _saveCurrentDisplay() async {
    final shareId = _shareId;
    if (shareId == null || shareId.isEmpty) {
      return;
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
        return;
      }

      setState(() {
        _eventTitle = saved.display.eventTitle;
        _teamDisplayNames = saved.display.teamNames;
        _memberDisplayNames = saved.display.memberNames;
        _isSavingDisplay = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _displaySaveErrorMessage = _formatError(error);
        _isSavingDisplay = false;
      });
    }
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

  Future<void> _editEventTitle() async {
    final l10n = AppLocalizations.of(context);

    await _editDisplayName(
      dialogTitle: l10n.editTeamScheduleEventTitleDialogTitle,
      initialValue: _eventTitle,
      onSaved: (value) {
        _eventTitle = value;
      },
    );
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
                IconButton(
                  tooltip: l10n.editTeamScheduleEventTitleTooltip,
                  onPressed: _editEventTitle,
                  icon: const Icon(Icons.edit_outlined),
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
            const SizedBox(height: 8),
            Text(
              l10n.teamScheduleBackendDataNotice,
              style: theme.textTheme.bodySmall,
            ),
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

  Widget _buildShareCard(BuildContext context) {
    final theme = Theme.of(context);
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.teamScheduleShareTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(l10n.teamScheduleShareDescription),
            const SizedBox(height: 12),
            SelectableText(
              l10n.teamScheduleShareIdLabel(shareId),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            SelectableText(shareUrl),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _copyShareUrl,
              icon: const Icon(Icons.copy),
              label: Text(l10n.copyTeamScheduleShareUrlButton),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextRoundCard(BuildContext context) {
    final schedule = _schedule!;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final nextRound = schedule.rounds.firstWhere(
      (round) => round.roundNo == schedule.nextRoundNo,
      orElse: () => schedule.rounds.first,
    );

    return Card(
      elevation: 0,
      color: Colors.blue.shade100,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.nextTeamMatchTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.teamRoundTitle(nextRound.roundNo),
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            for (final match in nextRound.matches) ...[
              Text(
                l10n.teamCourtMatchTitle(
                  courtNo: match.courtNo,
                  matchTitle: _matchTitle(context, match),
                ),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (match != nextRound.matches.last) const SizedBox(height: 4),
            ],
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
    final schedule = _schedule!;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isNextRound = round.roundNo == schedule.nextRoundNo;

    return Card(
      elevation: 0,
      color: isNextRound ? Colors.blue.shade50 : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isNextRound ? Colors.blue.shade300 : Colors.transparent,
        ),
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
                if (isNextRound) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: Text(l10n.nextTeamMatchTitle),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: Colors.blue.shade100,
                  ),
                ],
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

  Widget _buildMatchRow(BuildContext context, _TeamMatchViewData match) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

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
              ActionChip(
                label: Text(_teamName(teamSlot)),
                avatar: teamSlot == _selectedTeamSlot
                    ? const Icon(Icons.check, size: 18)
                    : null,
                onPressed: () => _selectTeam(teamSlot),
              ),
          ],
        ),
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
        _buildNextRoundCard(context),
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
