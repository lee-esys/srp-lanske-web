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
    this.showRangeHelp = true,
    this.titleTrailing,
  });

  final String label;
  final int value;
  final int minValue;
  final int maxValue;
  final ValueChanged<int> onChanged;
  final String tooltipDecrement;
  final String tooltipIncrement;
  final String? helpText;
  final bool showRangeHelp;
  final Widget? titleTrailing;

  bool get _canDecrement => value > minValue;
  bool get _canIncrement => value < maxValue;

  int _clampValue(int nextValue) {
    return nextValue.clamp(minValue, maxValue).toInt();
  }

  void _setValue(int nextValue) {
    onChanged(_clampValue(nextValue));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final values = List<int>.generate(
      maxValue - minValue + 1,
      (index) => minValue + index,
    );
    final helperText = helpText ??
        (showRangeHelp ? l10n.teamSetupRangeHelp(minValue, maxValue) : null);

    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (titleTrailing != null) ...[
                  const SizedBox(width: 8),
                  titleTrailing!,
                ],
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  onPressed: _canDecrement ? () => _setValue(value - 1) : null,
                  tooltip: tooltipDecrement,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: const Icon(Icons.remove_circle_outline),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: value,
                    icon: const SizedBox.shrink(),
                    items: values
                        .map(
                          (item) => DropdownMenuItem<int>(
                            value: item,
                            child: Center(child: Text(item.toString())),
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
                      helperText: helperText,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                IconButton(
                  onPressed: _canIncrement ? () => _setValue(value + 1) : null,
                  tooltip: tooltipIncrement,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
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
