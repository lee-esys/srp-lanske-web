import 'package:flutter/material.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/doubles_progress_ui_store.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/doubles_progress_visuals.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/models/doubles_match_editor_models.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';
import 'package:srp_lanske/l10n/l10n.dart';
import 'package:srp_lanske/shared/presentation/app_message_type.dart';
import 'package:srp_lanske/shared/presentation/app_snack_bar.dart';
import 'package:srp_lanske/shared/repositories/app_repositories.dart';
import 'package:srp_lanske/shared/utils/browser_url.dart';

import 'doubles_match_card.dart';
import 'doubles_match_result_dialog.dart';
import 'schedule_player_chip.dart';

class ScheduleRoundsView extends StatefulWidget {
  const ScheduleRoundsView({
    super.key,
    required this.scheduleResponse,
    required this.playerNameById,
    required this.courtCount,
    this.selectedPlayerId,
    this.onPlayerSelected,
    required this.courtLabelByNumber,
  });

  final Map<String, dynamic>? scheduleResponse;
  final Map<String, String> playerNameById;
  final int courtCount;
  final String? selectedPlayerId;
  final ValueChanged<String>? onPlayerSelected;
  final Map<int, String> courtLabelByNumber;

  @override
  State<ScheduleRoundsView> createState() => _ScheduleRoundsViewState();
}

class _ScheduleRoundsViewState extends State<ScheduleRoundsView> {
  static const _courtAreaSpacing = 24.0;
  static const _courtMatchCardWidth = 340.0;

  final Set<String> _expandedRestRoundNumbers = {};

  Map<String, ScheduleMatchProgress> _progressByKey = const {};
  bool _canEditMatches = false;
  bool _isLoadingProgress = false;
  bool _isOpeningMatch = false;
  int _progressRequestSequence = 0;

