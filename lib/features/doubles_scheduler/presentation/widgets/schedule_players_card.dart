import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

import 'schedule_player_chip.dart';
import 'schedule_section_card.dart';

class SchedulePlayerViewModel {
  const SchedulePlayerViewModel({
    required this.orderNo,
    required this.displayName,
    required this.playerId,
  });

  final int orderNo;
  final String displayName;
  final String playerId;
}

class SchedulePlayersCard extends StatefulWidget {
  const SchedulePlayersCard({
    super.key,
    required this.title,
    required this.players,
    this.selectedPlayerId,
    this.onPlayerSelected,
  });

  final String title;
  final List<SchedulePlayerViewModel> players;
  final String? selectedPlayerId;
  final ValueChanged<String>? onPlayerSelected;

  @override
  State<SchedulePlayersCard> createState() => _SchedulePlayersCardState();
}

class _SchedulePlayersCardState extends State<SchedulePlayersCard> {
  final _scrollController = ScrollController();
  bool _showScrollHint = false;

  @override
  void initState() {
    super.initState();

    _scrollController.addListener(_updateScrollHint);
    WidgetsBinding.instance.addPostFrameCallback((_) => _updateScrollHint());
  }

  @override
  void didUpdateWidget(SchedulePlayersCard oldWidget) {
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
    final l10n = AppLocalizations.of(context);

    if (widget.players.isEmpty) {
      return ScheduleSectionCard(
        title: l10n.playersTitle,
        child: Text(l10n.noPlayersMessage),
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
                children: widget.players.map((player) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: SchedulePlayerChip(
                      slotNumber: player.orderNo,
                      playerId: player.playerId,
                      displayName: player.displayName,
                      isHighlighted: widget.selectedPlayerId == player.playerId,
                      onTap: widget.onPlayerSelected,
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
