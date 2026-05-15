import 'package:flutter/material.dart';

import 'schedule_section_card.dart';

class ScheduleParticipantViewModel {
  const ScheduleParticipantViewModel({
    required this.orderNo,
    required this.displayName,
  });

  final int orderNo;
  final String displayName;
}

class ScheduleParticipantsCard extends StatelessWidget {
  const ScheduleParticipantsCard({
    super.key,
    required this.participants,
  });

  final List<ScheduleParticipantViewModel> participants;

  @override
  Widget build(BuildContext context) {
    if (participants.isEmpty) {
      return const ScheduleSectionCard(
        title: '参加者',
        child: Text('参加者情報がありません'),
      );
    }

    return ScheduleSectionCard(
      title: '参加者',
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: participants.map((participant) {
          return Chip(
            label: Text('${participant.orderNo}: ${participant.displayName}'),
          );
        }).toList(growable: false),
      ),
    );
  }
}
