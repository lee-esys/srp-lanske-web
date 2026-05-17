import 'package:flutter/material.dart';

import 'schedule_player_chip.dart';
import 'schedule_section_card.dart';

class ScheduleParticipantViewModel {
  const ScheduleParticipantViewModel({
    required this.orderNo,
    required this.displayName,
    required this.participantId,
  });

  final int orderNo;
  final String displayName;
  final String participantId;
}

class ScheduleParticipantsCard extends StatefulWidget {
  const ScheduleParticipantsCard({
    super.key,
    required this.title,
    required this.participants,
    this.selectedParticipantId,
    this.onParticipantSelected,
  });

  final String title;
  final List<ScheduleParticipantViewModel> participants;
  final String? selectedParticipantId;
  final ValueChanged<String>? onParticipantSelected;

  @override
  State<ScheduleParticipantsCard> createState() =>
      _ScheduleParticipantsCardState();
}

class _ScheduleParticipantsCardState extends State<ScheduleParticipantsCard> {
  final _scrollController = ScrollController();
  bool _showScrollHint = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_updateScrollHint);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollHint());
  }

  @override
  void didUpdateWidget(ScheduleParticipantsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollHint());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollHint);
    _scrollController.dispose();
    super.dispose();
  }

  void _updateScrollHint() {
    if (!_scrollController.hasClients) return;

    final maxScrollExtent = _scrollController.position.maxScrollExtent;
    final pixels = _scrollController.position.pixels;
    final nextShowScrollHint = maxScrollExtent - pixels > 8;

    if (_showScrollHint == nextShowScrollHint) return;

    setState(() {
      _showScrollHint = nextShowScrollHint;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.participants.isEmpty) {
      return const ScheduleSectionCard(
        title: '参加者',
        child: Text('参加者情報がありません'),
      );
    }

    return ScheduleSectionCard(
      title: widget.title,
      child: SizedBox(
        height: 64,
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              child: Row(
                children: widget.participants.map((participant) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: SchedulePlayerChip(
                      slotNumber: participant.orderNo,
                      playerId: participant.participantId,
                      displayName: participant.displayName,
                      isHighlighted: widget.selectedParticipantId ==
                          participant.participantId,
                      onTap: widget.onParticipantSelected,
                    ),
                  );
                }).toList(growable: false),
              ),
            ),
            if (_showScrollHint)
              Positioned(
                top: 0,
                right: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    width: 36,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.0),
                          Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.92),
                        ],
                      ),
                    ),
                    child: const Text('>>'),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
