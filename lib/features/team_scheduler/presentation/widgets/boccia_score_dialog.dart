import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

import '../../domain/boccia_score.dart';

class BocciaScoreDialog extends StatefulWidget {
  const BocciaScoreDialog({
    required this.initialScore,
    required this.redTeamName,
    required this.blueTeamName,
    required this.onSave,
    super.key,
  });

  final BocciaMatchScore initialScore;
  final String redTeamName;
  final String blueTeamName;
  final Future<BocciaMatchScore> Function(BocciaMatchScore score) onSave;

  @override
  State<BocciaScoreDialog> createState() => _BocciaScoreDialogState();
}

class _BocciaScoreDialogState extends State<BocciaScoreDialog> {
  late BocciaMatchScore _draftScore;
  late BocciaMatchScore _lastSavedScore;

  bool _isSaving = false;
  String? _statusMessage;
  String? _errorMessage;

  bool get _isDirty => !_scoreEquals(_draftScore, _lastSavedScore);

  @override
  void initState() {
    super.initState();
    _draftScore = widget.initialScore;
    _lastSavedScore = widget.initialScore;
  }

  String _redTeamName(BocciaMatchScore score) {
    if (score.redTeamSlot == widget.initialScore.redTeamSlot) {
      return widget.redTeamName;
    }

    return widget.blueTeamName;
  }

  String _blueTeamName(BocciaMatchScore score) {
    if (score.blueTeamSlot == widget.initialScore.blueTeamSlot) {
      return widget.blueTeamName;
    }

    return widget.redTeamName;
  }

