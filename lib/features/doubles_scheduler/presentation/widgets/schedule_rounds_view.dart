import 'package:flutter/material.dart';

class ScheduleRoundsView extends StatefulWidget {
  const ScheduleRoundsView({
    super.key,
    required this.scheduleResponse,
    required this.playerNameById,
  });

  final Map<String, dynamic>? scheduleResponse;
  final Map<String, String> playerNameById;

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
    final restSlotNumbers = _asIntList(round['rest_slot_numbers']);
    final courts = _asObjectList(round['courts']);
    final isRestExpanded = _expandedRestRoundNumbers.contains(roundNumber);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 34,
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  roundNumber,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...courts.map((court) {
                    return _buildCourtRow(court, slotToPlayerId);
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
                          );
                        }),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            _RestToggleButton(
              restCount: restSlotNumbers.length,
              isExpanded: isRestExpanded,
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
    );
  }

  Widget _buildCourtRow(
    Map<String, dynamic> court,
    Map<int, String> slotToPlayerId,
  ) {
    final courtNumber = court['court_number']?.toString() ?? '-';
    final team1Slots = _asIntList(court['team1_player_slots']);
    final team2Slots = _asIntList(court['team2_player_slots']);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            'コート: $courtNumber',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          ..._buildTeamChips(team1Slots, slotToPlayerId),
          const Text('vs'),
          ..._buildTeamChips(team2Slots, slotToPlayerId),
        ],
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

    final chips = <Widget>[];
    for (var i = 0; i < slotNumbers.length; i += 1) {
      if (i > 0) {
        chips.add(const Text('/'));
      }

      chips.add(
        _buildPlayerChip(
          slotNumber: slotNumbers[i],
          slotToPlayerId: slotToPlayerId,
        ),
      );
    }

    return chips;
  }

  Widget _buildPlayerChip({
    required int slotNumber,
    required Map<int, String> slotToPlayerId,
  }) {
    final playerId = slotToPlayerId[slotNumber];
    final displayName = playerId == null
        ? 'slot:$slotNumber'
        : widget.playerNameById[playerId] ?? playerId;

    return SchedulePlayerChip(
      slotNumber: slotNumber,
      playerId: playerId,
      displayName: displayName,
    );
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

class SchedulePlayerChip extends StatelessWidget {
  const SchedulePlayerChip({
    super.key,
    required this.slotNumber,
    required this.displayName,
    this.playerId,
    this.isHighlighted = false,
    this.onTap,
  });

  final int slotNumber;
  final String displayName;
  final String? playerId;
  final bool isHighlighted;
  final ValueChanged<String>? onTap;

  @override
  Widget build(BuildContext context) {
    final playerId = this.playerId;
    final label = Text('$slotNumber: $displayName');

    if (onTap == null || playerId == null) {
      return Chip(
        label: label,
        visualDensity: VisualDensity.compact,
        backgroundColor: isHighlighted
            ? Theme.of(context).colorScheme.primaryContainer
            : null,
      );
    }

    return ActionChip(
      label: label,
      visualDensity: VisualDensity.compact,
      backgroundColor:
          isHighlighted ? Theme.of(context).colorScheme.primaryContainer : null,
      onPressed: () => onTap!(playerId),
    );
  }
}

class _RestToggleButton extends StatelessWidget {
  const _RestToggleButton({
    required this.restCount,
    required this.isExpanded,
    required this.onTap,
  });

  final int restCount;
  final bool isExpanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 52,
        padding: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              '休憩',
              style: TextStyle(fontSize: 12),
            ),
            Text(
              '$restCount人',
              style: const TextStyle(fontSize: 12),
            ),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
