import 'package:flutter/material.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/doubles_match_progress_service.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/doubles_match_save_registry.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/models/doubles_match_editor_models.dart';
import 'package:srp_lanske/features/schedule_progress/application/schedule_progress_repository.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';
import 'package:srp_lanske/l10n/l10n.dart';

import 'schedule_player_chip.dart';

typedef DoublesMatchLoadCallback = Future<ScheduleMatchProgress> Function(
  DoublesMatchSelection match,
);

class DoublesMatchResultDialog extends StatefulWidget {
  const DoublesMatchResultDialog({
    required this.match,
    required this.initialProgress,
    this.matches = const <DoublesMatchSelection>[],
    this.onLoadMatch,
    this.onSave,
    super.key,
  });

  final DoublesMatchSelection match;
  final ScheduleMatchProgress initialProgress;
  final List<DoublesMatchSelection> matches;
  final DoublesMatchLoadCallback? onLoadMatch;
  final DoublesMatchSaveCallback? onSave;

  @override
  State<DoublesMatchResultDialog> createState() =>
      _DoublesMatchResultDialogState();
}

class _DoublesMatchResultDialogState extends State<DoublesMatchResultDialog> {
  late DoublesMatchSelection _match;
  late ScheduleMatchProgress _baselineProgress;
  late ScheduleMatchStatus _status;
  late int? _side1Score;
  late int? _side2Score;
  late DateTime? _startedAt;
  late DateTime? _finishedAt;
  late final TextEditingController _noteController;

  bool _isSaving = false;
  bool _isLoadingMatch = false;
  bool _suppressNoteListener = false;
  String? _statusMessage;
  String? _errorMessage;

  bool get _isBusy => _isSaving || _isLoadingMatch;

  DoublesMatchProgressInput get _draftInput {
    return DoublesMatchProgressInput(
      status: _status,
      side1Score: _side1Score,
      side2Score: _side2Score,
      note: _noteController.text,
      startedAt: _startedAt,
      finishedAt: _finishedAt,
    );
  }

  bool get _isDirty {
    return !doublesMatchProgressInputsEqual(
      _draftInput,
      buildDoublesMatchProgressInput(_baselineProgress),
    );
  }

  int get _currentMatchIndex {
    return widget.matches.indexWhere((candidate) {
      return candidate.roundNo == _match.roundNo &&
          candidate.courtNo == _match.courtNo;
    });
  }

  @override
  void initState() {
    super.initState();
    _match = widget.match;
    _baselineProgress = widget.initialProgress;
    final input = buildDoublesMatchProgressInput(_baselineProgress);
    _status = input.status;
    _side1Score = input.side1Score;
    _side2Score = input.side2Score;
    _startedAt = input.startedAt;
    _finishedAt = input.finishedAt;
    _noteController = TextEditingController(text: input.note)
      ..addListener(_handleNoteChanged);
  }

  @override
  void dispose() {
    _noteController
      ..removeListener(_handleNoteChanged)
      ..dispose();
    super.dispose();
  }

  void _handleNoteChanged() {
    if (_suppressNoteListener || !mounted) {
      return;
    }
    setState(_clearFeedback);
  }

  void _clearFeedback() {
    _statusMessage = null;
    _errorMessage = null;
  }

  void _applyProgress(ScheduleMatchProgress progress) {
    final input = buildDoublesMatchProgressInput(progress);
    _baselineProgress = progress;
    _status = input.status;
    _side1Score = input.side1Score;
    _side2Score = input.side2Score;
    _startedAt = input.startedAt;
    _finishedAt = input.finishedAt;

    _suppressNoteListener = true;
    _noteController.value = TextEditingValue(
      text: input.note,
      selection: TextSelection.collapsed(offset: input.note.length),
    );
    _suppressNoteListener = false;
  }

  void _selectStatus(ScheduleMatchStatus status) {
    if (_isBusy) {
      return;
    }

    final previousStatus = _status;
    final now = DateTime.now();

    setState(() {
      _clearFeedback();
      _status = status;
      switch (status) {
        case ScheduleMatchStatus.scheduled:
          _startedAt = null;
          _finishedAt = null;
          break;
        case ScheduleMatchStatus.inProgress:
          _startedAt ??= now;
          _finishedAt = null;
          break;
        case ScheduleMatchStatus.completed:
          if (previousStatus == ScheduleMatchStatus.scheduled &&
              _startedAt == null) {
            _startedAt = now;
            _finishedAt = now;
          } else {
            _finishedAt ??= now;
          }
          break;
      }
    });
  }

