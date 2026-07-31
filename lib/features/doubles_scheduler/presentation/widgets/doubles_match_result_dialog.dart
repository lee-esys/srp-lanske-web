import 'package:flutter/material.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/doubles_match_progress_service.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/models/doubles_match_editor_models.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';
import 'package:srp_lanske/l10n/l10n.dart';
import 'package:srp_lanske/shared/presentation/app_message_type.dart';
import 'package:srp_lanske/shared/presentation/app_snack_bar.dart';

import 'schedule_player_chip.dart';

class DoublesMatchResultDialog extends StatefulWidget {
  const DoublesMatchResultDialog({
    required this.match,
    required this.initialProgress,
    super.key,
  });

  final DoublesMatchSelection match;
  final ScheduleMatchProgress initialProgress;

  @override
  State<DoublesMatchResultDialog> createState() =>
      _DoublesMatchResultDialogState();
}

class _DoublesMatchResultDialogState extends State<DoublesMatchResultDialog> {
  late ScheduleMatchStatus _status;
  late int? _side1Score;
  late int? _side2Score;
  late DateTime? _startedAt;
  late DateTime? _finishedAt;
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    final progress = widget.initialProgress;
    final scores =
        progress.result?.type == ScheduleMatchResultSummary.simpleScoreType &&
                (progress.result?.sideScores.length ?? 0) >= 2
            ? progress.result!.sideScores
            : const <int>[];

    _status = progress.status;
    _side1Score = scores.length >= 2 && scores[0] <= 9 ? scores[0] : null;
    _side2Score = scores.length >= 2 && scores[1] <= 9 ? scores[1] : null;
    _startedAt = progress.startedAt;
    _finishedAt = progress.finishedAt;
    _noteController = TextEditingController(text: progress.note);
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _selectStatus(ScheduleMatchStatus status) {
    final previousStatus = _status;
    final now = DateTime.now();

    setState(() {
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
    final current = side1 ? _side1Score : _side2Score;

    setState(() {
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
    setState(() {
      if (start) {
        _startedAt = DateTime.now();
      } else {
        _finishedAt = DateTime.now();
      }
    });
  }

  void _setHour({required bool start, required int? hour}) {
    if (hour == null) {
      return;
    }

    setState(() {
      if (start) {
        _startedAt = _replaceTime(_startedAt, hour: hour);
      } else {
        _finishedAt = _replaceTime(_finishedAt, hour: hour);
      }
    });
  }

  void _setMinute({required bool start, required int? minute}) {
    if (minute == null) {
      return;
    }

    setState(() {
      if (start) {
        _startedAt = _replaceTime(_startedAt, minute: minute);
      } else {
        _finishedAt = _replaceTime(_finishedAt, minute: minute);
      }
    });
  }

  void _save() {
    final l10n = AppLocalizations.of(context);
    final startedAt = _startedAt;
    final finishedAt = _finishedAt;
    if (startedAt != null &&
        finishedAt != null &&
        finishedAt.isBefore(startedAt)) {
      AppSnackBar.show(
        context,
        message: l10n.doublesMatchTimeOrderErrorMessage,
        type: AppMessageType.warning,
      );
      return;
    }

    Navigator.of(context).pop(
      DoublesMatchProgressInput(
        status: _status,
        side1Score: _side1Score,
        side2Score: _side2Score,
        note: _noteController.text,
        startedAt: _startedAt,
        finishedAt: _finishedAt,
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, ScheduleMatchStatus status) {
    return switch (status) {
      ScheduleMatchStatus.scheduled => l10n.doublesMatchStatusScheduledLabel,
      ScheduleMatchStatus.inProgress => l10n.doublesMatchStatusInProgressLabel,
      ScheduleMatchStatus.completed => l10n.doublesMatchStatusCompletedLabel,
    };
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

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton.outlined(
          onPressed: () => _adjustScore(side1: side1, delta: -1),
          icon: const Icon(Icons.remove),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: 54,
          child: OutlinedButton(
            onPressed: () => _pickScore(side1: side1),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(score?.toString() ?? '－'),
          ),
        ),
        const SizedBox(width: 4),
        IconButton.outlined(
          onPressed: () => _adjustScore(side1: side1, delta: 1),
          icon: const Icon(Icons.add),
        ),
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

    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        enabled: enabled,
        contentPadding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value?.hour,
              hint: const Text('－－'),
              onChanged:
                  enabled ? (hour) => _setHour(start: start, hour: hour) : null,
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
              value: value?.minute,
              hint: const Text('－－'),
              onChanged: enabled
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
            onPressed: enabled ? () => _setCurrentTime(start: start) : null,
            icon: const Icon(Icons.access_time),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final startEnabled = _status != ScheduleMatchStatus.scheduled;
    final finishEnabled = _status == ScheduleMatchStatus.completed;
    final useHorizontalTimeLayout = MediaQuery.sizeOf(context).width >= 720;

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

    return AlertDialog(
      title: Text(l10n.doublesMatchEditTitle),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: SegmentedButton<ScheduleMatchStatus>(
                  showSelectedIcon: false,
                  segments: [
                    for (final status in ScheduleMatchStatus.values)
                      ButtonSegment<ScheduleMatchStatus>(
                        value: status,
                        label: Text(_statusLabel(l10n, status)),
                      ),
                  ],
                  selected: <ScheduleMatchStatus>{_status},
                  onSelectionChanged: (selected) {
                    _selectStatus(selected.single);
                  },
                ),
              ),
              const SizedBox(height: 20),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildPlayers(widget.match.side1Players),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('vs'),
                    ),
                    _buildPlayers(widget.match.side2Players),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildScoreControl(side1: true),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('vs'),
                    ),
                    _buildScoreControl(side1: false),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (useHorizontalTimeLayout)
                Row(
                  children: [
                    Expanded(child: startTimeInput),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text('～'),
                    ),
                    Expanded(child: finishTimeInput),
                  ],
                )
              else
                Column(
                  children: [
                    startTimeInput,
                    const SizedBox(height: 12),
                    finishTimeInput,
                  ],
                ),
              const SizedBox(height: 20),
              TextField(
                controller: _noteController,
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
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancelButton),
        ),
        FilledButton(
          onPressed: _save,
          child: Text(l10n.doublesMatchSaveButton),
        ),
      ],
    );
  }
}
