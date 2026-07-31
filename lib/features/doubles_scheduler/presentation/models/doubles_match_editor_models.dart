class DoublesMatchParticipantViewModel {
  const DoublesMatchParticipantViewModel({
    required this.slotNumber,
    required this.displayName,
    this.playerId,
  });

  final int slotNumber;
  final String displayName;
  final String? playerId;
}

class DoublesMatchSelection {
  const DoublesMatchSelection({
    required this.roundNo,
    required this.courtNo,
    this.matchNo,
    required this.side1Players,
    required this.side2Players,
  });

  final int roundNo;
  final int courtNo;
  final int? matchNo;
  final List<DoublesMatchParticipantViewModel> side1Players;
  final List<DoublesMatchParticipantViewModel> side2Players;
}