  @override
  void initState() {
    super.initState();
    DoublesProgressUiStore.clearOverride();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadProgress();
      }
    });
  }

  @override
  void didUpdateWidget(covariant ScheduleRoundsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    DoublesProgressUiStore.clearOverride();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadProgress();
      }
    });
  }

  String? get _publicId {
    final value = Uri.base.queryParameters['sid']?.trim().toUpperCase();
    return value == null || value.isEmpty ? null : value;
  }

  String? get _generatedScheduleId {
    final value = widget.scheduleResponse?['generated_schedule_id']?.toString();
    return value == null || value.isEmpty ? null : value;
  }

  bool get _hasAdoptedSchedule {
    return widget.scheduleResponse?['adopted'] == true || _canEditMatches;
  }

  int get _totalMatchCount {
    final scheduleResponse = widget.scheduleResponse;
    if (scheduleResponse == null) {
      return 0;
    }

    return _asObjectList(scheduleResponse['rounds']).fold<int>(0, (
      total,
      round,
    ) {
      return total + _asObjectList(round['courts']).length;
    });
  }

  ScheduleProgressScope? get _progressScope {
    final publicId = _publicId;
    final generatedScheduleId = _generatedScheduleId;
    if (publicId == null || generatedScheduleId == null) {
      return null;
    }

    return ScheduleProgressScope(
      scheduleType: ScheduleProgressScheduleType.doubles,
      shareId: publicId,
      generatedScheduleId: generatedScheduleId,
    );
  }

  Future<void> _loadProgress({bool showMessage = false}) async {
    final requestSequence = ++_progressRequestSequence;
    final scope = _progressScope;
    if (scope == null || _totalMatchCount <= 0) {
      if (mounted && requestSequence == _progressRequestSequence) {
        setState(() {
          _progressByKey = const {};
          _canEditMatches = false;
          _isLoadingProgress = false;
        });
      }
      DoublesProgressUiStore.setSummary(null);
      return;
    }

    final identity = scope.storageKey;
    setState(() {
      _isLoadingProgress = true;
    });

    try {
      final aggregate = await appEventRepository.findByPublicId(scope.shareId);
      final summary = await appScheduleProgressRepository.findSummary(scope);
      final matches = summary == null
          ? const <ScheduleMatchProgress>[]
          : await appScheduleProgressRepository.listMatches(scope);
      if (!mounted ||
          requestSequence != _progressRequestSequence ||
          _progressScope?.storageKey != identity) {
        return;
      }

      setState(() {
        _progressByKey = Map<String, ScheduleMatchProgress>.unmodifiable({
          for (final match in matches) match.key.value: match,
        });
        _canEditMatches = aggregate?.event.hasAdoptedSchedule ?? false;
        _isLoadingProgress = false;
      });
      DoublesProgressUiStore.setSummary(summary);

      if (showMessage) {
        AppSnackBar.show(
          context,
          message: AppLocalizations.of(context).doublesMatchRefreshedMessage,
          type: AppMessageType.success,
        );
      }
    } catch (error) {
      if (!mounted || requestSequence != _progressRequestSequence) {
        return;
      }

      setState(() {
        _canEditMatches = false;
        _isLoadingProgress = false;
      });
      if (showMessage) {
        AppSnackBar.show(
          context,
          message: AppLocalizations.of(context)
              .reloadScheduleFailedMessage(error.toString()),
          type: AppMessageType.error,
        );
      }
    }
  }

  Future<ScheduleMatchProgress> _loadMatchForDialog(
    ScheduleProgressScope sessionScope,
    DoublesMatchSelection selection,
  ) async {
    final currentScope = _progressScope;
    if (currentScope == null ||
        currentScope.storageKey != sessionScope.storageKey) {
      throw StateError('displayed doubles schedule changed while editing');
    }

    return appScheduleProgressRepository.findMatch(
      scope: sessionScope,
      roundNo: selection.roundNo,
      courtNo: selection.courtNo,
      matchNo: selection.matchNo,
    );
  }

  Future<void> _openMatch(DoublesMatchSelection selection) async {
    if (!_canEditMatches || _isOpeningMatch || _isLoadingProgress) {
      return;
    }

    final scope = _progressScope;
    final publicId = _publicId;
    final generatedScheduleId = _generatedScheduleId;
    final scheduleResponse = widget.scheduleResponse;
    final l10n = AppLocalizations.of(context);
    if (scope == null ||
        publicId == null ||
        generatedScheduleId == null ||
        scheduleResponse == null ||
        _totalMatchCount <= 0) {
      AppSnackBar.show(
        context,
        message: l10n.doublesMatchUnavailableMessage,
        type: AppMessageType.warning,
      );
      return;
    }

    setState(() {
      _isOpeningMatch = true;
    });

    try {
      final aggregate = await appEventRepository.findByPublicId(publicId);
      if (!mounted) {
        return;
      }

      if (aggregate == null ||
          !aggregate.event.hasAdoptedSchedule ||
          aggregate.event.displayGeneratedScheduleId != generatedScheduleId) {
        AppSnackBar.show(
          context,
          message: l10n.doublesMatchScheduleChangedMessage,
          type: AppMessageType.info,
          actionLabel: l10n.refreshLatestButton,
          onAction: reloadPage,
        );
        return;
      }

      final latest = await _loadMatchForDialog(scope, selection);
      if (!mounted) {
        return;
      }

      final slotToPlayerId = _buildSlotToPlayerId(scheduleResponse);
      final matches = _buildMatchSelections(
        scheduleResponse,
        slotToPlayerId,
      );

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return DoublesMatchResultDialog(
            match: selection,
            initialProgress: latest,
            matches: matches,
            onLoadMatch: (target) => _loadMatchForDialog(scope, target),
          );
        },
      );
      if (!mounted) {
        return;
      }

      await _loadProgress();
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.show(
        context,
        message: l10n.reloadScheduleFailedMessage(error.toString()),
        type: AppMessageType.error,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningMatch = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheduleResponse = widget.scheduleResponse;
    if (scheduleResponse == null) {
      return Text(l10n.scheduleNotLoadedMessage);
    }

    final rounds = _asObjectList(scheduleResponse['rounds']);
    final slotToPlayerId = _buildSlotToPlayerId(scheduleResponse);

    if (rounds.isEmpty) {
      return Text(l10n.scheduleDataEmptyMessage);
    }

    final inputHint = _hasAdoptedSchedule
        ? l10n.doublesMatchInputHint
        : l10n.doublesMatchInputAvailableAfterAdoptionHint;

    return Column(
      children: [
        DoublesMatchInputHint(message: inputHint),
        ...rounds.map((round) {
          return _buildRoundCard(round, slotToPlayerId);
        }),
      ],
    );
  }

  Widget _buildRoundCard(
    Map<String, dynamic> round,
    Map<int, String> slotToPlayerId,
  ) {
    final roundNumber = round['round_number']?.toString() ?? '-';
    final roundNumberValue = int.tryParse(roundNumber);
    final isEvenRound = roundNumberValue != null && roundNumberValue.isEven;
    final restSlotNumbers = _asIntList(round['rest_slot_numbers']);
    final hasSelectedRestPlayer = _hasSelectedRestPlayer(
      restSlotNumbers,
      slotToPlayerId,
    );
    final courts = _asObjectList(round['courts']);
    final courtNumbers = courts
        .map((court) => _tryReadInt(court['court_number']))
        .whereType<int>();
    final isRoundCompleted = isDoublesRoundCompleted(
      roundNo: roundNumberValue,
      courtNumbers: courtNumbers,
      progressByKey: _progressByKey,
    );
    final roundCardColor = resolveDoublesRoundCardColor(
      Theme.of(context).colorScheme,
      isCompleted: isRoundCompleted,
      isEvenRound: isEvenRound,
    );
    final isRestExpanded = _expandedRestRoundNumbers.contains(roundNumber);
    final restToggle = _RestToggleButton(
      key: ValueKey('round-rest-toggle-$roundNumber'),
      restCount: restSlotNumbers.length,
      isExpanded: isRestExpanded,
      isHighlighted: hasSelectedRestPlayer,
      onTap: () {
        setState(() {
          if (isRestExpanded) {
            _expandedRestRoundNumbers.remove(roundNumber);
          } else {
            _expandedRestRoundNumbers.add(roundNumber);
          }
        });
      },
    );

    return Card(
      key: ValueKey('round-card-$roundNumber'),
      color: roundCardColor,
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCourtArea(
              roundNo: roundNumberValue,
              roundLabel: roundNumber,
              courts: courts,
              slotToPlayerId: slotToPlayerId,
              roundAction: restToggle,
            ),
            if (isRestExpanded) ...[
              const Divider(),
              _buildRestPlayersRow(
                restSlotNumbers: restSlotNumbers,
                slotToPlayerId: slotToPlayerId,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCourtArea({
    required int? roundNo,
    required String roundLabel,
    required List<Map<String, dynamic>> courts,
    required Map<int, String> slotToPlayerId,
    required Widget roundAction,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final courtItemWidth =
            _courtMatchCardWidth.clamp(0.0, maxWidth).toDouble();
        final canUseTwoColumns = courts.length >= 2 &&
            maxWidth >= (_courtMatchCardWidth * 2 + _courtAreaSpacing);

        if (courts.length == 1) {
          return Align(
            alignment: Alignment.center,
            child: _buildCourtMatchCard(
              roundNo: roundNo,
              roundLabel: roundLabel,
              court: courts.first,
              slotToPlayerId: slotToPlayerId,
              cardWidth: courtItemWidth,
              headerTrailing: roundAction,
            ),
          );
        }

        if (courts.length == 2 && canUseTwoColumns) {
          final groupWidth = _courtMatchCardWidth * 2 + _courtAreaSpacing;

          return Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: groupWidth,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildCourtMatchCard(
                    roundNo: roundNo,
                    roundLabel: roundLabel,
                    court: courts[0],
                    slotToPlayerId: slotToPlayerId,
                    cardWidth: _courtMatchCardWidth,
                    headerTrailing: roundAction,
                  ),
                  const SizedBox(width: _courtAreaSpacing),
                  _buildCourtMatchCard(
                    roundNo: roundNo,
                    roundLabel: roundLabel,
                    court: courts[1],
                    slotToPlayerId: slotToPlayerId,
                    cardWidth: _courtMatchCardWidth,
                  ),
                ],
              ),
            ),
          );
        }

        if (courts.length == 2) {
          return Column(
            children: courts.asMap().entries.map((entry) {
              return Padding(
                padding: EdgeInsets.only(
                  bottom: entry.key == courts.length - 1 ? 0 : 8,
                ),
                child: Align(
                  alignment: Alignment.center,
                  child: _buildCourtMatchCard(
                    roundNo: roundNo,
                    roundLabel: roundLabel,
                    court: entry.value,
                    slotToPlayerId: slotToPlayerId,
                    cardWidth: courtItemWidth,
                    headerTrailing: entry.key == 0 ? roundAction : null,
                  ),
                ),
              );
            }).toList(growable: false),
          );
        }

        final itemWidth =
            canUseTwoColumns ? _courtMatchCardWidth : courtItemWidth;

        return Wrap(
          alignment: WrapAlignment.start,
          spacing: _courtAreaSpacing,
          runSpacing: 8,
          children: courts.asMap().entries.map((entry) {
            return _buildCourtMatchCard(
              roundNo: roundNo,
              roundLabel: roundLabel,
              court: entry.value,
              slotToPlayerId: slotToPlayerId,
              cardWidth: itemWidth,
              headerTrailing: entry.key == 0 ? roundAction : null,
            );
          }).toList(growable: false),
        );
      },
    );
  }

  Widget _buildCourtMatchCard({
    required int? roundNo,
    required String roundLabel,
    required Map<String, dynamic> court,
    required Map<int, String> slotToPlayerId,
    required double cardWidth,
    Widget? headerTrailing,
  }) {
    final l10n = AppLocalizations.of(context);
    final courtNumberText = court['court_number']?.toString() ?? '-';
    final courtNumber = int.tryParse(courtNumberText);
    final defaultCourtLabel = courtNumber?.toString() ?? courtNumberText;
    final configuredCourtLabel =
        courtNumber == null ? null : widget.courtLabelByNumber[courtNumber];

    final courtLabel =
        configuredCourtLabel == null || configuredCourtLabel.trim().isEmpty
            ? defaultCourtLabel
            : configuredCourtLabel.trim();

    final side1Slots = _asIntList(court['team1_player_slots']);
    final side2Slots = _asIntList(court['team2_player_slots']);
    final matchNo = _tryReadInt(court['match_number'] ?? court['match_no']);

    final progress = roundNo == null || courtNumber == null
        ? null
        : _progressByKey[ScheduleMatchKey(
            roundNo: roundNo,
            courtNo: courtNumber,
          ).value];
    final status = progress?.status ?? ScheduleMatchStatus.scheduled;
    final visualStyle = resolveDoublesMatchVisualStyle(
      Theme.of(context).colorScheme,
      status,
    );

    final selection = roundNo == null || courtNumber == null
        ? null
        : DoublesMatchSelection(
            roundNo: roundNo,
            courtNo: courtNumber,
            matchNo: matchNo,
            side1Players: _buildParticipantViewModels(
              side1Slots,
              slotToPlayerId,
            ),
            side2Players: _buildParticipantViewModels(
              side2Slots,
              slotToPlayerId,
            ),
          );

    return SizedBox(
      width: cardWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: !_canEditMatches || selection == null
              ? null
              : () => _openMatch(selection),
          child: Container(
            key: ValueKey(
              'match-card-${roundNo ?? 'unknown'}-${courtNumber ?? 'unknown'}',
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: visualStyle.cardBackgroundColor,
              border: Border.all(color: visualStyle.cardBorderColor),
              borderRadius: BorderRadius.circular(12),
            ),
            child: DoublesMatchCardContent(
              hasAdoptedSchedule: _hasAdoptedSchedule,
              matchPositionLabel: 'R $roundLabel / C $courtLabel',
              headerTrailing: headerTrailing,
              side1: _buildTeamGroup(side1Slots, slotToPlayerId),
              side2: _buildTeamGroup(side2Slots, slotToPlayerId),
              progress: progress,
              status: status,
              visualStyle: visualStyle,
              statusLabel: _statusLabel(l10n, status),
              winnerLabel: l10n.doublesMatchWinnerLabel,
              loserLabel: l10n.doublesMatchLoserLabel,
              drawLabel: l10n.doublesMatchDrawLabel,
            ),
          ),
        ),
      ),
    );
  }

  List<DoublesMatchSelection> _buildMatchSelections(
    Map<String, dynamic> scheduleResponse,
    Map<int, String> slotToPlayerId,
  ) {
    final matches = <DoublesMatchSelection>[];

    for (final round in _asObjectList(scheduleResponse['rounds'])) {
      final roundNo = _tryReadInt(round['round_number']);
      if (roundNo == null) {
        continue;
      }

      for (final court in _asObjectList(round['courts'])) {
        final courtNo = _tryReadInt(court['court_number']);
        if (courtNo == null) {
          continue;
        }

        matches.add(
          DoublesMatchSelection(
            roundNo: roundNo,
            courtNo: courtNo,
            matchNo: _tryReadInt(court['match_number'] ?? court['match_no']),
            side1Players: _buildParticipantViewModels(
              _asIntList(court['team1_player_slots']),
              slotToPlayerId,
            ),
            side2Players: _buildParticipantViewModels(
              _asIntList(court['team2_player_slots']),
              slotToPlayerId,
            ),
          ),
        );
      }
    }

    return List<DoublesMatchSelection>.unmodifiable(matches);
  }

  String _statusLabel(AppLocalizations l10n, ScheduleMatchStatus status) {
    return switch (status) {
      ScheduleMatchStatus.scheduled => l10n.doublesMatchStatusScheduledLabel,
      ScheduleMatchStatus.inProgress => l10n.doublesMatchStatusInProgressLabel,
      ScheduleMatchStatus.completed => l10n.doublesMatchStatusCompletedLabel,
    };
  }

  Widget _buildRestPlayersRow({
    required List<int> restSlotNumbers,
    required Map<int, String> slotToPlayerId,
  }) {
    final l10n = AppLocalizations.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${l10n.restLabel}:'),
            const SizedBox(width: 6),
            for (final slotNumber in restSlotNumbers) ...[
              _buildPlayerChip(
                slotNumber: slotNumber,
                slotToPlayerId: slotToPlayerId,
                size: SchedulePlayerChipSize.compact,
                highlightEnabled: false,
              ),
              const SizedBox(width: 6),
            ],
          ],
        ),
      ),
    );
  }

  List<DoublesMatchParticipantViewModel> _buildParticipantViewModels(
    List<int> slotNumbers,
    Map<int, String> slotToPlayerId,
  ) {
    return slotNumbers.map((slotNumber) {
      final playerId = slotToPlayerId[slotNumber];
      return DoublesMatchParticipantViewModel(
        slotNumber: slotNumber,
        playerId: playerId,
        displayName: playerId == null
            ? 'slot:$slotNumber'
            : widget.playerNameById[playerId] ?? playerId,
      );
    }).toList(growable: false);
  }

  List<Widget> _buildTeamChips(
    List<int> slotNumbers,
    Map<int, String> slotToPlayerId,
  ) {
    if (slotNumbers.isEmpty) {
      return const [Text('-')];
    }

    return slotNumbers.map((slotNumber) {
      return _buildPlayerChip(
        slotNumber: slotNumber,
        slotToPlayerId: slotToPlayerId,
      );
    }).toList(growable: false);
  }

  Widget _buildTeamGroup(
    List<int> slotNumbers,
    Map<int, String> slotToPlayerId,
  ) {
    if (slotNumbers.isEmpty) {
      return const Text('-');
    }

    final chips = _buildTeamChips(slotNumbers, slotToPlayerId);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < chips.length; index += 1) ...[
          if (index > 0) const SizedBox(width: 6),
          chips[index],
        ],
      ],
    );
  }

  Widget _buildPlayerChip({
    required int slotNumber,
    required Map<int, String> slotToPlayerId,
    SchedulePlayerChipSize size = SchedulePlayerChipSize.normal,
    bool highlightEnabled = true,
  }) {
    final playerId = slotToPlayerId[slotNumber];
    final displayName = playerId == null
        ? 'slot:$slotNumber'
        : widget.playerNameById[playerId] ?? playerId;

    return SchedulePlayerChip(
      slotNumber: slotNumber,
      playerId: playerId,
      displayName: displayName,
      size: size,
      isHighlighted: highlightEnabled && widget.selectedPlayerId == playerId,
      onTap: widget.onPlayerSelected,
    );
  }

  bool _hasSelectedRestPlayer(
    List<int> restSlotNumbers,
    Map<int, String> slotToPlayerId,
  ) {
    final selectedPlayerId = widget.selectedPlayerId;
    if (selectedPlayerId == null) {
      return false;
    }

    return restSlotNumbers.any((slotNumber) {
      return slotToPlayerId[slotNumber] == selectedPlayerId;
    });
  }

  List<Map<String, dynamic>> _asObjectList(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value.whereType<Map>().map((item) {
      return item.map(
        (key, value) => MapEntry(key.toString(), value),
      );
    }).toList(growable: false);
  }

  List<int> _asIntList(Object? value) {
    if (value is! List) {
      return const [];
    }

    return value.map(_tryReadInt).whereType<int>().toList(growable: false);
  }

  int? _tryReadInt(Object? value) {
    if (value is int) {
      return value;
    }
    return value == null ? null : int.tryParse(value.toString());
  }

  Map<int, String> _buildSlotToPlayerId(Map<String, dynamic> scheduleResponse) {
    final assignment = _asObjectList(scheduleResponse['assignment']);
    final slotToPlayerId = <int, String>{};

    for (final row in assignment) {
      final slotNumber = _tryReadInt(row['slot_number']);
      final playerId = row['player_id']?.toString();
      if (slotNumber == null || playerId == null) {
        continue;
      }

      slotToPlayerId[slotNumber] = playerId;
    }

    return slotToPlayerId;
  }
}

class _RestToggleButton extends StatelessWidget {
  const _RestToggleButton({
    super.key,
    required this.restCount,
    required this.isExpanded,
    required this.onTap,
    this.isHighlighted = false,
  });

  final int restCount;
  final bool isExpanded;
  final VoidCallback onTap;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    final backgroundColor =
        isHighlighted ? colorScheme.tertiaryContainer : Colors.transparent;
    final borderColor =
        isHighlighted ? colorScheme.tertiary : colorScheme.outlineVariant;
    final textColor = isHighlighted ? colorScheme.onTertiaryContainer : null;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 5, 4, 5),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: isHighlighted ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${l10n.restLabel}：${l10n.restCountLabel(restCount)}',
              style: TextStyle(
                fontSize: 11,
                height: 1,
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.normal,
                color: textColor,
              ),
            ),
            Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              size: 16,
              color: textColor,
            ),
          ],
        ),
      ),
    );
  }
}
