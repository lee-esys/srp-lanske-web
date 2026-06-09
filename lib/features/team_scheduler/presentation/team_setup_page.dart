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
  static const _minCourts = 1;
  static const _maxCourts = 5;
  static const _minTeamCount = 2;
  static const _maxTeamCount = 25;
  static const _minParticipantCount = 2;
  static const _maxParticipantCount = 50;
  static const _minTeamSize = 1;
  static const _maxTeamSize = 25;
  static const _minActiveTeamCountPerRound = 2;
  static const _maxActiveTeamCountPerRound = 25;

  int _courts = 1;
  int _teamCount = 4;
  int _activeTeamCountPerRound = 2;
  int _teamSize = 2;
  int _participantCount = 8;

  int _clampInt(int value, int minValue, int maxValue) =>
      value.clamp(minValue, maxValue).toInt();

  int get _effectiveMaxTeamCount =>
      _clampInt(_maxTeamCount, _minTeamCount, _participantCount);

  int get _effectiveMaxTeamSize =>
      _clampInt(_maxTeamSize, _minTeamSize, _participantCount);

  int get _effectiveMaxActiveTeamCountPerRound => _clampInt(
        _maxActiveTeamCountPerRound,
        _minActiveTeamCountPerRound,
        _teamCount,
      );

  TeamSetupDraft get _draft => TeamSetupDraft(
        courts: _courts,
        teamCount: _teamCount,
        activeTeamCountPerRound: _activeTeamCountPerRound,
        teamSize: _teamSize,
        participantCount: _participantCount,
      );

  void _syncDependentValues() {
    _teamCount = _clampInt(_teamCount, _minTeamCount, _effectiveMaxTeamCount);
    _activeTeamCountPerRound = _clampInt(
      _activeTeamCountPerRound,
      _minActiveTeamCountPerRound,
      _effectiveMaxActiveTeamCountPerRound,
    );
    _teamSize = _clampInt(_teamSize, _minTeamSize, _effectiveMaxTeamSize);
  }

  void _setCourts(int value) {
    setState(() => _courts = _clampInt(value, _minCourts, _maxCourts));
  }

  void _setTeamCount(int value) {
    setState(() {
      _teamCount = _clampInt(value, _minTeamCount, _effectiveMaxTeamCount);
      _syncDependentValues();
    });
  }

  void _setActiveTeamCountPerRound(int value) {
    setState(() {
      _activeTeamCountPerRound = _clampInt(
        value,
        _minActiveTeamCountPerRound,
        _effectiveMaxActiveTeamCountPerRound,
      );
    });
  }

  void _setTeamSize(int value) {
    setState(() {
      _teamSize = _clampInt(value, _minTeamSize, _effectiveMaxTeamSize);
      _participantCount = _clampInt(
        _teamCount * _teamSize,
        _minParticipantCount,
        _maxParticipantCount,
      );
      _syncDependentValues();
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

  void _resetInputs() {
    setState(() {
      _courts = 1;
      _teamCount = 4;
      _activeTeamCountPerRound = 2;
      _teamSize = 2;
      _participantCount = 8;
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
                label: l10n.courtCountLabel,
                value: _courts,
                minValue: _minCourts,
                maxValue: _maxCourts,
                onChanged: _setCourts,
                tooltipDecrement: l10n.decrementCourtCountTooltip,
                tooltipIncrement: l10n.incrementCourtCountTooltip,
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
                label: l10n.activeTeamCountPerRoundLabel,
                value: _activeTeamCountPerRound,
                minValue: _minActiveTeamCountPerRound,
                maxValue: _effectiveMaxActiveTeamCountPerRound,
                onChanged: _setActiveTeamCountPerRound,
                tooltipDecrement:
                    l10n.decrementActiveTeamCountPerRoundTooltip,
                tooltipIncrement:
                    l10n.incrementActiveTeamCountPerRoundTooltip,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: TeamSetupNumberField(
                label: l10n.teamSizeLabel,
                value: _teamSize,
                minValue: _minTeamSize,
                maxValue: _effectiveMaxTeamSize,
                onChanged: _setTeamSize,
                tooltipDecrement: l10n.decrementTeamSizeTooltip,
                tooltipIncrement: l10n.incrementTeamSizeTooltip,
                helpText: l10n.teamSetupDerivedTeamSizeHelp,
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
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.teamSetupTitle)),
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
    );
  }
}
