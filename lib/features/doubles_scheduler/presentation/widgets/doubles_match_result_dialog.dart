import 'dart:async';

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
  static const _autoSaveDelay = Duration(milliseconds: 500);

  late DoublesMatchSelection _match;
  late ScheduleMatchProgress _baselineProgress;
  late ScheduleMatchStatus _status;
  late int? _side1Score;
  late int? _side2Score;
  late DateTime? _startedAt;
  late DateTime? _finishedAt;
  late final TextEditingController _noteController;

  Timer? _autoSaveTimer;
  bool _autoSaveRequested = false;
  bool _isSaving = false;
  bool _isLoadingMatch = false;
  bool _suppressNoteListener = false;
  DateTime? _lastSyncedAt;
  String? _errorMessage;

  bool get _isInputBlocked => _isLoadingMatch;
  bool get _isActionBlocked => _isSaving || _isLoadingMatch;

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
    _lastSyncedAt = DateTime.now();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
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
    _scheduleAutoSave();
  }

  void _clearFeedback() {
    _errorMessage = null;
  }

  void _scheduleAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    _autoSaveRequested = false;

    if (!_isDirty || _isLoadingMatch) {
      return;
    }

    _autoSaveTimer = Timer(_autoSaveDelay, _handleAutoSaveTimer);
  }

  void _cancelAutoSave() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
    _autoSaveRequested = false;
  }

  void _handleAutoSaveTimer() {
    _autoSaveTimer = null;
    if (!mounted || !_isDirty || _isLoadingMatch) {
      return;
    }

    if (_isSaving) {
      _autoSaveRequested = true;
      return;
    }

    unawaited(_saveDraft());
  }

  void _scheduleAfterDraftChange() {
    if (!mounted) {
      return;
    }
    _scheduleAutoSave();
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
    if (_isInputBlocked) {
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
    _scheduleAfterDraftChange();
  }

  void _adjustScore({required bool side1, required int delta}) {
    if (_isInputBlocked) {
      return;
    }

    final current = side1 ? _side1Score : _side2Score;

    setState(() {
      _clearFeedback();
      if (_side1Score == null || _side2Score == null) {
        final next = delta > 0 ? 1 : 0;
        _side1Score = side1 ? next : 0;
        _side2Score = side1 ? 0 : next;
      } else {
        final next = ((current ?? 0) + delta).clamp(0, 9).toInt();
        if (side1) {
          _side1Score = next;
        } else {
          _side2Score = next;
        }
      }
    });
    _scheduleAfterDraftChange();
  }

  Future<void> _pickScore({required bool side1}) async {
    if (_isInputBlocked) {
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
      } else if (side1) {
        _side1Score = selected;
        _side2Score ??= 0;
      } else {
        _side2Score = selected;
        _side1Score ??= 0;
      }
    });
    _scheduleAfterDraftChange();
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
    if (_isInputBlocked) {
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
    _scheduleAfterDraftChange();
  }

  void _setHour({required bool start, required int? hour}) {
    if (_isInputBlocked || hour == null) {
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
    _scheduleAfterDraftChange();
  }

  void _setMinute({required bool start, required int? minute}) {
    if (_isInputBlocked || minute == null) {
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
    _scheduleAfterDraftChange();
  }

  Future<bool> _saveDraft({
    bool allowAutoFollowUp = true,
  }) async {
    if (_isLoadingMatch || _isSaving) {
      return false;
    }
    if (!_isDirty) {
      _cancelAutoSave();
      return true;
    }

    final l10n = AppLocalizations.of(context);
    final submittedBaseline = _baselineProgress;
    final submittedDraft = _draftInput;
    final startedAt = submittedDraft.startedAt;
    final finishedAt = submittedDraft.finishedAt;
    if (startedAt != null &&
        finishedAt != null &&
        finishedAt.isBefore(startedAt)) {
      _cancelAutoSave();
      setState(() {
        _errorMessage = l10n.doublesMatchTimeOrderErrorMessage;
      });
      return false;
    }

    final onSave = widget.onSave ??
        DoublesMatchSaveRegistry.find(
          submittedBaseline.generatedScheduleId,
        );
    if (onSave == null) {
      _cancelAutoSave();
      setState(() {
        _errorMessage = l10n.doublesMatchSaveFailedMessage(
          'save callback is unavailable',
        );
      });
      return false;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final saved = await onSave(
        current: submittedBaseline,
        input: submittedDraft,
      );
      if (!mounted) {
        return false;
      }

      final hasNewerDraft = !doublesMatchProgressInputsEqual(
        _draftInput,
        submittedDraft,
      );

      setState(() {
        if (hasNewerDraft) {
          _baselineProgress = saved.match;
        } else {
          _applyProgress(saved.match);
        }
        _isSaving = false;
        _lastSyncedAt = DateTime.now();
        _errorMessage = null;
      });

      if (!_isDirty) {
        _cancelAutoSave();
      } else if (allowAutoFollowUp && _autoSaveRequested) {
        _cancelAutoSave();
        unawaited(_saveDraft());
      }

      return true;
    } on ScheduleProgressConflictException {
      if (!mounted) {
        return false;
      }
      _cancelAutoSave();
      setState(() {
        _isSaving = false;
        _errorMessage = l10n.doublesMatchConflictMessage;
      });
      return false;
    } on DoublesMatchIncompleteScoreException {
      if (!mounted) {
        return false;
      }
      _cancelAutoSave();
      setState(() {
        _isSaving = false;
        _errorMessage = l10n.doublesMatchIncompleteScoreMessage;
      });
      return false;
    } on DoublesMatchTimeOrderException {
      if (!mounted) {
        return false;
      }
      _cancelAutoSave();
      setState(() {
        _isSaving = false;
        _errorMessage = l10n.doublesMatchTimeOrderErrorMessage;
      });
      return false;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      _cancelAutoSave();
      setState(() {
        _isSaving = false;
        _errorMessage = l10n.doublesMatchSaveFailedMessage(error.toString());
      });
      return false;
    }
  }

  Future<bool> _flushPendingSave() async {
    _cancelAutoSave();

    while (mounted && _isDirty) {
      final saved = await _saveDraft(allowAutoFollowUp: false);
      if (!mounted || !saved) {
        return false;
      }

      // Input can continue while a save is in flight. Flush any newer draft
      // before allowing an action that depends on the save result.
      _cancelAutoSave();
    }

    return mounted;
  }

  Future<bool> _loadMatch(
    DoublesMatchSelection match,
  ) async {
    if (_isActionBlocked) {
      return false;
    }

    final l10n = AppLocalizations.of(context);
    final onLoadMatch = widget.onLoadMatch;
    if (onLoadMatch == null) {
      setState(() {
        _errorMessage = l10n.doublesMatchLoadFailedMessage(
          'load callback is unavailable',
        );
      });
      return false;
    }

    _cancelAutoSave();
    setState(() {
      _isLoadingMatch = true;
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
        _lastSyncedAt = DateTime.now();
        _errorMessage = null;
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

  Future<void> _refreshLatest() async {
    if (_isActionBlocked || widget.onLoadMatch == null) {
      return;
    }

    if (_isDirty) {
      _cancelAutoSave();
      final confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          final l10n = AppLocalizations.of(context);
          return AlertDialog(
            title: Text(l10n.doublesMatchRefreshLatestConfirmTitle),
            content: Text(l10n.doublesMatchRefreshLatestConfirmBody),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(l10n.cancelButton),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(l10n.doublesMatchRefreshLatestButton),
              ),
            ],
          );
        },
      );
      if (!mounted) {
        return;
      }
      if (confirmed != true) {
        _scheduleAutoSave();
        return;
      }
    }

    await _loadMatch(_match);
  }

  Future<void> _move(int offset) async {
    if (_isActionBlocked) {
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
    if (_isDirty) {
      final saved = await _flushPendingSave();
      if (!mounted || !saved) {
        return;
      }
    }

    await _loadMatch(target);
  }

  Future<void> _close() async {
    if (_isActionBlocked) {
      return;
    }

    if (_isDirty) {
      final saved = await _flushPendingSave();
      if (!mounted || !saved) {
        return;
      }
    }

    if (mounted) {
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
      onSelectionChanged: _isInputBlocked
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

    final matchPosition = l10n.doublesMatchPositionLabel(
      _match.roundNo,
      _match.courtNo,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.outlined(
                key: const Key('doubles-match-previous-button'),
                onPressed:
                    !_isActionBlocked && hasPrevious ? () => _move(-1) : null,
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      matchPosition,
                      maxLines: 1,
                      softWrap: false,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.outlined(
                key: const Key('doubles-match-next-button'),
                onPressed: !_isActionBlocked && hasNext ? () => _move(1) : null,
                icon: const Icon(Icons.arrow_forward),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: _buildStatusSelector(l10n),
        ),
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
        _isInputBlocked ? null : () => _adjustScore(side1: side1, delta: -1);
    final onIncrease =
        _isInputBlocked ? null : () => _adjustScore(side1: side1, delta: 1);

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
            onPressed: _isInputBlocked ? null : () => _pickScore(side1: side1),
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
    final canEdit = enabled && !_isInputBlocked;

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

  String _formatSyncTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    final second = value.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }

  Widget _buildSaveStatus(AppLocalizations l10n) {
    if (_isSaving) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Text(l10n.doublesMatchSavingLabel),
        ],
      );
    }

    if (_isLoadingMatch) {
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

    final lastSyncedAt = _lastSyncedAt;
    if (lastSyncedAt != null) {
      return Text(
        l10n.doublesMatchSyncedAtLabel(_formatSyncTime(lastSyncedAt)),
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildDialogActions(AppLocalizations l10n) {
    final refreshButton = TextButton(
      onPressed: _isActionBlocked || widget.onLoadMatch == null
          ? null
          : _refreshLatest,
      child: Text(l10n.doublesMatchRefreshLatestButton),
    );
    final closeButton = TextButton(
      onPressed: _isActionBlocked ? null : _close,
      child: Text(l10n.closeButton),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _buildSaveStatus(l10n),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  refreshButton,
                  closeButton,
                ],
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildSaveStatus(l10n),
              ),
            ),
            refreshButton,
            closeButton,
          ],
        );
      },
    );
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
        if (!didPop && !_isActionBlocked) {
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
                  enabled: !_isInputBlocked,
                  minLines: 2,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: l10n.doublesMatchNoteLabel,
                    alignLabelWithHint: true,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: _buildDialogActions(l10n),
          ),
        ],
      ),
    );
  }
}
