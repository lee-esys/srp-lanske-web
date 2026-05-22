import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

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
    required this.canRemovePlayer,
    required this.onRemovePlayer,
  });

  final TextEditingController eventNameController;
  final List<TextEditingController> displayNameControllers;
  final List<FocusNode> displayNameFocusNodes;
  final List<String?> sourceDisplayNames;
  final bool isLoadingEvent;
  final VoidCallback onReset;
  final VoidCallback onSubmit;
  final bool canRemovePlayer;
  final ValueChanged<int> onRemovePlayer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        TextFormField(
          controller: eventNameController,
          enabled: !isLoadingEvent,
          decoration: InputDecoration(
            labelText: l10n.eventNameLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.playerDisplayNameSectionTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        EventSetupDisplayNameGrid(
          controllers: displayNameControllers,
          focusNodes: displayNameFocusNodes,
          sourceDisplayNames: sourceDisplayNames,
          isLoadingEvent: isLoadingEvent,
          canRemovePlayer: canRemovePlayer,
          onRemovePlayer: onRemovePlayer,
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
