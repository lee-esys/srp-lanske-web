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
    this.onRefresh,
    super.key,
  });

  final BocciaMatchScore initialScore;
  final String redTeamName;
  final String blueTeamName;
  final List<BocciaScorePlayerOption> redPlayerOptions;
  final List<BocciaScorePlayerOption> bluePlayerOptions;
  final Future<BocciaMatchScore> Function(BocciaMatchScore score) onSave;
  final Future<BocciaMatchScore?> Function()? onRefresh;

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
  bool _isRefreshing = false;
  String? _statusMessage;
  String? _errorMessage;

  bool get _isBusy => _isSaving || _isRefreshing;

  int _selectedEndNo = 1;
  bool _isEditingThrowingBoxAssignments = false;

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

  Future<void> _refreshLatestScore() async {
    final onRefresh = widget.onRefresh;
    if (_isBusy || onRefresh == null) {
      return;
    }

    final l10n = AppLocalizations.of(context);

    if (_isDirty) {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return AlertDialog(
            title: Text(l10n.refreshBocciaScoreDiscardChangesTitle),
            content: Text(l10n.refreshBocciaScoreDiscardChangesBody),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                child: Text(l10n.cancelRefreshBocciaScoreButton),
              ),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                child: Text(l10n.confirmRefreshBocciaScoreButton),
              ),
            ],
          );
        },
      );

      if (!mounted || confirmed != true) {
        return;
      }
    }

    setState(() {
      _isRefreshing = true;
      _statusMessage = null;
      _errorMessage = null;
    });

    try {
      final refreshed = await onRefresh();

      if (!mounted) {
        return;
      }

      if (refreshed == null) {
        setState(() {
          _errorMessage = l10n.refreshBocciaScoreFailedMessage;
          _isRefreshing = false;
        });
        return;
      }

      setState(() {
        _draftScore = refreshed;
        _lastSavedScore = refreshed;
        _selectedEndNo = 1;
        _isEditingThrowingBoxAssignments = false;
        _statusMessage = l10n.bocciaScoreRefreshedMessage;
        _isRefreshing = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
        _isRefreshing = false;
      });
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
    if (!_draftScore.canEditThrowingBoxAssignments) {
      return;
    }

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
      _selectedEndNo = endNo;
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

  void _selectEnd(int endNo) {
    setState(() {
      _selectedEndNo = endNo;
      _isEditingThrowingBoxAssignments = false;
    });
  }

  void _toggleThrowingBoxAssignmentMode() {
    if (!_draftScore.canEditThrowingBoxAssignments) {
      return;
    }

    setState(() {
      _isEditingThrowingBoxAssignments = !_isEditingThrowingBoxAssignments;
    });
  }

  void _addThrowLog({
    required int boxNo,
  }) {
    setState(() {
      _draftScore = _draftScore.addThrowLog(
        endNo: _selectedEndNo,
        boxNo: boxNo,
      );
      _statusMessage = null;
      _errorMessage = null;
    });
  }

  void _removeLastThrowLog() {
    setState(() {
      _draftScore = _draftScore.removeLastThrowLog(
        endNo: _selectedEndNo,
      );
      _statusMessage = null;
      _errorMessage = null;
    });
  }

  Future<void> _clearSelectedEndThrowLogs() async {
    final hasLogs = _draftScore.throwLogCountForEnd(_selectedEndNo) > 0;
    if (!hasLogs) {
      return;
    }

    final l10n = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.clearBocciaEndThrowLogsDialogTitle),
          content: Text(l10n.clearBocciaEndThrowLogsDialogBody),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: Text(l10n.cancelClearBocciaEndThrowLogsButton),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: Text(l10n.confirmClearBocciaEndThrowLogsButton),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) {
      return;
    }

    setState(() {
      _draftScore = _draftScore.clearThrowLogsForEnd(
        endNo: _selectedEndNo,
      );
      _statusMessage = null;
      _errorMessage = null;
    });
  }

  String _playerNameForAssignment(
    BocciaThrowingBoxAssignment assignment,
    AppLocalizations l10n,
  ) {
    final playerSlot = assignment.playerSlot;
    if (playerSlot == null) {
      return l10n.bocciaUnusedThrowingBoxLabel;
    }

    final playerOptions = _playerOptionsForAssignment(assignment);
    for (final option in playerOptions) {
      if (option.playerSlot == playerSlot) {
        return option.displayName;
      }
    }

    return l10n.bocciaDefaultParticipantName(playerSlot);
  }

  String _playerNameForThrowLog(
    BocciaThrowLog log,
    AppLocalizations l10n,
  ) {
    final playerOptions = switch (log.side) {
      BocciaThrowingSide.red => _redPlayerOptions(_draftScore),
      BocciaThrowingSide.blue => _bluePlayerOptions(_draftScore),
    };

    for (final option in playerOptions) {
      if (option.playerSlot == log.playerSlot) {
        return option.displayName;
      }
    }

    return l10n.bocciaDefaultParticipantName(log.playerSlot);
  }

  String _throwingSideLabel(
    BocciaThrowingSide side,
    AppLocalizations l10n,
  ) {
    return switch (side) {
      BocciaThrowingSide.red => l10n.bocciaRedSideLabel,
      BocciaThrowingSide.blue => l10n.bocciaBlueSideLabel,
    };
  }

  Widget _buildConcurrentEditNotice(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            size: 18,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.teamScheduleConcurrentEditNotice,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderHeader(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.tonalIcon(
          onPressed: _isBusy || !_draftScore.canEditThrowingBoxAssignments
              ? null
              : _swapOrder,
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

  Widget _buildEndHeader(
    BuildContext context,
    int endNo,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isSelected = endNo == _selectedEndNo;

    return InkWell(
      onTap: () {
        _selectEnd(endNo);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          l10n.bocciaEndLabel(endNo),
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: isSelected ? FontWeight.bold : null,
            color: isSelected ? theme.colorScheme.primary : null,
          ),
        ),
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
              label: _buildEndHeader(context, endScore.endNo),
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
      onChanged: _isBusy ? null : onChanged,
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
    final l10n = AppLocalizations.of(context);
    final assignments = _draftScore.throwingBoxAssignments;
    final canEditAssignments = _draftScore.canEditThrowingBoxAssignments;
    final selectedEndThrowCount =
        _draftScore.throwLogCountForEnd(_selectedEndNo);
    final redThrowCount = _draftScore.throwLogCountForEndSide(
      endNo: _selectedEndNo,
      side: BocciaThrowingSide.red,
    );
    final blueThrowCount = _draftScore.throwLogCountForEndSide(
      endNo: _selectedEndNo,
      side: BocciaThrowingSide.blue,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            FilledButton.tonalIcon(
              onPressed: _isBusy || !canEditAssignments
                  ? null
                  : _toggleThrowingBoxAssignmentMode,
              icon: Icon(
                _isEditingThrowingBoxAssignments
                    ? Icons.list_alt
                    : Icons.edit_location_alt,
              ),
              label: Text(
                _isEditingThrowingBoxAssignments
                    ? l10n.bocciaReturnToThrowLogButton
                    : l10n.bocciaThrowingBoxSettingsButton,
              ),
            ),
            if (!canEditAssignments) ...[
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.bocciaThrowingBoxLockedMessage,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 12),
            Text(
              l10n.bocciaThrowCountProgress(
                count: selectedEndThrowCount,
                maxCount: 12,
              ),
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.bocciaThrowLogTitle(_selectedEndNo),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              l10n.bocciaThrowCountSummary(
                redCount: redThrowCount,
                blueCount: blueThrowCount,
              ),
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          l10n.bocciaThrowLogHelp,
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final assignment in assignments) ...[
                _buildThrowingBoxCard(
                  context,
                  assignment,
                  isEditing:
                      _isEditingThrowingBoxAssignments && canEditAssignments,
                ),
                if (assignment != assignments.last) const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildThrowOrderSection(context),
      ],
    );
  }

  Widget _buildThrowingBoxCard(
    BuildContext context,
    BocciaThrowingBoxAssignment assignment, {
    required bool isEditing,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final isRed = assignment.side == BocciaThrowingSide.red;
    final playerOptions = _playerOptionsForAssignment(assignment);
    final selectedPlayerSlot = playerOptions.any(
      (option) => option.playerSlot == assignment.playerSlot,
    )
        ? assignment.playerSlot
        : null;
    final playerName = _playerNameForAssignment(assignment, l10n);
    final throwCount = _draftScore.throwLogCountForEndBox(
      endNo: _selectedEndNo,
      boxNo: assignment.boxNo,
    );
    final canAdd = !_isBusy &&
        assignment.hasPlayer &&
        _draftScore.canAddThrowLogForEnd(_selectedEndNo) &&
        !isEditing;

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
          if (isEditing)
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
              onChanged: _isBusy
                  ? null
                  : (value) {
                      _setThrowingBoxPlayer(
                        boxNo: assignment.boxNo,
                        playerSlot: value,
                      );
                    },
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(l10n.bocciaUnusedThrowingBoxLabel),
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
            )
          else ...[
            Text(
              playerName,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: assignment.hasPlayer ? FontWeight.bold : null,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              assignment.hasPlayer
                  ? l10n.bocciaThrowCountForBox(throwCount)
                  : '',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            if (assignment.hasPlayer)
              IconButton(
                onPressed: canAdd
                    ? () {
                        _addThrowLog(boxNo: assignment.boxNo);
                      }
                    : null,
                icon: const Icon(Icons.add),
                tooltip: l10n.bocciaAddThrowLogTooltip,
              )
            else
              const SizedBox(height: 48),
          ],
        ],
      ),
    );
  }

  Widget _buildThrowOrderSection(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final logs = _draftScore.throwLogsForEnd(_selectedEndNo);
    final hasLogs = logs.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.bocciaThrowOrderTitle,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            TextButton.icon(
              onPressed:
                  _isBusy || !hasLogs ? null : _clearSelectedEndThrowLogs,
              icon: const Icon(Icons.delete_outline),
              label: Text(l10n.clearBocciaEndThrowLogsButton),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (!hasLogs)
          Text(
            l10n.bocciaNoThrowLogsMessage,
            style: theme.textTheme.bodySmall,
          )
        else
          _buildThrowOrderGrid(context, logs),
      ],
    );
  }

  Widget _buildThrowOrderGrid(
    BuildContext context,
    List<BocciaThrowLog> logs,
  ) {
    final columns = <Widget>[];

    for (var columnIndex = 0; columnIndex < 3; columnIndex += 1) {
      final startIndex = columnIndex * 4;
      final columnLogs = logs.skip(startIndex).take(4).toList(growable: false);

      columns.add(
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final log in columnLogs) _buildThrowOrderItem(context, log),
              for (var index = columnLogs.length; index < 4; index += 1)
                const SizedBox(height: 36),
            ],
          ),
        ),
      );

      if (columnIndex < 2) {
        columns.add(const SizedBox(width: 12));
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: columns,
    );
  }

  Widget _buildThrowOrderItem(
    BuildContext context,
    BocciaThrowLog log,
  ) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final logs = _draftScore.throwLogsForEnd(_selectedEndNo);
    final isLast = logs.isNotEmpty &&
        logs.last.endNo == log.endNo &&
        logs.last.throwNo == log.throwNo;

    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.bocciaThrowOrderItem(
                throwNo: log.throwNo,
                playerName: _playerNameForThrowLog(log, l10n),
                sideLabel: _throwingSideLabel(log.side, l10n),
                boxNo: log.boxNo,
              ),
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall,
            ),
          ),
          if (isLast)
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              onPressed: _isBusy ? null : _removeLastThrowLog,
              icon: const Icon(Icons.remove_circle_outline),
              tooltip: l10n.removeLastBocciaThrowLogTooltip,
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

    if (_isRefreshing) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(
            l10n.refreshingTeamScheduleScoresMessage,
            style: theme.textTheme.bodySmall,
          ),
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
              _buildConcurrentEditNotice(context),
              const SizedBox(height: 12),
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
              TextButton.icon(
                onPressed: _isBusy || widget.onRefresh == null
                    ? null
                    : _refreshLatestScore,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.refreshLatestTeamScheduleButton),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: _isBusy ? null : _close,
                child: Text(l10n.closeBocciaScoreDialogButton),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _isBusy ? null : _save,
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
      a.throwingBoxAssignments.length != b.throwingBoxAssignments.length ||
      a.throwLogs.length != b.throwLogs.length) {
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

  for (var index = 0; index < a.throwLogs.length; index += 1) {
    final aLog = a.throwLogs[index];
    final bLog = b.throwLogs[index];

    if (aLog.endNo != bLog.endNo ||
        aLog.throwNo != bLog.throwNo ||
        aLog.side != bLog.side ||
        aLog.boxNo != bLog.boxNo ||
        aLog.teamSlot != bLog.teamSlot ||
        aLog.playerSlot != bLog.playerSlot) {
      return false;
    }
  }

  return true;
}
