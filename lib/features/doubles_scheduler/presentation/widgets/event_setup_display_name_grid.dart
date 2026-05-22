import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';
import 'package:srp_lanske/shared/utils/number_label_mapper.dart';

class EventSetupDisplayNameGrid extends StatelessWidget {
  const EventSetupDisplayNameGrid({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.sourceDisplayNames,
    required this.isLoadingEvent,
    required this.canRemovePlayer,
    required this.onRemovePlayer,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final List<String?> sourceDisplayNames;
  final bool isLoadingEvent;
  final bool canRemovePlayer;
  final ValueChanged<int> onRemovePlayer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(controllers.length, (index) {
        final sourceName =
            sourceDisplayNames[index] ?? circledNumber(index + 1);

        return SizedBox(
          width: 160,
          child: TextFormField(
            controller: controllers[index],
            focusNode: focusNodes[index],
            enabled: !isLoadingEvent,
            decoration: InputDecoration(
              labelText: l10n.playerDisplayNameInputLabel(
                index + 1,
                sourceName,
              ),
              border: const OutlineInputBorder(),
              isDense: true,
              suffixIcon: IconButton(
                tooltip: canRemovePlayer
                    ? l10n.removePlayerTooltip
                    : l10n.cannotRemovePlayerTooltip,
                onPressed: isLoadingEvent || !canRemovePlayer
                    ? null
                    : () => onRemovePlayer(index),
                icon: const Icon(Icons.remove_circle_outline),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
              suffixIconConstraints: const BoxConstraints(
                minWidth: 36,
                minHeight: 36,
              ),
            ),
          ),
        );
      }),
    );
  }
}
