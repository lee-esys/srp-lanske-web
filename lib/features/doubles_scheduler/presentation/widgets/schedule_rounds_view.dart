import 'package:flutter/material.dart';

import 'schedule_player_chip.dart';

class ScheduleRoundsView extends StatefulWidget {
  const ScheduleRoundsView({
    super.key,
    required this.scheduleResponse,
    required this.playerNameById,
    required this.courtCount,
    this.selectedParticipantId,
    this.onParticipantSelected,
  });

  final Map<String, dynamic>? scheduleResponse;
  final Map<String, String> playerNameById;
  final int courtCount;
  final String? selectedParticipantId;
  final ValueChanged<String>? onParticipantSelected;

  @override
  State<ScheduleRoundsView> createState() => _ScheduleRoundsViewState();
}

class _ScheduleRoundsViewState extends State<ScheduleRoundsView> {
  final Set<String> _expandedRestRoundNumbers = {};

  @override
  Widget build(BuildContext context) {
    final scheduleResponse = widget.scheduleResponse;
    if (scheduleResponse == null) {
      return const Text('対戦表を取得できていません');
    }

    final rounds = _asObjectList(scheduleResponse['rounds']);
    final slotToPlayerId = _buildSlotToPlayerId(scheduleResponse);

    if (rounds.isEmpty) {
      return const Text('対戦表データがありません');
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
        padding: const EdgeInsets.all(4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: 36,
                child: Column(
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
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...courts.map((court) {
                    return _buildCourtRow(court, slotToPlayerId,
                        showCourtNumber: widget.courtCount >= 2);
                  }),
                  if (isRestExpanded) ...[
                    const Divider(),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('休憩:'),
                        ...restSlotNumbers.map((slotNumber) {
                          return _buildPlayerChip(
                            slotNumber: slotNumber,
                            slotToPlayerId: slotToPlayerId,
                            size: SchedulePlayerChipSize.compact,
                            highlightEnabled: false,
                          );
                        }),
                      ],
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

  Widget _buildCourtRow(
      Map<String, dynamic> court, Map<int, String> slotToPlayerId,
      {required bool showCourtNumber}) {
    final courtNumber = court['court_number']?.toString() ?? '-';
    final team1Slots = _asIntList(court['team1_player_slots']);
    final team2Slots = _asIntList(court['team2_player_slots']);

    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (showCourtNumber)
              Text(
                courtNumber,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            _buildTeamGroup(team1Slots, slotToPlayerId),
            const Text('vs'),
            _buildTeamGroup(team2Slots, slotToPlayerId),
          ],
        ));
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

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: _buildTeamChips(slotNumbers, slotToPlayerId),
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
      isHighlighted:
          highlightEnabled && widget.selectedParticipantId == playerId,
      onTap: widget.onParticipantSelected,
    );
  }

  bool _hasSelectedRestPlayer(
    List<int> restSlotNumbers,
    Map<int, String> slotToPlayerId,
  ) {
    final selectedParticipantId = widget.selectedParticipantId;
    if (selectedParticipantId == null) return false;

    return restSlotNumbers.any((slotNumber) {
      return slotToPlayerId[slotNumber] == selectedParticipantId;
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
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor =
        isHighlighted ? colorScheme.tertiaryContainer : Colors.transparent;
    final borderColor =
        isHighlighted ? colorScheme.tertiary : colorScheme.outlineVariant;
    final textColor = isHighlighted ? colorScheme.onTertiaryContainer : null;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        width: 40,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: isHighlighted ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '休憩: $restCount',
              style: TextStyle(
                fontSize: 10,
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.normal,
                color: textColor,
              ),
            ),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 16,
              color: textColor,
            ),
          ],
        ),
      ),
    );
  }
}
