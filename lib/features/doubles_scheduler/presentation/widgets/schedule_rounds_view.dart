import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

import 'schedule_player_chip.dart';

class ScheduleRoundsView extends StatefulWidget {
  const ScheduleRoundsView({
    super.key,
    required this.scheduleResponse,
    required this.playerNameById,
    required this.courtCount,
    this.selectedPlayerId,
    this.onPlayerSelected,
    required this.courtLabelByNumber,
  });

  final Map<String, dynamic>? scheduleResponse;
  final Map<String, String> playerNameById;
  final int courtCount;
  final String? selectedPlayerId;
  final ValueChanged<String>? onPlayerSelected;
  final Map<int, String> courtLabelByNumber;

  @override
  State<ScheduleRoundsView> createState() => _ScheduleRoundsViewState();
}

class _ScheduleRoundsViewState extends State<ScheduleRoundsView> {
  static const _courtAreaSpacing = 24.0;
  static const _courtMatchCardWidth = 300.0;

  final Set<String> _expandedRestRoundNumbers = {};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheduleResponse = widget.scheduleResponse;
    if (scheduleResponse == null) {
      return Text(l10n.scheduleNotLoadedMessage);
    }

    final rounds = _asObjectList(scheduleResponse['rounds']);
    final slotToPlayerId = _buildSlotToPlayerId(scheduleResponse);

    if (rounds.isEmpty) {
      return Text(l10n.scheduleDataEmptyMessage);
    }

