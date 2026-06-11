import 'package:flutter/material.dart';

import 'models/team_setup_draft.dart';

class TeamSchedulePage extends StatefulWidget {
  const TeamSchedulePage({
    required this.draft,
    super.key,
  });

  final TeamSetupDraft draft;

  @override
  State<TeamSchedulePage> createState() => _TeamSchedulePageState();
}

class _TeamSchedulePageState extends State<TeamSchedulePage> {
  late final _MockTeamSchedule _schedule;
  late String _selectedTeamId;

  @override
  void initState() {
    super.initState();

    _schedule = _buildMockSchedule(widget.draft);
    _selectedTeamId = _schedule.teams.first.id;
  }

  _MockTeamSchedule _buildMockSchedule(TeamSetupDraft draft) {
    final participantCount = draft.participantCount;
    final preferredTeamSize =
        draft.preferredTeamSize.clamp(1, participantCount);
    final teamCount = (participantCount / preferredTeamSize)
        .ceil()
        .clamp(1, participantCount)
        .toInt();

    final memberNames = List<String>.generate(participantCount, (index) {
      if (index < draft.participantNames.length) {
        final name = draft.participantNames[index].trim();
        if (name.isNotEmpty) {
          return name;
        }
      }

      return '参加者${index + 1}';
    }, growable: false);

    final members = List<_MockTeamMember>.generate(
      participantCount,
      (index) => _MockTeamMember(
        id: 'member-${index + 1}',
        displayName: memberNames[index],
      ),
      growable: false,
    );

    final baseMemberCount = participantCount ~/ teamCount;
    final remainder = participantCount % teamCount;
    var memberIndex = 0;

    final teams = List<_MockTeam>.generate(teamCount, (teamIndex) {
      final memberCount =
          teamIndex < remainder ? baseMemberCount + 1 : baseMemberCount;
      final memberIds = members
          .skip(memberIndex)
          .take(memberCount)
          .map((member) => member.id)
          .toList(growable: false);

      memberIndex += memberCount;

      return _MockTeam(
        id: 'team-${teamIndex + 1}',
        displayName: 'チーム${teamIndex + 1}',
        memberIds: memberIds,
      );
    }, growable: false);

    final effectiveTeamsPerMatch =
        teamCount <= 1 ? 1 : draft.teamsPerMatch.clamp(2, teamCount).toInt();
    final effectiveConcurrentMatchCount =
        draft.concurrentMatchCount.clamp(1, teamCount).toInt();

    final rounds = List<_MockTeamRound>.generate(6, (roundIndex) {
      final matches = List<_MockTeamMatch>.generate(
        effectiveConcurrentMatchCount,
        (matchIndex) {
          final startTeamIndex = (roundIndex *
                      effectiveConcurrentMatchCount *
                      effectiveTeamsPerMatch +
                  matchIndex * effectiveTeamsPerMatch) %
              teamCount;

          final teamIds = List<String>.generate(
            effectiveTeamsPerMatch,
            (offset) => teams[(startTeamIndex + offset) % teamCount].id,
            growable: false,
          );

          return _MockTeamMatch(
            courtNo: matchIndex + 1,
            teamIds: teamIds,
          );
        },
        growable: false,
      );

      return _MockTeamRound(
        roundNo: roundIndex + 1,
        matches: matches,
      );
    }, growable: false);

    return _MockTeamSchedule(
      eventTitle: 'チーム練習会',
      members: members,
      teams: teams,
      rounds: rounds,
      nextRoundNo: 1,
    );
  }

  Map<String, _MockTeam> get _teamById => {
        for (final team in _schedule.teams) team.id: team,
      };

  Map<String, _MockTeamMember> get _memberById => {
        for (final member in _schedule.members) member.id: member,
      };

  _MockTeam get _selectedTeam => _teamById[_selectedTeamId]!;

  String _teamName(String teamId) {
    return _teamById[teamId]?.displayName ?? teamId;
  }

  String _memberName(String memberId) {
    return _memberById[memberId]?.displayName ?? memberId;
  }

