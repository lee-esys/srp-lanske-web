import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

class TeamSetupNumberField extends StatelessWidget {
  const TeamSetupNumberField({
    super.key,
    required this.label,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.onChanged,
    required this.tooltipDecrement,
    required this.tooltipIncrement,
    this.helpText,
  });

  final String label;
  final int value;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onChanged;
  final String tooltipDecrement;
  final String tooltipIncrement;
  final String? helpText;

  bool get _canDecrement => value > minValue;
  bool get _canIncrement => value < maxValue;

  void _setValue(int nextValue) {
    onChanged(nextValue.clamp(minValue, maxValue));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final values = List<int>.generate(
      maxValue - minValue + 1,
      (index) => minValue + index,
    );

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: _canDecrement ? () => _setValue(value - 1) : null,
                  tooltip: tooltipDecrement,
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: value,
                    items: values
                        .map(
                          (item) => DropdownMenuItem<int>(
                            value: item,
                            child: Text(item.toString()),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: (nextValue) {
                      if (nextValue == null) return;
                      _setValue(nextValue);
                    },
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      isDense: true,
                      helperText: helpText ??
                          l10n.teamSetupRangeHelp(minValue, maxValue),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _canIncrement ? () => _setValue(value + 1) : null,
                  tooltip: tooltipIncrement,
                  icon: const Icon(Icons.add_circle_outline),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
