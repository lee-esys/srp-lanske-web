import 'package:flutter/material.dart';

import 'schedule_slot_icon.dart';

enum SchedulePlayerChipSize {
  normal,
  compact,
}

class SchedulePlayerChip extends StatelessWidget {
  const SchedulePlayerChip({
    super.key,
    required this.slotNumber,
    required this.displayName,
    this.playerId,
    this.isHighlighted = false,
    this.onTap,
    this.size = SchedulePlayerChipSize.normal,
  });

  final int slotNumber;
  final String displayName;
  final String? playerId;
  final bool isHighlighted;
  final ValueChanged<String>? onTap;
  final SchedulePlayerChipSize size;

  double get _chipWidth {
    switch (size) {
      case SchedulePlayerChipSize.normal:
        return 60;
      case SchedulePlayerChipSize.compact:
        return 52;
    }
  }

  double get _chipHeight {
    switch (size) {
      case SchedulePlayerChipSize.normal:
        return 56;
      case SchedulePlayerChipSize.compact:
        return 48;
    }
  }

  double get _iconSize {
    switch (size) {
      case SchedulePlayerChipSize.normal:
        return 26;
      case SchedulePlayerChipSize.compact:
        return 22;
    }
  }

  double get _nameFontSize {
    switch (size) {
      case SchedulePlayerChipSize.normal:
        return 9;
      case SchedulePlayerChipSize.compact:
        return 8;
    }
  }

  @override
  Widget build(BuildContext context) {
    final playerId = this.playerId;
    final colorScheme = Theme.of(context).colorScheme;
    final borderRadius = BorderRadius.circular(8);

    final chipContent = SizedBox(
      width: _chipWidth,
      height: _chipHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScheduleSlotIcon(
            slotNumber: slotNumber,
            playerId: playerId,
            displayName: displayName,
            size: _iconSize,
          ),
          const SizedBox(height: 1),
          Text(
            displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: _nameFontSize,
              height: 1.1,
            ),
          ),
        ],
      ),
    );

    final backgroundColor =
        isHighlighted ? colorScheme.primaryContainer : colorScheme.surface;

    if (onTap == null || playerId == null) {
      return Container(
        width: _chipWidth,
        height: _chipHeight,
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(color: colorScheme.outlineVariant),
          borderRadius: borderRadius,
        ),
        child: chipContent,
      );
    }

    return Material(
      color: backgroundColor,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colorScheme.outlineVariant),
        borderRadius: borderRadius,
      ),
      child: InkWell(
        borderRadius: borderRadius,
        onTap: () => onTap!(playerId),
        child: chipContent,
      ),
    );
  }
}
