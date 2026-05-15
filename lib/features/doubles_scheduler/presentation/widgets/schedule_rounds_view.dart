import 'package:flutter/material.dart';

class ScheduleRoundsView extends StatelessWidget {
  const ScheduleRoundsView({
    super.key,
    required this.scheduleResponse,
    required this.playerNameById,
  });

  final Map<String, dynamic>? scheduleResponse;
  final Map<String, String> playerNameById;

  @override
  Widget build(BuildContext context) {
    if (scheduleResponse == null) {
      return const Text('対戦表を取得できていません');
    }

    final rounds = _asObjectList(scheduleResponse?['rounds']);
    final slotToPlayerId = _buildSlotToPlayerId();

    if (rounds.isEmpty) {
      return const Text('対戦表データがありません');
    }

    return Column(
      children: rounds.map((round) {
        final roundNumber = round['round_number']?.toString() ?? '-';
        final restSlotNumbers = _asIntList(round['rest_slot_numbers']);
        final courts = _asObjectList(round['courts']);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '第$roundNumber試合',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                ...courts.map((court) {
                  final courtNumber = court['court_number']?.toString() ?? '-';
                  final team1Slots = _asIntList(court['team1_player_slots']);
                  final team2Slots = _asIntList(court['team2_player_slots']);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'コート$courtNumber',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatTeamFromSlots(team1Slots, slotToPlayerId)}  vs  ${_formatTeamFromSlots(team2Slots, slotToPlayerId)}',
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(),
                Text(
                  '休憩: ${_formatRestPlayersBySlots(restSlotNumbers, slotToPlayerId)}',
                ),
              ],
            ),
          ),
        );
      }).toList(growable: false),
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

  Map<int, String> _buildSlotToPlayerId() {
    final assignment = _asObjectList(scheduleResponse?['assignment']);
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

  String _playerLabelFromId(String playerId) {
    return playerNameById[playerId] ?? playerId;
  }

  String _playerLabelFromSlot(
    int slotNumber,
    Map<int, String> slotToPlayerId,
  ) {
    final playerId = slotToPlayerId[slotNumber];
    if (playerId == null) return 'slot:$slotNumber';
    return _playerLabelFromId(playerId);
  }

  String _formatTeamFromSlots(
    List<int> slots,
    Map<int, String> slotToPlayerId,
  ) {
    if (slots.isEmpty) return '-';

    return slots
        .map((slot) => '$slot: ${_playerLabelFromSlot(slot, slotToPlayerId)}')
        .join(' / ');
  }

  String _formatRestPlayersBySlots(
    List<int> slotNumbers,
    Map<int, String> slotToPlayerId,
  ) {
    if (slotNumbers.isEmpty) return '-';

    return slotNumbers
        .map((slot) => '$slot: ${_playerLabelFromSlot(slot, slotToPlayerId)}')
        .join(' / ');
  }
}
