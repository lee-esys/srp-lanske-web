import 'package:flutter/material.dart';
import 'package:srp_lanske/shared/utils/number_label_mapper.dart';

class EventSetupDisplayNameGrid extends StatelessWidget {
  const EventSetupDisplayNameGrid({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.sourceDisplayNames,
    required this.isLoadingEvent,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final List<String?> sourceDisplayNames;
  final bool isLoadingEvent;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(controllers.length, (index) {
        final sourceName = sourceDisplayNames[index] ?? circledNumber(index + 1);
        final labelSuffix = '：$sourceName';

        return SizedBox(
          width: 140,
          child: TextFormField(
            controller: controllers[index],
            focusNode: focusNodes[index],
            enabled: !isLoadingEvent,
            decoration: InputDecoration(
              labelText: '参加者${participantLabelNumber(index)}$labelSuffix',
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        );
      }),
    );
  }
}