  void _adjustScore({required bool side1, required int delta}) {
    if (_isBusy) {
      return;
    }

    final current = side1 ? _side1Score : _side2Score;

    setState(() {
      _clearFeedback();
      if (_side1Score == null || _side2Score == null) {
        final next = delta > 0 ? 1 : 0;
        _side1Score = side1 ? next : 0;
        _side2Score = side1 ? 0 : next;
        return;
      }

      final next = ((current ?? 0) + delta).clamp(0, 9).toInt();
      if (side1) {
        _side1Score = next;
      } else {
        _side2Score = next;
      }
    });
  }

  Future<void> _pickScore({required bool side1}) async {
    if (_isBusy) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    final selected = await showModalBottomSheet<int>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.doublesMatchScorePickerTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var score = 0; score <= 9; score += 1)
                      SizedBox(
                        width: 52,
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).pop(score),
                          child: Text('$score'),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => Navigator.of(context).pop(-1),
                  icon: const Icon(Icons.clear),
                  label: Text(l10n.doublesMatchScoreUnsetLabel),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) {
      return;
    }

    setState(() {
      _clearFeedback();
      if (selected < 0) {
        _side1Score = null;
        _side2Score = null;
        return;
      }

      if (side1) {
        _side1Score = selected;
        _side2Score ??= 0;
      } else {
        _side2Score = selected;
        _side1Score ??= 0;
      }
    });
  }

  DateTime _replaceTime(DateTime? current, {int? hour, int? minute}) {
    final base = current ?? DateTime.now();
    return DateTime(
      base.year,
      base.month,
      base.day,
      hour ?? base.hour,
      minute ?? base.minute,
    );
  }

  void _setCurrentTime({required bool start}) {
    if (_isBusy) {
      return;
    }

    setState(() {
      _clearFeedback();
      if (start) {
        _startedAt = DateTime.now();
      } else {
        _finishedAt = DateTime.now();
      }
    });
  }

  void _setHour({required bool start, required int? hour}) {
    if (_isBusy || hour == null) {
      return;
    }

    setState(() {
      _clearFeedback();
      if (start) {
        _startedAt = _replaceTime(_startedAt, hour: hour);
      } else {
        _finishedAt = _replaceTime(_finishedAt, hour: hour);
      }
    });
  }

  void _setMinute({required bool start, required int? minute}) {
    if (_isBusy || minute == null) {
      return;
    }

    setState(() {
      _clearFeedback();
      if (start) {
        _startedAt = _replaceTime(_startedAt, minute: minute);
      } else {
        _finishedAt = _replaceTime(_finishedAt, minute: minute);
      }
    });
  }

  Future<bool> _save() async {
    if (_isBusy) {
      return false;
    }
    if (!_isDirty) {
      return true;
    }

    final l10n = AppLocalizations.of(context);
    final draft = _draftInput;
    final startedAt = draft.startedAt;
    final finishedAt = draft.finishedAt;
    if (startedAt != null &&
        finishedAt != null &&
        finishedAt.isBefore(startedAt)) {
      setState(() {
        _statusMessage = null;
        _errorMessage = l10n.doublesMatchTimeOrderErrorMessage;
      });
      return false;
    }

    final onSave = widget.onSave ??
        DoublesMatchSaveRegistry.find(_baselineProgress.generatedScheduleId);
    if (onSave == null) {
      setState(() {
        _statusMessage = null;
        _errorMessage = l10n.doublesMatchSaveFailedMessage(
          'save callback is unavailable',
        );
      });
      return false;
    }

    setState(() {
      _isSaving = true;
      _statusMessage = null;
      _errorMessage = null;
    });

    try {
      final saved = await onSave(
        current: _baselineProgress,
        input: draft,
      );
      if (!mounted) {
        return false;
      }

      setState(() {
        _applyProgress(saved.match);
        _isSaving = false;
        _statusMessage = l10n.doublesMatchSavedMessage;
      });
      return true;
    } on ScheduleProgressConflictException {
      if (!mounted) {
        return false;
      }
      setState(() {
        _isSaving = false;
        _errorMessage = l10n.doublesMatchConflictMessage;
      });
      return false;
    } on DoublesMatchIncompleteScoreException {
      if (!mounted) {
        return false;
      }
      setState(() {
        _isSaving = false;
        _errorMessage = l10n.doublesMatchIncompleteScoreMessage;
      });
      return false;
    } on DoublesMatchTimeOrderException {
      if (!mounted) {
        return false;
      }
      setState(() {
        _isSaving = false;
        _errorMessage = l10n.doublesMatchTimeOrderErrorMessage;
      });
      return false;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      setState(() {
        _isSaving = false;
        _errorMessage = l10n.doublesMatchSaveFailedMessage(error.toString());
      });
      return false;
    }
  }

  Future<bool> _loadMatch(
    DoublesMatchSelection match, {
    bool showRefreshedMessage = false,
  }) async {
    if (_isBusy) {
      return false;
    }

    final l10n = AppLocalizations.of(context);
    final onLoadMatch = widget.onLoadMatch;
    if (onLoadMatch == null) {
      setState(() {
        _statusMessage = null;
        _errorMessage = l10n.doublesMatchLoadFailedMessage(
          'load callback is unavailable',
        );
      });
      return false;
    }

    setState(() {
      _isLoadingMatch = true;
      _statusMessage = null;
      _errorMessage = null;
    });

    try {
      final latest = await onLoadMatch(match);
      if (!mounted) {
        return false;
      }

      setState(() {
        _match = match;
        _applyProgress(latest);
        _isLoadingMatch = false;
        if (showRefreshedMessage) {
          _statusMessage = l10n.doublesMatchRefreshedMessage;
        }
      });
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      setState(() {
        _isLoadingMatch = false;
        _errorMessage = l10n.doublesMatchLoadFailedMessage(error.toString());
      });
      return false;
    }
  }

  Future<void> _restoreLatest() async {
    if (_isBusy || widget.onLoadMatch == null) {
      return;
    }

    if (_isDirty) {
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return AlertDialog(
            title: Text(l10n.doublesMatchRestoreLatestConfirmTitle),
            content: Text(l10n.doublesMatchRestoreLatestConfirmBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancelButton),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.doublesMatchRestoreLatestButton),
              ),
            ],
          );
        },
      );
      if (!mounted || confirmed != true) {
        return;
      }
    }

    await _loadMatch(_match, showRefreshedMessage: true);
  }

  Future<void> _move(int offset) async {
    if (_isBusy) {
      return;
    }

    final currentIndex = _currentMatchIndex;
    final targetIndex = currentIndex + offset;
    if (currentIndex < 0 ||
        targetIndex < 0 ||
        targetIndex >= widget.matches.length) {
      return;
    }

    final target = widget.matches[targetIndex];
    if (!_isDirty) {
      await _loadMatch(target);
      return;
    }

    final action = await showDialog<_UnsavedMoveAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.bocciaScoreDiscardChangesTitle),
          content: Text(l10n.bocciaScoreUnsavedChangesMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_UnsavedMoveAction.cancel);
              },
              child: Text(l10n.cancelButton),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_UnsavedMoveAction.discardAndMove);
              },
              child: Text(l10n.doublesMatchDiscardAndMoveButton),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(_UnsavedMoveAction.saveAndMove);
              },
              child: Text(l10n.doublesMatchSaveAndMoveButton),
            ),
          ],
        );
      },
    );

    if (!mounted || action == null || action == _UnsavedMoveAction.cancel) {
      return;
    }

    if (action == _UnsavedMoveAction.saveAndMove) {
      final saved = await _save();
      if (!mounted || !saved) {
        return;
      }
    }

    await _loadMatch(target);
  }

  Future<void> _close() async {
    if (_isBusy) {
      return;
    }
    if (!_isDirty) {
      Navigator.of(context).pop();
      return;
    }

    final action = await showDialog<_UnsavedAction>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final l10n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(l10n.bocciaScoreDiscardChangesTitle),
          content: Text(l10n.bocciaScoreUnsavedChangesMessage),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(_UnsavedAction.cancel);
              },
              child: Text(l10n.cancelButton),
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

    if (!mounted || action == null || action == _UnsavedAction.cancel) {
      return;
    }
    if (action == _UnsavedAction.discardAndClose) {
      Navigator.of(context).pop();
      return;
    }

    final saved = await _save();
    if (mounted && saved) {
      Navigator.of(context).pop();
    }
  }

  String _statusLabel(AppLocalizations l10n, ScheduleMatchStatus status) {
    return switch (status) {
      ScheduleMatchStatus.scheduled => l10n.doublesMatchStatusScheduledLabel,
      ScheduleMatchStatus.inProgress => l10n.doublesMatchStatusInProgressLabel,
      ScheduleMatchStatus.completed => l10n.doublesMatchStatusCompletedLabel,
    };
  }

  Widget _buildStatusSelector(AppLocalizations l10n) {
    return SegmentedButton<ScheduleMatchStatus>(
      showSelectedIcon: false,
      segments: [
        for (final status in ScheduleMatchStatus.values)
          ButtonSegment<ScheduleMatchStatus>(
            value: status,
            label: Text(_statusLabel(l10n, status)),
          ),
      ],
      selected: <ScheduleMatchStatus>{_status},
      onSelectionChanged: _isBusy
          ? null
          : (selected) {
              _selectStatus(selected.single);
            },
    );
  }

  Widget _buildMatchNavigationAndStatus(AppLocalizations l10n) {
    final currentIndex = _currentMatchIndex;
    final hasPrevious = currentIndex > 0;
    final hasNext =
        currentIndex >= 0 && currentIndex < widget.matches.length - 1;
    final matchPosition = 'R ${_match.roundNo} / C ${_match.courtNo}';

    final navigation = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          key: const Key('doubles-match-previous-button'),
          onPressed: !_isBusy && hasPrevious ? () => _move(-1) : null,
          icon: const Icon(Icons.arrow_back),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            matchPosition,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        IconButton.outlined(
          key: const Key('doubles-match-next-button'),
          onPressed: !_isBusy && hasNext ? () => _move(1) : null,
          icon: const Icon(Icons.arrow_forward),
        ),
      ],
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: navigation,
        ),
        const SizedBox(height: 8),
        Center(child: _buildStatusSelector(l10n)),
      ],
    );
  }

  Widget _buildPlayers(List<DoublesMatchParticipantViewModel> players) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < players.length; index += 1) ...[
          if (index > 0) const SizedBox(width: 6),
          SchedulePlayerChip(
            slotNumber: players[index].slotNumber,
            playerId: players[index].playerId,
            displayName: players[index].displayName,
            size: SchedulePlayerChipSize.compact,
          ),
        ],
      ],
    );
  }

  Widget _buildScoreControl({required bool side1}) {
    final score = side1 ? _side1Score : _side2Score;
    final onDecrease =
        _isBusy ? null : () => _adjustScore(side1: side1, delta: -1);
    final onIncrease =
        _isBusy ? null : () => _adjustScore(side1: side1, delta: 1);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          padding: EdgeInsets.zero,
          iconSize: 20,
          onPressed: onDecrease,
          icon: const Icon(Icons.remove),
        ),
        const SizedBox(width: 2),
        SizedBox(
          width: 48,
          height: 48,
          child: OutlinedButton(
            onPressed: _isBusy ? null : () => _pickScore(side1: side1),
            style: OutlinedButton.styleFrom(padding: EdgeInsets.zero),
            child: Text(score?.toString() ?? '－'),
          ),
        ),
        const SizedBox(width: 2),
        IconButton.outlined(
          constraints: const BoxConstraints.tightFor(width: 48, height: 48),
          padding: EdgeInsets.zero,
          iconSize: 20,
          onPressed: onIncrease,
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }

  Widget _buildWideMatchInputs() {
    return Column(
      key: const Key('doubles-match-wide-score-layout'),
      mainAxisSize: MainAxisSize.min,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPlayers(_match.side1Players),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 10),
                child: Text('vs'),
              ),
              _buildPlayers(_match.side2Players),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildScoreControl(side1: true),
            const SizedBox(width: 24),
            _buildScoreControl(side1: false),
          ],
        ),
      ],
    );
  }

  Widget _buildNarrowSideRow({required bool side1}) {
    final players = side1 ? _match.side1Players : _match.side2Players;

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildPlayers(players),
          ),
        ),
        const SizedBox(width: 8),
        _buildScoreControl(side1: side1),
      ],
    );
  }

  Widget _buildNarrowMatchInputs() {
    return Column(
      key: const Key('doubles-match-narrow-score-layout'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNarrowSideRow(side1: true),
        const Divider(height: 16, thickness: 1),
        _buildNarrowSideRow(side1: false),
      ],
    );
  }

  Widget _buildTimeInput({
    required String label,
    required DateTime? value,
    required bool enabled,
    required bool start,
  }) {
    final l10n = AppLocalizations.of(context);
    final canEdit = enabled && !_isBusy;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        enabled: canEdit,
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isDense: true,
              value: value?.hour,
              hint: const Text('－－'),
              onChanged:
                  canEdit ? (hour) => _setHour(start: start, hour: hour) : null,
              items: [
                for (var hour = 0; hour < 24; hour += 1)
                  DropdownMenuItem<int>(
                    value: hour,
                    child: Text(hour.toString().padLeft(2, '0')),
                  ),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(':'),
          ),
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isDense: true,
              value: value?.minute,
              hint: const Text('－－'),
              onChanged: canEdit
                  ? (minute) => _setMinute(start: start, minute: minute)
                  : null,
              items: [
                for (var minute = 0; minute < 60; minute += 1)
                  DropdownMenuItem<int>(
                    value: minute,
                    child: Text(minute.toString().padLeft(2, '0')),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.doublesMatchSetCurrentTimeTooltip,
            onPressed: canEdit ? () => _setCurrentTime(start: start) : null,
            icon: const Icon(Icons.access_time),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInputs({
    required Widget startTimeInput,
    required Widget finishTimeInput,
  }) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: startTimeInput,
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 300),
          child: finishTimeInput,
        ),
      ],
    );
  }

  Widget _buildSaveStatus(AppLocalizations l10n) {
    if (_isBusy) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(l10n.processingButton),
        ],
      );
    }

    final errorMessage = _errorMessage;
    if (errorMessage != null) {
      return Text(
        errorMessage,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      );
    }

    final statusMessage = _statusMessage;
    if (statusMessage != null) {
      return Text(
        statusMessage,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    if (_isDirty) {
      return Text(l10n.bocciaScoreUnsavedChangesMessage);
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final startEnabled = _status != ScheduleMatchStatus.scheduled;
    final finishEnabled = _status == ScheduleMatchStatus.completed;
    final availableContentWidth =
        (MediaQuery.sizeOf(context).width - 72).clamp(0.0, 680.0).toDouble();
    final useWideScoreLayout = availableContentWidth >= 328;

    final startTimeInput = _buildTimeInput(
      label: l10n.doublesMatchStartTimeLabel,
      value: _startedAt,
      enabled: startEnabled,
      start: true,
    );
    final finishTimeInput = _buildTimeInput(
      label: l10n.doublesMatchEndTimeLabel,
      value: _finishedAt,
      enabled: finishEnabled,
      start: false,
    );

    return PopScope<Object?>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_isBusy) {
          _close();
        }
      },
      child: AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
        contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
        title: Text(l10n.doublesMatchEditTitle),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMatchNavigationAndStatus(l10n),
                const SizedBox(height: 20),
                if (useWideScoreLayout)
                  _buildWideMatchInputs()
                else
                  _buildNarrowMatchInputs(),
                const SizedBox(height: 20),
                _buildTimeInputs(
                  startTimeInput: startTimeInput,
                  finishTimeInput: finishTimeInput,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _noteController,
                  enabled: !_isBusy,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.doublesMatchNoteLabel,
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: _buildSaveStatus(l10n),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed:
                _isBusy || widget.onLoadMatch == null ? null : _restoreLatest,
            child: Text(l10n.doublesMatchRestoreLatestButton),
          ),
          TextButton(
            onPressed: _isBusy ? null : _close,
            child: Text(l10n.closeButton),
          ),
          FilledButton(
            onPressed: _isBusy || !_isDirty ? null : _save,
            child: Text(l10n.doublesMatchSaveButton),
          ),
        ],
      ),
    );
  }
}

enum _UnsavedAction {
  cancel,
  discardAndClose,
  saveAndClose,
}

enum _UnsavedMoveAction {
  cancel,
  discardAndMove,
  saveAndMove,
}
