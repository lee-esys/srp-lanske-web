import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

import 'models/team_setup_draft.dart';
import 'team_navigation_drawer.dart';
import 'team_schedule_page.dart';
import 'widgets/team_participant_name_input_card.dart';
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
  static const _minPreferredTeamSize = 1;
  static const _maxPreferredTeamSize = 25;
  static const _minTeamsPerMatch = 2;
  static const _maxTeamsPerMatch = 25;

  static const _leftColumnMinWidth = 220.0;
  static const _rightColumnMinWidth = 220.0;
  static const _columnGap = 16.0;

  int _concurrentMatchCount = 1;
  int _participantCount = 8;
  int _preferredTeamSize = 2;
  int _teamsPerMatch = 2;
  List<String> _participantNames = const [];

  int _clampInt(int value, int minValue, int maxValue) =>
      value.clamp(minValue, maxValue).toInt();

  int get _effectiveMaxPreferredTeamSize {
    final maxValue = (_participantCount - 1).clamp(
      _minPreferredTeamSize,
      _maxPreferredTeamSize,
    );
    return maxValue.toInt();
  }

  int get _derivedTeamCount =>
      (_participantCount / _preferredTeamSize).ceil().toInt();

  int get _effectiveMaxTeamsPerMatch => _clampInt(
        _maxTeamsPerMatch,
        _minTeamsPerMatch,
        _derivedTeamCount,
      );

  int get _effectiveMaxConcurrentMatchCount {
    final maxByTeams = _derivedTeamCount ~/ _teamsPerMatch;
    return _clampInt(
      maxByTeams,
      _minConcurrentMatchCount,
      _maxConcurrentMatchCount,
    );
  }

  List<int> get _teamMemberCounts {
    final teamCount = _derivedTeamCount;
    final base = _participantCount ~/ teamCount;
    final remainder = _participantCount % teamCount;

    return List<int>.generate(
      teamCount,
      (index) => index < remainder ? base + 1 : base,
      growable: false,
    );
  }

  String get _teamDistributionText {
    final counts = _teamMemberCounts;
    final grouped = <int, int>{};

    for (final count in counts) {
      grouped[count] = (grouped[count] ?? 0) + 1;
    }

    final entries = grouped.entries.toList()
      ..sort((a, b) => b.key.compareTo(a.key));

    return entries.map((entry) {
      return '${entry.key}人×${entry.value}チーム';
    }).join(' / ');
  }

  TeamSetupDraft get _draft => TeamSetupDraft(
        concurrentMatchCount: _concurrentMatchCount,
        participantCount: _participantCount,
        preferredTeamSize: _preferredTeamSize,
        teamsPerMatch: _teamsPerMatch,
        participantNames: _participantNames,
      );

  void _syncDependentValues() {
    _preferredTeamSize = _clampInt(
      _preferredTeamSize,
      _minPreferredTeamSize,
      _effectiveMaxPreferredTeamSize,
    );
    _teamsPerMatch = _clampInt(
      _teamsPerMatch,
      _minTeamsPerMatch,
      _effectiveMaxTeamsPerMatch,
    );
    _concurrentMatchCount = _clampInt(
      _concurrentMatchCount,
      _minConcurrentMatchCount,
      _effectiveMaxConcurrentMatchCount,
    );
  }

  void _setConcurrentMatchCount(int value) {
    setState(() {
      _concurrentMatchCount = _clampInt(
        value,
        _minConcurrentMatchCount,
        _effectiveMaxConcurrentMatchCount,
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

  void _setPreferredTeamSize(int value) {
    setState(() {
      _preferredTeamSize = _clampInt(
        value,
        _minPreferredTeamSize,
        _effectiveMaxPreferredTeamSize,
      );
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
      _syncDependentValues();
    });
  }

  void _applyParticipantNames(List<String> names) {
    setState(() {
      _participantNames = names;
      _participantCount = _clampInt(
        names.length,
        _minParticipantCount,
        _maxParticipantCount,
      );
      _syncDependentValues();
    });
  }

  void _resetInputs() {
    setState(() {
      _concurrentMatchCount = 1;
      _participantCount = 8;
      _preferredTeamSize = 2;
      _teamsPerMatch = 2;
      _participantNames = const [];
    });
  }

  void _submit() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) => TeamSchedulePage.create(draft: _draft),
      ),
    );
  }

  Widget _buildNumberFields(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      children: [
        TeamSetupNumberField(
          label: l10n.concurrentMatchCountLabel,
          value: _concurrentMatchCount,
          minValue: _minConcurrentMatchCount,
          maxValue: _effectiveMaxConcurrentMatchCount,
          onChanged: _setConcurrentMatchCount,
          tooltipDecrement: l10n.decrementConcurrentMatchCountTooltip,
          tooltipIncrement: l10n.incrementConcurrentMatchCountTooltip,
          showRangeHelp: false,
        ),
        const SizedBox(height: 12),
        TeamSetupNumberField(
          label: l10n.participantCountLabel,
          value: _participantCount,
          minValue: _minParticipantCount,
          maxValue: _maxParticipantCount,
          onChanged: _setParticipantCount,
          tooltipDecrement: l10n.decrementParticipantCountTooltip,
          tooltipIncrement: l10n.incrementParticipantCountTooltip,
          showRangeHelp: false,
        ),
        const SizedBox(height: 12),
        TeamSetupNumberField(
          label: l10n.preferredTeamSizeLabel,
          value: _preferredTeamSize,
          minValue: _minPreferredTeamSize,
          maxValue: _effectiveMaxPreferredTeamSize,
          onChanged: _setPreferredTeamSize,
          tooltipDecrement: l10n.decrementPreferredTeamSizeTooltip,
          tooltipIncrement: l10n.incrementPreferredTeamSizeTooltip,
          showRangeHelp: false,
        ),
        const SizedBox(height: 12),
        TeamSetupNumberField(
          label: l10n.teamsPerMatchLabel,
          value: _teamsPerMatch,
          minValue: _minTeamsPerMatch,
          maxValue: _effectiveMaxTeamsPerMatch,
          onChanged: _setTeamsPerMatch,
          tooltipDecrement: l10n.decrementTeamsPerMatchTooltip,
          tooltipIncrement: l10n.incrementTeamsPerMatchTooltip,
          showRangeHelp: false,
        ),
      ],
    );
  }

  Widget _buildSetupInputs(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useTwoColumns = constraints.maxWidth >=
            _leftColumnMinWidth + _rightColumnMinWidth + _columnGap;

        if (!useTwoColumns) {
          return Column(
            children: [
              _buildNumberFields(context),
              const SizedBox(height: 16),
              TeamParticipantNameInputCard(
                participantNames: _participantNames,
                participantCount: _participantCount,
                maxParticipantCount: _maxParticipantCount,
                onApply: _applyParticipantNames,
              ),
            ],
          );
        }

        final leftColumnWidth = _leftColumnMinWidth;
        final rightColumnWidth =
            constraints.maxWidth - leftColumnWidth - _columnGap;

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: _leftColumnMinWidth,
                child: _buildNumberFields(context),
              ),
              const SizedBox(width: _columnGap),
              SizedBox(
                width: rightColumnWidth,
                child: TeamParticipantNameInputCard(
                  participantNames: _participantNames,
                  participantCount: _participantCount,
                  maxParticipantCount: _maxParticipantCount,
                  onApply: _applyParticipantNames,
                  expandToFillHeight: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Wrap(
          spacing: 16,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              '${l10n.teamCountSummary(_derivedTeamCount)} / ${l10n.teamDistributionSummary(_teamDistributionText)}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              l10n.teamCountSummaryHelp,
              style: theme.textTheme.bodySmall,
            ),
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
        endDrawer: const TeamNavigationDrawer(showHomeLink: true),
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
              _buildSetupInputs(context),
              const SizedBox(height: 16),
              _buildSummaryCard(context),
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
                    onPressed: _submit,
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
