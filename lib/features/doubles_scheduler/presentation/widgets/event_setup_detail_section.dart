import 'package:flutter/material.dart';

import 'event_setup_action_buttons.dart';
import 'event_setup_display_name_grid.dart';

class EventSetupDetailSection extends StatelessWidget {
  const EventSetupDetailSection({
    super.key,
    required this.eventNameController,
    required this.displayNameControllers,
    required this.displayNameFocusNodes,
    required this.sourceDisplayNames,
    required this.isLoadingEvent,
    required this.onReset,
    required this.onSubmit,
  });

  final TextEditingController eventNameController;
  final List<TextEditingController> displayNameControllers;
  final List<FocusNode> displayNameFocusNodes;
  final List<String?> sourceDisplayNames;
  final bool isLoadingEvent;
  final VoidCallback onReset;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        TextFormField(
          controller: eventNameController,
          enabled: !isLoadingEvent,
          decoration: const InputDecoration(
            labelText: 'イベント名',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '参加者表示名',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        EventSetupDisplayNameGrid(
          controllers: displayNameControllers,
          focusNodes: displayNameFocusNodes,
          sourceDisplayNames: sourceDisplayNames,
          isLoadingEvent: isLoadingEvent,
        ),
        const SizedBox(height: 20),
        EventSetupActionButtons(
          isLoadingEvent: isLoadingEvent,
          onReset: onReset,
          onSubmit: onSubmit,
        ),
      ],
    );
  }
}
