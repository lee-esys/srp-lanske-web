import 'package:flutter/material.dart';

import 'schedule_section_card.dart';

class ScheduleEventSummaryCard extends StatelessWidget {
  const ScheduleEventSummaryCard({
    super.key,
    required this.eventName,
    required this.courtCount,
    required this.participantCount,
    required this.statusLabel,
    this.publicId,
    this.onCopyShareUrl,
  });

  final String eventName;
  final int courtCount;
  final int participantCount;
  final String statusLabel;
  final String? publicId;
  final VoidCallback? onCopyShareUrl;

  @override
  Widget build(BuildContext context) {
    final publicId = this.publicId;

    return ScheduleSectionCard(
      title: 'イベント情報',
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('イベント名: $eventName'),
          Text('面数: $courtCount'),
          Text('人数: $participantCount'),
          if (publicId != null && publicId.isNotEmpty) Text('共有ID: $publicId'),
          Text('状態: $statusLabel'),
          if (onCopyShareUrl != null)
            OutlinedButton.icon(
              onPressed: onCopyShareUrl,
              icon: const Icon(Icons.copy),
              label: const Text('共有URLをコピー'),
            ),
        ],
      ),
    );
  }
}