  String _matchTitle(_MockTeamMatch match) {
    final teamNames = match.teamIds.map(_teamName).toList(growable: false);

    if (teamNames.length == 2) {
      return '${teamNames[0]} vs ${teamNames[1]}';
    }

    return teamNames.join(' / ');
  }

  void _selectTeam(String teamId) {
    setState(() {
      _selectedTeamId = teamId;
    });
  }

  Widget _buildHeaderCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _schedule.eventTitle,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_schedule.teams.length}チーム / '
              '${_schedule.members.length}人 / '
              '${widget.draft.concurrentMatchCount}同時進行',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'backend API 接続前のため、表示内容はセットアップ条件から作成したモックデータです。',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextRoundCard(BuildContext context) {
    final theme = Theme.of(context);
    final nextRound = _schedule.rounds.firstWhere(
      (round) => round.roundNo == _schedule.nextRoundNo,
      orElse: () => _schedule.rounds.first,
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
              '次の対戦',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '第${nextRound.roundNo}ラウンド',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            for (final match in nextRound.matches) ...[
              Text(
                'コート${match.courtNo}: ${_matchTitle(match)}',
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
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'チーム一覧',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final team in _schedule.teams)
                  ChoiceChip(
                    label: Text(
                      '${team.displayName} (${team.memberIds.length}人)',
                    ),
                    selected: team.id == _selectedTeamId,
                    onSelected: (_) => _selectTeam(team.id),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedTeamMembersCard(BuildContext context) {
    final theme = Theme.of(context);
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
              '${team.displayName} のメンバー',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            for (final memberId in team.memberIds)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.person_outline),
                title: Text(_memberName(memberId)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoundList(BuildContext context) {
    return Column(
      children: [
        for (final round in _schedule.rounds) ...[
          _buildRoundCard(context, round),
          if (round != _schedule.rounds.last) const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _buildRoundCard(BuildContext context, _MockTeamRound round) {
    final theme = Theme.of(context);
    final isNextRound = round.roundNo == _schedule.nextRoundNo;

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
                  '第${round.roundNo}ラウンド',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (isNextRound) ...[
                  const SizedBox(width: 8),
                  Chip(
                    label: const Text('次の対戦'),
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

  Widget _buildMatchRow(BuildContext context, _MockTeamMatch match) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'コート${match.courtNo}',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 6),
        Text(
          _matchTitle(match),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final teamId in match.teamIds)
              ActionChip(
                label: Text(_teamName(teamId)),
                avatar: teamId == _selectedTeamId
                    ? const Icon(Icons.check, size: 18)
                    : null,
                onPressed: () => _selectTeam(teamId),
              ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        scaffoldBackgroundColor: Colors.blue.shade50,
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('チーム対戦表'),
          backgroundColor: Colors.blue.shade100,
          foregroundColor: Colors.black87,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              _buildHeaderCard(context),
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
          ),
        ),
      ),
    );
  }
}

class _MockTeamSchedule {
  const _MockTeamSchedule({
    required this.eventTitle,
    required this.members,
    required this.teams,
    required this.rounds,
    required this.nextRoundNo,
  });

  final String eventTitle;
  final List<_MockTeamMember> members;
  final List<_MockTeam> teams;
  final List<_MockTeamRound> rounds;
  final int nextRoundNo;
}

class _MockTeamMember {
  const _MockTeamMember({
    required this.id,
    required this.displayName,
  });

  final String id;
  final String displayName;
}

class _MockTeam {
  const _MockTeam({
    required this.id,
    required this.displayName,
    required this.memberIds,
  });

  final String id;
  final String displayName;
  final List<String> memberIds;
}

class _MockTeamRound {
  const _MockTeamRound({
    required this.roundNo,
    required this.matches,
  });

  final int roundNo;
  final List<_MockTeamMatch> matches;
}

class _MockTeamMatch {
  const _MockTeamMatch({
    required this.courtNo,
    required this.teamIds,
  });

  final int courtNo;
  final List<String> teamIds;
}