    return Column(
      children: rounds.map((round) {
        return _buildRoundCard(round, slotToPlayerId);
      }).toList(growable: false),
    );
  }

  Widget _buildRoundCard(
    Map<String, dynamic> round,
    Map<int, String> slotToPlayerId,
  ) {
    final roundNumber = round['round_number']?.toString() ?? '-';
    final roundNumberValue = int.tryParse(roundNumber);
    final isEvenRound = roundNumberValue != null && roundNumberValue.isEven;

    final colorScheme = Theme.of(context).colorScheme;
    final roundCardColor = isEvenRound
        ? colorScheme.surface.withValues(alpha: 0.92)
        : colorScheme.primaryContainer.withValues(alpha: 0.92);

    final restSlotNumbers = _asIntList(round['rest_slot_numbers']);
    final hasSelectedRestPlayer = _hasSelectedRestPlayer(
      restSlotNumbers,
      slotToPlayerId,
    );
    final courts = _asObjectList(round['courts']);
    final isRestExpanded = _expandedRestRoundNumbers.contains(roundNumber);

    return Card(
      color: roundCardColor,
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'R $roundNumber',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _RestToggleButton(
                    restCount: restSlotNumbers.length,
                    isExpanded: isRestExpanded,
                    isHighlighted: hasSelectedRestPlayer,
                    onTap: () {
                      setState(() {
                        if (isRestExpanded) {
                          _expandedRestRoundNumbers.remove(roundNumber);
                        } else {
                          _expandedRestRoundNumbers.add(roundNumber);
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCourtArea(
                    courts: courts,
                    slotToPlayerId: slotToPlayerId,
                  ),
                  if (isRestExpanded) ...[
                    const Divider(),
                    _buildRestPlayersRow(
                      restSlotNumbers: restSlotNumbers,
                      slotToPlayerId: slotToPlayerId,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourtArea({
    required List<Map<String, dynamic>> courts,
    required Map<int, String> slotToPlayerId,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final courtItemWidth =
            _courtMatchCardWidth.clamp(0.0, maxWidth).toDouble();
        final canUseTwoColumns = courts.length >= 2 &&
            maxWidth >= (_courtMatchCardWidth * 2 + _courtAreaSpacing);

        if (courts.length == 1) {
          return SizedBox(
            width: maxWidth,
            child: _buildCourtMatchCard(
              courts.first,
              slotToPlayerId,
              alignment: Alignment.center,
            ),
          );
        }

        if (courts.length == 2 && canUseTwoColumns) {
          final groupWidth = _courtMatchCardWidth * 2 + _courtAreaSpacing;

          return Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: groupWidth,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: _courtMatchCardWidth,
                    child: _buildCourtMatchCard(
                      courts[0],
                      slotToPlayerId,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  const SizedBox(width: _courtAreaSpacing),
                  SizedBox(
                    width: _courtMatchCardWidth,
                    child: _buildCourtMatchCard(
                      courts[1],
                      slotToPlayerId,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (courts.length == 2) {
          return Column(
            children: courts.map((court) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: maxWidth,
                  child: _buildCourtMatchCard(
                    court,
                    slotToPlayerId,
                    alignment: Alignment.center,
                  ),
                ),
              );
            }).toList(growable: false),
          );
        }

        final itemWidth =
            canUseTwoColumns ? _courtMatchCardWidth : courtItemWidth;

        return Wrap(
          alignment: WrapAlignment.start,
          spacing: _courtAreaSpacing,
          runSpacing: 8,
          children: courts.map((court) {
            return SizedBox(
              width: itemWidth,
              child: _buildCourtMatchCard(
                court,
                slotToPlayerId,
                alignment: Alignment.centerLeft,
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }

  Widget _buildCourtMatchCard(
    Map<String, dynamic> court,
    Map<int, String> slotToPlayerId, {
    Alignment alignment = Alignment.centerLeft,
  }) {
    final courtNumberText = court['court_number']?.toString() ?? '-';
    final courtNumber = int.tryParse(courtNumberText);
    final defaultCourtLabel = courtNumber?.toString() ?? courtNumberText;
    final configuredCourtLabel =
        courtNumber == null ? null : widget.courtLabelByNumber[courtNumber];

    final courtLabel =
        configuredCourtLabel == null || configuredCourtLabel.trim().isEmpty
            ? defaultCourtLabel
            : configuredCourtLabel.trim();

    final hasCustomCourtLabel = courtLabel != defaultCourtLabel;
    final showCourtLabel = widget.courtCount >= 2 || hasCustomCourtLabel;
    final team1Slots = _asIntList(court['team1_player_slots']);
    final team2Slots = _asIntList(court['team2_player_slots']);

    return _buildHorizontalScrollableContent(
      alignment: alignment,
      child: _buildCourtMatchContent(
        courtLabel: courtLabel,
        showCourtLabel: showCourtLabel,
        team1Slots: team1Slots,
        team2Slots: team2Slots,
        slotToPlayerId: slotToPlayerId,
      ),
    );
  }

  Widget _buildHorizontalScrollableContent({
    required Widget child,
    required Alignment alignment,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Align(
              alignment: alignment,
              child: child,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCourtMatchContent({
    required String courtLabel,
    required bool showCourtLabel,
    required List<int> team1Slots,
    required List<int> team2Slots,
    required Map<int, String> slotToPlayerId,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (showCourtLabel) ...[
          Text(
            courtLabel,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
        ],
        _buildTeamGroup(team1Slots, slotToPlayerId),
        const SizedBox(width: 6),
        const Text('vs'),
        const SizedBox(width: 6),
        _buildTeamGroup(team2Slots, slotToPlayerId),
      ],
    );
  }

  Widget _buildRestPlayersRow({
    required List<int> restSlotNumbers,
    required Map<int, String> slotToPlayerId,
  }) {
    final l10n = AppLocalizations.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${l10n.restLabel}:'),
            const SizedBox(width: 6),
            for (final slotNumber in restSlotNumbers) ...[
              _buildPlayerChip(
                slotNumber: slotNumber,
                slotToPlayerId: slotToPlayerId,
                size: SchedulePlayerChipSize.compact,
                highlightEnabled: false,
              ),
              const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTeamChips(
    List<int> slotNumbers,
    Map<int, String> slotToPlayerId,
  ) {
    if (slotNumbers.isEmpty) {
      return const [Text('-')];
    }

    return slotNumbers.map((slotNumber) {
      return _buildPlayerChip(
        slotNumber: slotNumber,
        slotToPlayerId: slotToPlayerId,
      );
    }).toList(growable: false);
  }

  Widget _buildTeamGroup(
    List<int> slotNumbers,
    Map<int, String> slotToPlayerId,
  ) {
    if (slotNumbers.isEmpty) {
      return const Text('-');
    }

    final chips = _buildTeamChips(slotNumbers, slotToPlayerId);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < chips.length; i++) ...[
          if (i > 0) const SizedBox(width: 6),
          chips[i],
        ],
      ],
    );
  }

  Widget _buildPlayerChip({
    required int slotNumber,
    required Map<int, String> slotToPlayerId,
    SchedulePlayerChipSize size = SchedulePlayerChipSize.normal,
    bool highlightEnabled = true,
  }) {
    final playerId = slotToPlayerId[slotNumber];
    final displayName = playerId == null
        ? 'slot:$slotNumber'
        : widget.playerNameById[playerId] ?? playerId;

    return SchedulePlayerChip(
      slotNumber: slotNumber,
      playerId: playerId,
      displayName: displayName,
      size: size,
      isHighlighted: highlightEnabled && widget.selectedPlayerId == playerId,
      onTap: widget.onPlayerSelected,
    );
  }

  bool _hasSelectedRestPlayer(
    List<int> restSlotNumbers,
    Map<int, String> slotToPlayerId,
  ) {
    final selectedPlayerId = widget.selectedPlayerId;
    if (selectedPlayerId == null) return false;

    return restSlotNumbers.any((slotNumber) {
      return slotToPlayerId[slotNumber] == selectedPlayerId;
    });
  }

  List<Map<String, dynamic>> _asObjectList(Object? value) {
    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map((e) => e.map((key, value) => MapEntry(key.toString(), value)))
        .toList(growable: false);
  }

  List<int> _asIntList(Object? value) {
    if (value is! List) return const [];

    return value
        .map((e) {
          if (e is int) return e;
          return int.tryParse(e.toString());
        })
        .whereType<int>()
        .toList(growable: false);
  }

  Map<int, String> _buildSlotToPlayerId(Map<String, dynamic> scheduleResponse) {
    final assignment = _asObjectList(scheduleResponse['assignment']);
    final slotToPlayerId = <int, String>{};

    for (final row in assignment) {
      final slotNumberValue = row['slot_number'];
      final playerIdValue = row['player_id'];
      if (slotNumberValue == null || playerIdValue == null) continue;

      final slotNumber = int.tryParse(slotNumberValue.toString());
      if (slotNumber == null) continue;

      slotToPlayerId[slotNumber] = playerIdValue.toString();
    }

    return slotToPlayerId;
  }
}

class _RestToggleButton extends StatelessWidget {
  const _RestToggleButton({
    required this.restCount,
    required this.isExpanded,
    required this.onTap,
    this.isHighlighted = false,
  });

  final int restCount;
  final bool isExpanded;
  final VoidCallback onTap;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor =
        isHighlighted ? colorScheme.tertiaryContainer : Colors.transparent;
    final borderColor =
        isHighlighted ? colorScheme.tertiary : colorScheme.outlineVariant;
    final textColor = isHighlighted ? colorScheme.onTertiaryContainer : null;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        width: 40,
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: isHighlighted ? 2.0 : 1.0,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                l10n.restLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.0,
                  fontWeight:
                      isHighlighted ? FontWeight.w700 : FontWeight.normal,
                  color: textColor,
                ),
              ),
              Text(
                l10n.restCountLabel(restCount),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.0,
                  fontWeight:
                      isHighlighted ? FontWeight.w700 : FontWeight.normal,
                  color: textColor,
                ),
              ),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 14,
                color: textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
