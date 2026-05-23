import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srp_lanske/l10n/l10n.dart';

import '../../domain/saved_event_models.dart';

class CourtDisplaySettingsDialog extends StatefulWidget {
  const CourtDisplaySettingsDialog({
    super.key,
    required this.courtCount,
    required this.initialSettings,
  });

  final int courtCount;
  final List<SavedEventCourtSetting> initialSettings;

  @override
  State<CourtDisplaySettingsDialog> createState() =>
      _CourtDisplaySettingsDialogState();
}

class _CourtDisplaySettingsDialogState
    extends State<CourtDisplaySettingsDialog> {
  late final List<TextEditingController> _controllers;

  bool _isCustomMode = false;
  bool _didResolveInitialMode = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    final initialLabelByCourtNumber = {
      for (final setting in widget.initialSettings)
        setting.courtNumber: setting.displayLabel,
    };

    _controllers = List.generate(widget.courtCount, (index) {
      final courtNumber = index + 1;
      final label = initialLabelByCourtNumber[courtNumber]?.trim();

      return TextEditingController(
        text: label == null || label.isEmpty ? courtNumber.toString() : label,
      );
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didResolveInitialMode) return;

    final currentLabels = _currentLabels();

    _isCustomMode = !_sameLabels(currentLabels, _numberPresetLabels()) &&
        !_sameLabels(currentLabels, _letterPresetLabels()) &&
        !_sameLabels(currentLabels, _leftRightPresetLabels(context)) &&
        !_sameLabels(currentLabels, _frontBackPresetLabels(context));

    _didResolveInitialMode = true;
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.displaySettingsDialogTitle),
      content: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.courtDisplaySectionTitle,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildPresetChip(
                    label: l10n.courtDisplayPresetNumbers,
                    labels: _numberPresetLabels(),
                  ),
                  _buildPresetChip(
                    label: l10n.courtDisplayPresetLetters,
                    labels: _letterPresetLabels(),
                  ),
                  _buildPresetChip(
                    label: l10n.courtDisplayPresetLeftRight,
                    labels: _leftRightPresetLabels(context),
                  ),
                  _buildPresetChip(
                    label: l10n.courtDisplayPresetFrontBack,
                    labels: _frontBackPresetLabels(context),
                  ),
                  ChoiceChip(
                    label: Text(l10n.courtDisplayPresetCustom),
                    selected: _isCustomMode,
                    onSelected: (_) {
                      setState(() {
                        _isCustomMode = true;
                        _errorMessage = null;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(widget.courtCount, (index) {
                  final courtNumber = index + 1;

                  return SizedBox(
                    width: 96,
                    child: TextField(
                      controller: _controllers[index],
                      enabled: _isCustomMode,
                      textAlign: TextAlign.center,
                      textInputAction: TextInputAction.next,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(1),
                      ],
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: l10n.courtDisplayInputLabel(courtNumber),
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (_) {
                        if (_errorMessage == null) return;

                        setState(() {
                          _errorMessage = null;
                        });
                      },
                    ),
                  );
                }),
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.error,
                    fontSize: 13,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(l10n.confirmButton),
        ),
      ],
    );
  }

  Widget _buildPresetChip({
    required String label,
    required List<String> labels,
  }) {
    final isSelected = !_isCustomMode && _sameLabels(_currentLabels(), labels);

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => _applyPreset(labels),
    );
  }

  void _applyPreset(List<String> labels) {
    setState(() {
      for (var index = 0; index < _controllers.length; index += 1) {
        _controllers[index].text = labels[index];
      }

      _isCustomMode = false;
      _errorMessage = null;
    });
  }

  void _submit() {
    final l10n = AppLocalizations.of(context);
    final labels = _currentLabels();

    if (labels.any((label) => label.isEmpty)) {
      setState(() {
        _errorMessage = l10n.courtDisplayEmptyError;
      });
      return;
    }

    if (labels.toSet().length != labels.length) {
      setState(() {
        _errorMessage = l10n.courtDisplayDuplicateError;
      });
      return;
    }

    final settings = List.generate(widget.courtCount, (index) {
      return SavedEventCourtSetting(
        courtNumber: index + 1,
        displayLabel: labels[index],
      );
    });

    Navigator.pop(context, settings);
  }

  List<String> _currentLabels() {
    return _controllers.map((controller) {
      return controller.text.trim();
    }).toList(growable: false);
  }

  List<String> _numberPresetLabels() {
    return List.generate(widget.courtCount, (index) {
      return (index + 1).toString();
    });
  }

  List<String> _letterPresetLabels() {
    return List.generate(widget.courtCount, (index) {
      if (index < 26) {
        return String.fromCharCode('A'.codeUnitAt(0) + index);
      }

      return (index + 1).toString();
    });
  }

  List<String> _leftRightPresetLabels(BuildContext context) {
    final labels = _directionLabels(
      context,
      japaneseStart: '左',
      japaneseEnd: '右',
      englishStart: 'L',
      englishEnd: 'R',
    );

    return _edgePresetLabels(labels.start, labels.end);
  }

  List<String> _frontBackPresetLabels(BuildContext context) {
    final labels = _directionLabels(
      context,
      japaneseStart: '前',
      japaneseEnd: '奥',
      englishStart: 'F',
      englishEnd: 'B',
    );

    return _edgePresetLabels(labels.start, labels.end);
  }

  List<String> _edgePresetLabels(String start, String end) {
    if (widget.courtCount <= 1) {
      return [start];
    }

    if (widget.courtCount == 2) {
      return [start, end];
    }

    return List.generate(widget.courtCount, (index) {
      if (index == 0) return start;
      if (index == widget.courtCount - 1) return end;

      return (index + 1).toString();
    });
  }

  ({String start, String end}) _directionLabels(
    BuildContext context, {
    required String japaneseStart,
    required String japaneseEnd,
    required String englishStart,
    required String englishEnd,
  }) {
    final languageCode = Localizations.localeOf(context).languageCode;

    if (languageCode == 'ja') {
      return (start: japaneseStart, end: japaneseEnd);
    }

    return (start: englishStart, end: englishEnd);
  }

  bool _sameLabels(List<String> a, List<String> b) {
    if (a.length != b.length) return false;

    for (var index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }

    return true;
  }
}
