import 'package:flutter/material.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/doubles_match_progress_service.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/local_schedule_history_mapper.dart';
import 'package:srp_lanske/features/doubles_scheduler/data/local_schedule_history_store.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/doubles_progress_ui_store.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/doubles_progress_visuals.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/models/doubles_match_editor_models.dart';
import 'package:srp_lanske/features/schedule_progress/application/schedule_progress_repository.dart';
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
  late final DoublesMatchProgressService _progressService;

  Map<String, ScheduleMatchProgress> _progressByKey = const {};
  bool _canEditMatches = false;
  bool _isLoadingProgress = false;
  bool _isOpeningMatch = false;
  int _progressRequestSequence = 0;

  @override
  void initState() {
    super.initState();
    _progressService = DoublesMatchProgressService(
      repository: appScheduleProgressRepository,
    );
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
    return countDoublesScheduleMatches(widget.scheduleResponse);
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

  Future<void> _openMatch(DoublesMatchSelection selection) async {
    if (!_canEditMatches || _isOpeningMatch || _isLoadingProgress) {
      return;
    }

    final scope = _progressScope;
    final publicId = _publicId;
    final generatedScheduleId = _generatedScheduleId;
    final totalMatchCount = _totalMatchCount;
    final l10n = AppLocalizations.of(context);
    if (scope == null ||
        publicId == null ||
        generatedScheduleId == null ||
        totalMatchCount <= 0) {
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

      final latest = await appScheduleProgressRepository.findMatch(
        scope: scope,
        roundNo: selection.roundNo,
        courtNo: selection.courtNo,
        matchNo: selection.matchNo,
      );
      if (!mounted) {
        return;
      }

      final input = await showDialog<DoublesMatchProgressInput>(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return DoublesMatchResultDialog(
            match: selection,
            initialProgress: latest,
          );
        },
      );
      if (!mounted || input == null) {
        return;
      }

      final saved = await _progressService.save(
        scope: scope,
        current: latest,
        input: input,
        totalMatchCount: totalMatchCount,
      );
      if (!mounted) {
        return;
      }

      setState(() {
        _progressByKey = Map<String, ScheduleMatchProgress>.unmodifiable({
          ..._progressByKey,
          saved.match.key.value: saved.match,
        });
      });
      DoublesProgressUiStore.setSummary(saved.summary);

      await LocalScheduleHistoryStore().upsert(
        buildLocalScheduleHistoryItem(
          aggregate,
          now: DateTime.now(),
        ),
      );
      if (!mounted) {
        return;
      }

      AppSnackBar.show(
        context,
        message: l10n.doublesMatchSavedMessage,
        type: AppMessageType.success,
      );
    } on ScheduleProgressConflictException {
      if (!mounted) {
        return;
      }

      AppSnackBar.show(
        context,
        message: l10n.doublesMatchConflictMessage,
        type: AppMessageType.warning,
        actionLabel: l10n.refreshLatestButton,
        onAction: () {
          _loadProgress(showMessage: true);
        },
      );
    } on DoublesMatchIncompleteScoreException {
      if (!mounted) {
        return;
      }
      AppSnackBar.show(
        context,
        message: l10n.doublesMatchIncompleteScoreMessage,
        type: AppMessageType.warning,
      );
    } on DoublesMatchTimeOrderException {
      if (!mounted) {
        return;
      }
      AppSnackBar.show(
        context,
        message: l10n.doublesMatchTimeOrderErrorMessage,
        type: AppMessageType.warning,
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      AppSnackBar.show(
        context,
        message: l10n.doublesMatchSaveFailedMessage(error.toString()),
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

    return Card(
      key: ValueKey('round-card-$roundNumber'),
      color: roundCardColor,
      margin: const EdgeInsets.only(bottom: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'R $roundNumber',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _RestToggleButton(
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
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCourtArea(
                    roundNo: roundNumberValue,
                    courts: courts,
                    slotToPlayerId: slotToPlayerId,
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
          ],
        ),
      ),
    );
  }

  Widget _buildCourtArea({
    required int? roundNo,
    required List<Map<String, dynamic>> courts,
    required Map<int, String> slotToPlayerId,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final courtItemWidth =
            _courtMatchCardWidth.clamp(0.0, maxWidth).toDouble();
        final canUseTwoColumns = courts.length >= 2 &&
            maxWidth >= (_courtMatchCardWidth * 2 + _courtAreaSpacing);

        if (courts.length == 1) {
          return SizedBox(
            width: maxWidth,
            child: _buildCourtMatchCard(
              roundNo: roundNo,
              court: courts.first,
              slotToPlayerId: slotToPlayerId,
              alignment: Alignment.center,
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
                  SizedBox(
                    width: _courtMatchCardWidth,
                    child: _buildCourtMatchCard(
                      roundNo: roundNo,
                      court: courts[0],
                      slotToPlayerId: slotToPlayerId,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                  const SizedBox(width: _courtAreaSpacing),
                  SizedBox(
                    width: _courtMatchCardWidth,
                    child: _buildCourtMatchCard(
                      roundNo: roundNo,
                      court: courts[1],
                      slotToPlayerId: slotToPlayerId,
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (courts.length == 2) {
          return Column(
            children: courts.map((court) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SizedBox(
                  width: maxWidth,
                  child: _buildCourtMatchCard(
                    roundNo: roundNo,
                    court: court,
                    slotToPlayerId: slotToPlayerId,
                    alignment: Alignment.center,
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
          children: courts.map((court) {
            return SizedBox(
              width: itemWidth,
              child: _buildCourtMatchCard(
                roundNo: roundNo,
                court: court,
                slotToPlayerId: slotToPlayerId,
                alignment: Alignment.centerLeft,
              ),
            );
          }).toList(growable: false),
        );
      },
    );
  }

  Widget _buildCourtMatchCard({
    required int? roundNo,
    required Map<String, dynamic> court,
    required Map<int, String> slotToPlayerId,
    Alignment alignment = Alignment.centerLeft,
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

    final hasCustomCourtLabel = courtLabel != defaultCourtLabel;
    final showCourtLabel = widget.courtCount >= 2 || hasCustomCourtLabel;
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

    return _buildHorizontalScrollableContent(
      alignment: alignment,
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
              courtLabel: courtLabel,
              showCourtLabel: showCourtLabel,
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

  Widget _buildHorizontalScrollableContent({
    required Widget child,
    required Alignment alignment,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Align(
              alignment: alignment,
              child: child,
            ),
          ),
        );
      },
    );
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
        width: 40,
        padding: const EdgeInsets.symmetric(vertical: 5),
        decoration: BoxDecoration(
          color: backgroundColor,
          border: Border.all(
            color: borderColor,
            width: isHighlighted ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.restLabel,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  height: 1,
                  fontWeight:
                      isHighlighted ? FontWeight.w700 : FontWeight.normal,
                  color: textColor,
                ),
              ),
              Text(
                l10n.restCountLabel(restCount),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  height: 1,
                  fontWeight:
                      isHighlighted ? FontWeight.w700 : FontWeight.normal,
                  color: textColor,
                ),
              ),
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 14,
                color: textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