  Future<bool> _save() async {
    if (_isSaving) {
      return false;
    }

    setState(() {
      _isSaving = true;
      _statusMessage = null;
      _errorMessage = null;
    });

    try {
      final saved = await widget.onSave(_draftScore);

      if (!mounted) {
        return false;
      }

      setState(() {
        _draftScore = saved;
        _lastSavedScore = saved;
        _statusMessage = AppLocalizations.of(context).bocciaScoreSavedMessage;
        _isSaving = false;
      });

      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }

      setState(() {
        _errorMessage = error.toString();
        _isSaving = false;
      });

      return false;
    }
  }

  Future<void> _close() async {
    if (!_isDirty) {
      Navigator.of(context).pop(_lastSavedScore);
      return;
    }

    final action = await showDialog<_UnsavedAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final l10n = AppLocalizations.of(context);

        return AlertDialog(
          title: Text(l10n.bocciaScoreDiscardChangesTitle),
          content: Text(l10n.bocciaScoreDiscardChangesBody),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_UnsavedAction.returnToInput);
              },
              child: Text(l10n.returnToBocciaScoreInputButton),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_UnsavedAction.discardAndClose);
              },
              child: Text(l10n.discardBocciaScoreChangesButton),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(_UnsavedAction.saveAndClose);
              },
              child: Text(l10n.saveAndCloseBocciaScoreButton),
            ),
          ],
        );
      },
    );

    if (!mounted || action == null || action == _UnsavedAction.returnToInput) {
      return;
    }

    if (action == _UnsavedAction.discardAndClose) {
      Navigator.of(context).pop(_lastSavedScore);
      return;
    }

    final saved = await _save();
    if (!mounted || !saved) {
      return;
    }

    Navigator.of(context).pop(_lastSavedScore);
  }

  void _swapOrder() {
    setState(() {
      _draftScore = _draftScore.swapped();
      _statusMessage = null;
      _errorMessage = null;
    });
  }

  void _setEndScore({
    required int endNo,
    int? red,
    int? blue,
  }) {
    setState(() {
      _draftScore = _draftScore.replaceEndScore(
        endNo: endNo,
        red: red,
        blue: blue,
      );
      _statusMessage = null;
      _errorMessage = null;
    });
  }

  Widget _buildOrderHeader(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.tonalIcon(
          onPressed: _isSaving ? null : _swapOrder,
          icon: const Icon(Icons.swap_horiz),
          label: Text(l10n.swapBocciaOrderButton),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTeamHeader(
                context,
                label: l10n.bocciaFirstTeamLabel,
                teamName: _redTeamName(_draftScore),
                backgroundColor: Colors.red.shade50,
                borderColor: Colors.red.shade200,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTeamHeader(
                context,
                label: l10n.bocciaSecondTeamLabel,
                teamName: _blueTeamName(_draftScore),
                backgroundColor: Colors.blue.shade50,
                borderColor: Colors.blue.shade200,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          l10n.bocciaScoreDialogMatchTitle(
            redTeamName: _redTeamName(_draftScore),
            blueTeamName: _blueTeamName(_draftScore),
          ),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildTeamHeader(
    BuildContext context, {
    required String label,
    required String teamName,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          Text(
            teamName,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreTable(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 44,
        dataRowMinHeight: 52,
        dataRowMaxHeight: 56,
        columns: [
          const DataColumn(label: SizedBox(width: 56)),
          for (final endScore in _draftScore.endScores)
            DataColumn(
              label: Text(l10n.bocciaEndLabel(endScore.endNo)),
            ),
          DataColumn(
            label: Text(l10n.bocciaTotalLabel),
          ),
        ],
        rows: [
          DataRow(
            color: WidgetStatePropertyAll(Colors.red.shade50),
            cells: [
              DataCell(Text(l10n.bocciaFirstTeamLabel)),
              for (final endScore in _draftScore.endScores)
                DataCell(
                  _buildScoreDropdown(
                    value: endScore.red,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      _setEndScore(
                        endNo: endScore.endNo,
                        red: value,
                      );
                    },
                  ),
                ),
              DataCell(
                Text(
                  _draftScore.totalRedScore.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          DataRow(
            color: WidgetStatePropertyAll(Colors.blue.shade50),
            cells: [
              DataCell(Text(l10n.bocciaSecondTeamLabel)),
              for (final endScore in _draftScore.endScores)
                DataCell(
                  _buildScoreDropdown(
                    value: endScore.blue,
                    onChanged: (value) {
                      if (value == null) {
                        return;
                      }

                      _setEndScore(
                        endNo: endScore.endNo,
                        blue: value,
                      );
                    },
                  ),
                ),
              DataCell(
                Text(
                  _draftScore.totalBlueScore.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreDropdown({
    required int value,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButton<int>(
      value: value,
      onChanged: _isSaving ? null : onChanged,
      items: [
        for (var score = 0; score <= 6; score += 1)
          DropdownMenuItem<int>(
            value: score,
            child: Text(score.toString()),
          ),
      ],
    );
  }

  Widget _buildStatus(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    if (_isSaving) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(l10n.savingTeamScheduleScoresMessage),
        ],
      );
    }

    final errorMessage = _errorMessage;
    if (errorMessage != null && errorMessage.isNotEmpty) {
      return Text(
        l10n.teamScheduleScoresSaveFailedMessage(errorMessage),
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.error,
        ),
      );
    }

    final statusMessage = _statusMessage;
    if (statusMessage != null && statusMessage.isNotEmpty) {
      return Text(
        statusMessage,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    if (_isDirty) {
      return Text(
        l10n.bocciaScoreUnsavedChangesMessage,
        style: theme.textTheme.bodySmall,
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(l10n.bocciaScoreDialogTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOrderHeader(context),
              const SizedBox(height: 16),
              _buildScoreTable(context),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: _buildStatus(context),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : _close,
          child: Text(l10n.closeBocciaScoreDialogButton),
        ),
        FilledButton(
          onPressed: _isSaving ? null : _save,
          child: Text(l10n.saveBocciaScoreButton),
        ),
      ],
    );
  }
}

enum _UnsavedAction {
  returnToInput,
  discardAndClose,
  saveAndClose,
}

bool _scoreEquals(BocciaMatchScore a, BocciaMatchScore b) {
  if (a.matchNo != b.matchNo ||
      a.redTeamSlot != b.redTeamSlot ||
      a.blueTeamSlot != b.blueTeamSlot ||
      a.endScores.length != b.endScores.length) {
    return false;
  }

  for (var index = 0; index < a.endScores.length; index += 1) {
    final aEnd = a.endScores[index];
    final bEnd = b.endScores[index];

    if (aEnd.endNo != bEnd.endNo ||
        aEnd.red != bEnd.red ||
        aEnd.blue != bEnd.blue) {
      return false;
    }
  }

  return true;
}
