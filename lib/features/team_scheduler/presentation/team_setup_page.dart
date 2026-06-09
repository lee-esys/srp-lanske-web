import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

import 'models/team_setup_draft.dart';
import 'widgets/team_setup_number_field.dart';

class TeamSetupPage extends StatefulWidget {
  const TeamSetupPage({super.key});

  @override
  State<TeamSetupPage> createState() => _TeamSetupPageState();
}

class _TeamSetupPageState extends State<TeamSetupPage> {
  static const _minConcurrentMatchCount = 1;
  static const _maxConcurrentMatchCount = 5;
  static const _minParticipantCount = 2;
  static const _maxParticipantCount = 50;
  static const _minTeamCount = 2;
  static const _maxTeamCount = 25;
  static const _minTeamsPerMatch = 2;
  static const _maxTeamsPerMatch = 25;

  int _concurrentMatchCount = 1;
  int _participantCount = 8;
  int _teamCount = 4;
  int _teamsPerMatch = 2;

  int _clampInt(int value, int minValue, int maxValue) =>
      value.clamp(minValue, maxValue).toInt();

  int get _effectiveMaxTeamCount =>
      _clampInt(_maxTeamCount, _minTeamCount, _participantCount);

  int get _effectiveMaxTeamsPerMatch => _clampInt(
        _maxTeamsPerMatch,
        _minTeamsPerMatch,
        _teamCount,
      );

  int get _minMemberCountPerTeam => _participantCount ~/ _teamCount;

  int get _maxMemberCountPerTeam =>
      (_participantCount / _teamCount).ceil().toInt();

  TeamSetupDraft get _draft => TeamSetupDraft(
        concurrentMatchCount: _concurrentMatchCount,
        participantCount: _participantCount,
        teamCount: _teamCount,
        teamsPerMatch: _teamsPerMatch,
      );

  void _syncDependentValues() {
    _teamCount = _clampInt(_teamCount, _minTeamCount, _effectiveMaxTeamCount);
    _teamsPerMatch = _clampInt(
      _teamsPerMatch,
      _minTeamsPerMatch,
      _effectiveMaxTeamsPerMatch,
    );
  }

  void _setConcurrentMatchCount(int value) {
    setState(() {
      _concurrentMatchCount = _clampInt(
        value,
        _minConcurrentMatchCount,
        _maxConcurrentMatchCount,
      );
    });
  }

  void _setParticipantCount(int value) {
    setState(() {
      _participantCount = _clampInt(
        value,
        _minParticipantCount,
        _maxParticipantCount,
      );
      _syncDependentValues();
    });
  }

  void _setTeamCount(int value) {
    setState(() {
      _teamCount = _clampInt(value, _minTeamCount, _effectiveMaxTeamCount);
      _syncDependentValues();
    });
  }

  void _setTeamsPerMatch(int value) {
    setState(() {
      _teamsPerMatch = _clampInt(
        value,
        _minTeamsPerMatch,
        _effectiveMaxTeamsPerMatch,
      );
    });
  }

  void _resetInputs() {
    setState(() {
      _concurrentMatchCount = 1;
      _participantCount = 8;
      _teamCount = 4;
      _teamsPerMatch = 2;
    });
  }

  void _submitMock() {
    final l10n = AppLocalizations.of(context);
    debugPrint(_draft.toString());
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(l10n.teamSetupCreatedMessage),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildNumberFields(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >= 760;
        final itemWidth = useTwoColumns
            ? (constraints.maxWidth - 12) / 2
            : constraints.maxWidth;

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: itemWidth,
              child: TeamSetupNumberField(
                label: l10n.concurrentMatchCountLabel,
                value: _concurrentMatchCount,
                minValue: _minConcurrentMatchCount,
                maxValue: _maxConcurrentMatchCount,
                onChanged: _setConcurrentMatchCount,
                tooltipDecrement:
                    l10n.decrementConcurrentMatchCountTooltip,
                tooltipIncrement:
                    l10n.incrementConcurrentMatchCountTooltip,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: TeamSetupNumberField(
                label: l10n.participantCountLabel,
                value: _participantCount,
                minValue: _minParticipantCount,
                maxValue: _maxParticipantCount,
                onChanged: _setParticipantCount,
                tooltipDecrement: l10n.decrementParticipantCountTooltip,
                tooltipIncrement: l10n.incrementParticipantCountTooltip,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: TeamSetupNumberField(
                label: l10n.teamCountLabel,
                value: _teamCount,
                minValue: _minTeamCount,
                maxValue: _effectiveMaxTeamCount,
                onChanged: _setTeamCount,
                tooltipDecrement: l10n.decrementTeamCountTooltip,
                tooltipIncrement: l10n.incrementTeamCountTooltip,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: TeamSetupNumberField(
                label: l10n.teamsPerMatchLabel,
                value: _teamsPerMatch,
                minValue: _minTeamsPerMatch,
                maxValue: _effectiveMaxTeamsPerMatch,
                onChanged: _setTeamsPerMatch,
                tooltipDecrement: l10n.decrementTeamsPerMatchTooltip,
                tooltipIncrement: l10n.incrementTeamsPerMatchTooltip,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMemberCountSummary(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 0,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.teamMemberCountSummary(
                _minMemberCountPerTeam,
                _maxMemberCountPerTeam,
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(l10n.teamMemberCountSummaryHelp),
          ],
        ),
      ),
    );
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
          title: Text(l10n.teamSetupTitle),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              Text(
                l10n.teamSetupInstruction,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.teamSetupSupportedConditions,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.teamSetupInputUpperLimitNote,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 16),
              _buildNumberFields(context),
              const SizedBox(height: 16),
              _buildMemberCountSummary(context),
              const SizedBox(height: 16),
              Card(
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.teamSetupMockNoticeTitle,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(l10n.teamSetupMockNoticeBody),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FilledButton.tonal(
                    onPressed: _resetInputs,
                    style: FilledButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(l10n.resetTeamSetupButton),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: _submitMock,
                    style: FilledButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      l10n.generateTeamScheduleButton,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }
}
