import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srp_lanske/l10n/l10n.dart';

import '../../application/event_repository.dart';
import '../../domain/saved_event_models.dart';

class CourtDisplaySettingsDialog extends StatefulWidget {
  const CourtDisplaySettingsDialog({
    super.key,
    required this.initialAggregate,
    required this.repository,
  });

  final SavedEventAggregate initialAggregate;
  final EventRepository repository;

  @override
  State<CourtDisplaySettingsDialog> createState() =>
      _CourtDisplaySettingsDialogState();
}

class _CourtDisplaySettingsDialogState
    extends State<CourtDisplaySettingsDialog> {
  late final List<TextEditingController> _controllers;
  late SavedEventAggregate _latestAggregate;
  late int _expectedCourtSettingsRevision;

  bool _isCustomMode = false;
  bool _didResolveInitialMode = false;
  bool _isSaving = false;
  bool _messageIsError = false;
  String? _message;

  int get _courtCount => widget.initialAggregate.event.courtCount;

  @override
  void initState() {
    super.initState();

    _latestAggregate = widget.initialAggregate;
    _expectedCourtSettingsRevision =
        widget.initialAggregate.revisions.courtSettings;

    final initialLabelByCourtNumber = {
      for (final setting in widget.initialAggregate.courtSettings)
        setting.courtNumber: setting.displayLabel,
    };

    _controllers = List.generate(_courtCount, (index) {
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

    return PopScope(
      canPop: !_isSaving,
      child: AlertDialog(
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
                    onSelected: _isSaving
                        ? null
                        : (_) {
                            setState(() {
                              _isCustomMode = true;
                              _message = null;
                              _messageIsError = false;
                            });
                          },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: List.generate(_courtCount, (index) {
                  final courtNumber = index + 1;

                  return SizedBox(
                    width: 96,
                    child: TextField(
                      controller: _controllers[index],
                      enabled: _isCustomMode && !_isSaving,
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
                        if (_message == null) return;

                        setState(() {
                          _message = null;
                          _messageIsError = false;
                        });
                      },
                    ),
                  );
                }),
              ),
              if (_message != null) ...[
                const SizedBox(height: 12),
                Text(
                  _message!,
                  style: TextStyle(
                    color: _messageIsError
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.primary,
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
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
          ),
          FilledButton(
            onPressed: _isSaving ? null : _submit,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.confirmButton),
          ),
        ],
      ),
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
      onSelected: _isSaving ? null : (_) => _applyPreset(labels),
    );
  }

  void _applyPreset(List<String> labels) {
    setState(() {
      for (var index = 0; index < _controllers.length; index += 1) {
        _controllers[index].text = labels[index];
      }

      _isCustomMode = false;
      _message = null;
      _messageIsError = false;
    });
  }

  Future<void> _submit() async {
    if (_isSaving) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    final labels = _currentLabels();

    if (labels.any((label) => label.isEmpty)) {
      setState(() {
        _message = l10n.courtDisplayEmptyError;
        _messageIsError = true;
      });
      return;
    }

    if (labels.toSet().length != labels.length) {
      setState(() {
        _message = l10n.courtDisplayDuplicateError;
        _messageIsError = true;
      });
      return;
    }

    final settings = List.generate(_courtCount, (index) {
      return SavedEventCourtSetting(
        courtNumber: index + 1,
        displayLabel: labels[index],
      );
    });

    setState(() {
      _isSaving = true;
      _message = null;
      _messageIsError = false;
    });

    try {
      final updated = await widget.repository.updateCourtSettingsWithRevision(
        publicId: _latestAggregate.event.publicId,
        expectedCourtSettingsRevision: _expectedCourtSettingsRevision,
        courtSettings: settings,
      );

      if (!mounted) return;
      Navigator.pop(context, updated);
    } on EventRevisionConflictException {
      await _handleConflict(l10n);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _message = l10n.courtDisplaySaveFailedMessage(error.toString());
        _messageIsError = true;
      });
    }
  }

  Future<void> _handleConflict(AppLocalizations l10n) async {
    try {
      final latest = await widget.repository.findByPublicId(
        _latestAggregate.event.publicId,
      );
      if (!mounted) return;

      if (latest == null || latest.event.courtCount != _courtCount) {
        setState(() {
          _isSaving = false;
          _message = l10n.courtDisplayLatestLoadFailedMessage;
          _messageIsError = true;
        });
        return;
      }

      setState(() {
        _latestAggregate = latest;
        _expectedCourtSettingsRevision = latest.revisions.courtSettings;
        _isSaving = false;
        _message = l10n.courtDisplayConflictMessage;
        _messageIsError = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _message = l10n.courtDisplayLatestLoadFailedMessage;
        _messageIsError = true;
      });
    }
  }

  List<String> _currentLabels() {
    return _controllers.map((controller) {
      return controller.text.trim();
    }).toList(growable: false);
  }

  List<String> _numberPresetLabels() {
    return List.generate(_courtCount, (index) {
      return (index + 1).toString();
    });
  }

  List<String> _letterPresetLabels() {
    return List.generate(_courtCount, (index) {
      if (index < 26) {
        return String.fromCharCode('A'.codeUnitAt(0) + index);
      }

      return (index + 1).toString();
    });
  }

  List<String> _leftRightPresetLabels(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return _edgePresetLabels(
      l10n.courtDisplayLabelLeft,
      l10n.courtDisplayLabelRight,
    );
  }

  List<String> _frontBackPresetLabels(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return _edgePresetLabels(
      l10n.courtDisplayLabelFront,
      l10n.courtDisplayLabelBack,
    );
  }

  List<String> _edgePresetLabels(String start, String end) {
    if (_courtCount <= 1) {
      return [start];
    }

    if (_courtCount == 2) {
      return [start, end];
    }

    return List.generate(_courtCount, (index) {
      if (index == 0) return start;
      if (index == _courtCount - 1) return end;

      return (index + 1).toString();
    });
  }

  bool _sameLabels(List<String> a, List<String> b) {
    if (a.length != b.length) return false;

    for (var index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) return false;
    }

    return true;
  }
}
