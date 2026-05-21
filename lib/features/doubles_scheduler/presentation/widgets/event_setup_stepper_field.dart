import 'package:flutter/material.dart';

class EventSetupStepperField extends StatelessWidget {
  const EventSetupStepperField({
    super.key,
    required this.label,
    required this.controller,
    required this.isLoadingEvent,
    required this.onDecrement,
    required this.onIncrement,
    required this.tooltipDecrement,
    required this.tooltipIncrement,
  });

  final String label;
  final TextEditingController controller;
  final bool isLoadingEvent;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final String tooltipDecrement;
  final String tooltipIncrement;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          IconButton(
            onPressed: isLoadingEvent ? null : onDecrement,
            tooltip: tooltipDecrement,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Expanded(
            child: SizedBox(
              width: 84,
              child: TextFormField(
                controller: controller,
                readOnly: true,
                enabled: !isLoadingEvent,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: isLoadingEvent ? null : onIncrement,
            tooltip: tooltipIncrement,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }
}
