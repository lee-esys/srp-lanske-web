import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

import '../../domain/boccia_score.dart';

class BocciaScoreDialog extends StatefulWidget {
  const BocciaScoreDialog({
    required this.initialScore,
    required this.redTeamName,
    required this.blueTeamName,
    required this.redPlayerOptions,
    required this.bluePlayerOptions,
    required this.onSave,
    super.key,
  });

  final BocciaMatchScore initialScore;
  final String redTeamName;
  final String blueTeamName;
  final List<BocciaScorePlayerOption> redPlayerOptions;
  final List<BocciaScorePlayerOption> bluePlayerOptions;
  final Future<BocciaMatchScore> Function(BocciaMatchScore score) onSave;

  @override
  State<BocciaScoreDialog> createState() => _BocciaScoreDialogState();
}

class BocciaScorePlayerOption {
  const BocciaScorePlayerOption({
    required this.playerSlot,
    required this.displayName,
  });

  final int playerSlot;
  final String displayName;
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

  List<BocciaScorePlayerOption> _redPlayerOptions(BocciaMatchScore score) {
    if (score.redTeamSlot == widget.initialScore.redTeamSlot) {
      return widget.redPlayerOptions;
    }

    return widget.bluePlayerOptions;
  }

  List<BocciaScorePlayerOption> _bluePlayerOptions(BocciaMatchScore score) {
    if (score.blueTeamSlot == widget.initialScore.blueTeamSlot) {
      return widget.bluePlayerOptions;
    }

    return widget.redPlayerOptions;
  }

  List<BocciaScorePlayerOption> _playerOptionsForAssignment(
    BocciaThrowingBoxAssignment assignment,
  ) {
    return switch (assignment.side) {
      BocciaThrowingSide.red => _redPlayerOptions(_draftScore),
      BocciaThrowingSide.blue => _bluePlayerOptions(_draftScore),
    };
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

  void _setThrowingBoxPlayer({
    required int boxNo,
    required int? playerSlot,
  }) {
    setState(() {
      _draftScore = _draftScore.replaceThrowingBoxPlayer(
        boxNo: boxNo,
        playerSlot: playerSlot,
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
              const DataCell(SizedBox.shrink()),
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
              const DataCell(SizedBox.shrink()),
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

  Widget _buildThrowingBoxSection(BuildContext context) {
    final theme = Theme.of(context);
    final assignments = _draftScore.throwingBoxAssignments;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '投球場所',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '赤は奇数ボックス、青は偶数ボックスに投球者を設定します。',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final assignment in assignments) ...[
                _buildThrowingBoxCard(context, assignment),
                if (assignment != assignments.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThrowingBoxCard(
    BuildContext context,
    BocciaThrowingBoxAssignment assignment,
  ) {
    final theme = Theme.of(context);
    final isRed = assignment.side == BocciaThrowingSide.red;
    final playerOptions = _playerOptionsForAssignment(assignment);
    final selectedPlayerSlot = playerOptions.any(
      (option) => option.playerSlot == assignment.playerSlot,
    )
        ? assignment.playerSlot
        : null;

    return Container(
      width: 150,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isRed ? Colors.red.shade50 : Colors.blue.shade50,
        border: Border.all(
          color: isRed ? Colors.red.shade200 : Colors.blue.shade200,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${assignment.boxNo}',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int?>(
            initialValue: selectedPlayerSlot,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
            ),
            onChanged: _isSaving
                ? null
                : (value) {
                    _setThrowingBoxPlayer(
                      boxNo: assignment.boxNo,
                      playerSlot: value,
                    );
                  },
            items: [
              const DropdownMenuItem<int?>(
                value: null,
                child: Text('未使用'),
              ),
              for (final option in playerOptions)
                DropdownMenuItem<int?>(
                  value: option.playerSlot,
                  child: Text(
                    option.displayName,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
          ),
        ],
      ),
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
    final dialogWidth = MediaQuery.sizeOf(context).width * 0.95;

    return AlertDialog(
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 24,
      ),
      title: Text(l10n.bocciaScoreDialogTitle),
      content: SizedBox(
        width: dialogWidth,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOrderHeader(context),
              const SizedBox(height: 16),
              _buildScoreTable(context),
              const SizedBox(height: 16),
              _buildThrowingBoxSection(context),
            ],
          ),
        ),
      ),
      actions: [
        SizedBox(
          width: dialogWidth,
          child: Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildStatus(context),
                ),
              ),
              TextButton(
                onPressed: _isSaving ? null : _close,
                child: Text(l10n.closeBocciaScoreDialogButton),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: Text(l10n.saveBocciaScoreButton),
              ),
            ],
          ),
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
      a.endScores.length != b.endScores.length ||
      a.throwingBoxAssignments.length != b.throwingBoxAssignments.length) {
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

  for (var index = 0; index < a.throwingBoxAssignments.length; index += 1) {
    final aAssignment = a.throwingBoxAssignments[index];
    final bAssignment = b.throwingBoxAssignments[index];

    if (aAssignment.boxNo != bAssignment.boxNo ||
        aAssignment.side != bAssignment.side ||
        aAssignment.playerSlot != bAssignment.playerSlot) {
      return false;
    }
  }

  return true;
}
