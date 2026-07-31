import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srp_lanske/app/config/app_config.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';
import 'package:srp_lanske/l10n/l10n.dart';
import 'package:srp_lanske/shared/infrastructure/generated_schedule_api_client.dart';
import 'package:srp_lanske/shared/presentation/app_message_type.dart';
import 'package:srp_lanske/shared/presentation/app_snack_bar.dart';
import 'package:srp_lanske/shared/repositories/app_repositories.dart';
import 'package:srp_lanske/shared/utils/browser_url.dart';
import 'package:srp_lanske/shared/utils/external_link.dart';

import '../application/doubles_schedule_refresh_service.dart';
import '../application/generated_schedule_service.dart';
import '../application/local_schedule_history_mapper.dart';
import '../application/saved_event_aggregate_helpers.dart';
import '../application/schedule_share_url.dart';
import '../data/local_schedule_history_store.dart';
import '../domain/saved_event_models.dart';
import 'event_list_page.dart';
import 'event_setup_page.dart';
import 'models/event_draft.dart';
import 'widgets/court_display_settings_dialog.dart';
import 'widgets/schedule_event_summary_card.dart';
import 'widgets/schedule_operation_panel.dart';
import 'widgets/schedule_players_card.dart';
import 'widgets/schedule_rounds_view.dart';
import 'widgets/schedule_section_card.dart';
import 'widgets/schedule_share_dialog.dart';

const _supportPagePath = '/support/index.html';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key, required this.draft});

  final EventDraft draft;

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

enum _ScheduleMenuAction { top, list, support }

class _SchedulePageState extends State<SchedulePage> {
  late final GeneratedScheduleService _service;
  late final DoublesScheduleRefreshService _refreshService;

  bool _isLoading = true;
  bool _isAdopting = false;
  bool _isRefreshing = false;
  bool _isCheckingRegenerate = false;
  bool _isOpeningSharedDataDialog = false;
  int _refreshRequestSequence = 0;
  String? _errorMessage;
  String? _generatedScheduleId;
  String? _selectedPlayerId;
  Map<String, dynamic>? _scheduleResponse;
  ScheduleProgressSummary? _progressSummary;
  List<ScheduleMatchProgress> _matchProgresses = const [];

  SavedEventAggregate? _savedEvent;

  @override
  void initState() {
    super.initState();

    _service = GeneratedScheduleService(
      GeneratedScheduleApiClient(
        baseUrl: AppConfig.coreApiBaseUrl,
      ),
    );
    _refreshService = DoublesScheduleRefreshService(
      eventRepository: appEventRepository,
      progressRepository: appScheduleProgressRepository,
      loadGeneratedSchedule: _service.getById,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _generateSchedule();
      }
    });
  }

  bool get _isAdopted => _scheduleResponse?['adopted'] == true;

  bool get _hasAdoptedSchedule {
    return _isAdopted || (_savedEvent?.event.hasAdoptedSchedule ?? false);
  }

  String get _pageTitle {
    return _savedEvent?.event.title ?? widget.draft.eventName;
  }

  String _generateButtonLabel(AppLocalizations l10n) {
    final generatedScheduleId =
        _savedEvent?.event.displayGeneratedScheduleId ?? _generatedScheduleId;

    return generatedScheduleId == null || generatedScheduleId.isEmpty
        ? l10n.generateButton
        : l10n.regenerateButton;
  }

  bool get _hasGeneratedSchedule {
    final generatedScheduleId =
        _savedEvent?.event.displayGeneratedScheduleId ?? _generatedScheduleId;

    return generatedScheduleId != null && generatedScheduleId.isNotEmpty;
  }

  List<SavedEventPlayer> get _orderedSavedPlayers {
    final players = _savedEvent?.players.toList() ?? const [];
    if (players.isEmpty) {
      return const [];
    }

    return players..sort((a, b) => a.orderNo.compareTo(b.orderNo));
  }

  Map<String, String> get _playerNameById {
    final savedPlayers = _orderedSavedPlayers;
    if (savedPlayers.isNotEmpty) {
      return {
        for (final player in savedPlayers) player.id: player.displayName,
      };
    }

    return {
      for (final player in widget.draft.players) player.id: player.displayName,
    };
  }

  List<SchedulePlayerViewModel> get _playerViewModels {
    final savedPlayers = _orderedSavedPlayers;
    if (savedPlayers.isNotEmpty) {
      return savedPlayers.map((player) {
        return SchedulePlayerViewModel(
          orderNo: player.orderNo,
          displayName: player.displayName,
          playerId: player.id,
        );
      }).toList(growable: false);
    }

    return widget.draft.players.asMap().entries.map((entry) {
      return SchedulePlayerViewModel(
        orderNo: entry.key + 1,
        displayName: entry.value.displayName,
        playerId: entry.value.id,
      );
    }).toList(growable: false);
  }

  int get _displayCourtCount {
    return _savedEvent?.event.courtCount ?? widget.draft.courts;
  }

  int get _displayPlayerCount {
    final savedPlayers = _orderedSavedPlayers;
    return savedPlayers.isEmpty
        ? widget.draft.playerCount
        : savedPlayers.length;
  }

  List<SavedEventCourtSetting> get _courtSettings {
    return _savedEvent?.courtSettings ??
        buildDefaultCourtSettings(widget.draft.courts);
  }

  Map<int, String> get _courtLabelByNumber {
    return {
      for (final setting in _courtSettings)
        setting.courtNumber: setting.displayLabel,
    };
  }

  String get _courtDisplaySummary {
    final settings = _courtSettings.toList()
      ..sort((a, b) => a.courtNumber.compareTo(b.courtNumber));

    return settings.map((setting) => setting.displayLabel).join(' / ');
  }

  String get _progressText {
    final summary = _progressSummary;
    if (summary == null) {
      return '- / -';
    }

    return '${summary.completedMatchCount} / ${summary.totalMatchCount}';
  }

  DoublesScheduleRefreshSnapshot? get _currentRefreshSnapshot {
    final aggregate = _savedEvent;
    if (aggregate == null) {
      return null;
    }

    return DoublesScheduleRefreshSnapshot.fromCurrentState(
      aggregate: aggregate,
      scheduleResponse: _scheduleResponse,
      progressSummary: _progressSummary,
      matches: _matchProgresses,
    );
  }

  void _toggleSelectedPlayer(String playerId) {
    setState(() {
      _selectedPlayerId = _selectedPlayerId == playerId ? null : playerId;
    });
  }

  Future<void> _requestGenerateSchedule() async {
    if (_isCheckingRegenerate || _isLoading || _isAdopting) return;

    if (!_hasGeneratedSchedule) {
      await _generateSchedule();
      return;
    }

    final l10n = AppLocalizations.of(context);
    final expectedGeneratedScheduleId = _generatedScheduleId;
    if (expectedGeneratedScheduleId == null ||
        expectedGeneratedScheduleId.isEmpty) {
      await _generateSchedule();
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.regenerateConfirmTitle),
          content: Text(l10n.regenerateConfirmBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancelButton),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.regenerateActionButton),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    final canGenerate = await _refreshBeforeRegenerate(
      expectedGeneratedScheduleId: expectedGeneratedScheduleId,
    );
    if (!mounted || !canGenerate) return;

    await _generateSchedule();
  }

  Future<bool> _refreshBeforeRegenerate({
    required String expectedGeneratedScheduleId,
  }) async {
    final aggregate = _savedEvent;
    if (aggregate == null) return false;

    final l10n = AppLocalizations.of(context);
    final requestSequence = ++_refreshRequestSequence;
    final currentSnapshot = _currentRefreshSnapshot;

    setState(() {
      _isCheckingRegenerate = true;
      _errorMessage = null;
    });

    try {
      final snapshot = await _refreshService.loadLatestByPublicId(
        publicId: aggregate.event.publicId,
        current: currentSnapshot,
      );
      if (!mounted || requestSequence != _refreshRequestSequence) {
        return false;
      }

      final shouldApplySnapshot =
          currentSnapshot == null || snapshot.hasChanges;
      final latestPlayerIds =
          snapshot.aggregate.players.map((player) => player.id).toSet();
      final selectedPlayerId = _selectedPlayerId;

      setState(() {
        if (shouldApplySnapshot) {
          _savedEvent = snapshot.aggregate;
          _scheduleResponse = snapshot.scheduleResponse;
          _generatedScheduleId = snapshot.generatedScheduleId;
          _progressSummary = snapshot.progressSummary;
          _matchProgresses = snapshot.matches;
          if (selectedPlayerId != null &&
              !latestPlayerIds.contains(selectedPlayerId)) {
            _selectedPlayerId = null;
          }
        }
      });

      await _saveScheduleHistory(snapshot.aggregate);
      if (!mounted || requestSequence != _refreshRequestSequence) {
        return false;
      }

      if (snapshot.aggregate.event.hasAdoptedSchedule) {
        _showMessage(
          l10n.cannotRegenerateAdoptedScheduleMessage,
          type: AppMessageType.warning,
        );
        return false;
      }

      if (snapshot.generatedScheduleId != expectedGeneratedScheduleId) {
        _showMessage(
          l10n.scheduleUpdatedReloadMessage,
          type: AppMessageType.info,
        );
        return false;
      }

      return true;
    } on DoublesScheduleNotFoundException {
      if (!mounted || requestSequence != _refreshRequestSequence) {
        return false;
      }

      setState(() {
        _savedEvent = null;
        _scheduleResponse = null;
        _generatedScheduleId = null;
        _selectedPlayerId = null;
        _progressSummary = null;
        _matchProgresses = const [];
        _errorMessage = l10n.scheduleNotFoundMessage;
      });
      _showMessage(
        l10n.scheduleNotFoundMessage,
        type: AppMessageType.error,
      );
      return false;
    } catch (e) {
      if (!mounted || requestSequence != _refreshRequestSequence) {
        return false;
      }

      final message = l10n.reloadScheduleFailedMessage(e.toString());
      setState(() {
        _errorMessage = message;
      });
      _showMessage(message, type: AppMessageType.error);
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingRegenerate = false;
        });
      }
    }
  }

  Future<SavedEventAggregate?> _refreshSavedEventForAction() async {
    final l10n = AppLocalizations.of(context);
    final savedEvent = _savedEvent;
    if (savedEvent == null) return null;

    final aggregate =
        await appEventRepository.findByPublicId(savedEvent.event.publicId);
    if (!mounted) return null;

    if (aggregate == null) {
      setState(() {
        _savedEvent = null;
        _scheduleResponse = null;
        _generatedScheduleId = null;
        _progressSummary = null;
        _matchProgresses = const [];
        _errorMessage = l10n.scheduleNotFoundMessage;
      });
      return null;
    }

    setState(() {
      _savedEvent = aggregate;
      _generatedScheduleId = aggregate.event.displayGeneratedScheduleId;
    });

    return aggregate;
  }

  Future<SavedEventAggregate> _ensureSavedEvent() async {
    final existing = _savedEvent;
    if (existing != null) return existing;

    final savedEvent = await appEventRepository.createFromDraft(widget.draft);
    _savedEvent = savedEvent;
    return savedEvent;
  }

  void _replaceBrowserUrlWithPublicId(String publicId) {
    replaceUrl(buildScheduleShareUrl(baseUri: Uri.base, publicId: publicId));
  }

  String? _buildShareUrl() {
    final publicId = _savedEvent?.event.publicId;
    if (publicId == null || publicId.isEmpty) return null;

    return buildScheduleShareUrl(baseUri: Uri.base, publicId: publicId);
  }

  Future<void> _copyShareUrl() async {
    final l10n = AppLocalizations.of(context);
    final shareUrl = _buildShareUrl();
    if (shareUrl == null) {
      _showMessage(
        l10n.shareUrlCreateFailedMessage,
        type: AppMessageType.error,
      );
      return;
    }

    await Clipboard.setData(ClipboardData(text: shareUrl));
    _showMessage(
      l10n.shareUrlCopiedMessage,
      type: AppMessageType.success,
    );
  }

  void _showShareDialog() {
    final l10n = AppLocalizations.of(context);
    final shareUrl = _buildShareUrl();

    if (shareUrl == null) {
      _showMessage(
        l10n.shareUrlCreateFailedMessage,
        type: AppMessageType.error,
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (_) {
        return ScheduleShareDialog(
          shareUrl: shareUrl,
          onCopyShareUrl: _copyShareUrl,
        );
      },
    );
  }

  void _showMessage(
    String message, {
    AppMessageType type = AppMessageType.info,
  }) {
    AppSnackBar.show(
      context,
      message: message,
      type: type,
    );
  }

  Future<void> _generateSchedule() async {
    final l10n = AppLocalizations.of(context);
    if (_hasAdoptedSchedule) {
      _showMessage(
        l10n.cannotRegenerateAdoptedScheduleMessage,
        type: AppMessageType.warning,
      );
      return;
    }

    _refreshRequestSequence += 1;
    setState(() {
      _isLoading = true;
      _isRefreshing = false;
      _errorMessage = null;
    });

    try {
      final savedEvent = await _ensureSavedEvent();
      final response = await _service.generateFromDraft(widget.draft);
      if (!mounted) return;

      final generatedScheduleId = response['generated_schedule_id']?.toString();

      var nextSavedEvent = savedEvent;
      if (generatedScheduleId != null && generatedScheduleId.isNotEmpty) {
        final updatedEvent =
            await appEventRepository.updateCurrentGeneratedScheduleId(
          eventId: savedEvent.event.id,
          generatedScheduleId: generatedScheduleId,
        );

        nextSavedEvent = replaceSavedEventInAggregate(savedEvent, updatedEvent);
      }

      if (!mounted) return;

      setState(() {
        _savedEvent = nextSavedEvent;
        _scheduleResponse = response;
        _generatedScheduleId = generatedScheduleId;
        _progressSummary = null;
        _matchProgresses = const [];
      });

      _replaceBrowserUrlWithPublicId(nextSavedEvent.event.publicId);
      await _saveScheduleHistory(nextSavedEvent);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = l10n.generateScheduleFailedMessage(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _refreshLatestAll({
    bool showSuccess = false,
    bool initialLoad = false,
  }) async {
    final aggregate = _savedEvent;
    if (aggregate == null) {
      return false;
    }

    final l10n = AppLocalizations.of(context);
    final requestSequence = ++_refreshRequestSequence;
    final currentSnapshot = _currentRefreshSnapshot;
    final previousGeneratedScheduleId = _generatedScheduleId;
    final hadExistingDisplay = _scheduleResponse != null;

    setState(() {
      _isRefreshing = true;
      if (initialLoad && !hadExistingDisplay) {
        _isLoading = true;
      }
      _errorMessage = null;
    });

    try {
      final snapshot = await _refreshService.loadLatestByPublicId(
        publicId: aggregate.event.publicId,
        current: currentSnapshot,
      );
      if (!mounted || requestSequence != _refreshRequestSequence) {
        return false;
      }

      final shouldApplySnapshot =
          currentSnapshot == null || snapshot.hasChanges;
      final latestPlayerIds =
          snapshot.aggregate.players.map((player) => player.id).toSet();
      final selectedPlayerId = _selectedPlayerId;

      setState(() {
        if (shouldApplySnapshot) {
          _savedEvent = snapshot.aggregate;
          _scheduleResponse = snapshot.scheduleResponse;
          _generatedScheduleId = snapshot.generatedScheduleId;
          _progressSummary = snapshot.progressSummary;
          _matchProgresses = snapshot.matches;
          if (selectedPlayerId != null &&
              !latestPlayerIds.contains(selectedPlayerId)) {
            _selectedPlayerId = null;
          }
        }
        if (snapshot.aggregate.players.isEmpty) {
          _errorMessage = l10n.noPlayersMessage;
        } else if (snapshot.generatedScheduleId == null ||
            snapshot.generatedScheduleId!.isEmpty) {
          _errorMessage = l10n.scheduleNotLoadedMessage;
        }
        _isRefreshing = false;
        _isLoading = false;
      });

      await _saveScheduleHistory(snapshot.aggregate);
      if (!mounted || requestSequence != _refreshRequestSequence) {
        return true;
      }

      final latestGeneratedScheduleId = snapshot.generatedScheduleId;
      final scheduleWasReplaced = previousGeneratedScheduleId != null &&
          previousGeneratedScheduleId.isNotEmpty &&
          latestGeneratedScheduleId != previousGeneratedScheduleId;

      if (scheduleWasReplaced) {
        _showMessage(
          l10n.scheduleUpdatedReloadMessage,
          type: AppMessageType.info,
        );
      } else if (showSuccess) {
        _showMessage(
          l10n.bocciaScoreRefreshedMessage,
          type: AppMessageType.success,
        );
      }

      return true;
    } on DoublesScheduleNotFoundException {
      if (!mounted || requestSequence != _refreshRequestSequence) {
        return false;
      }

      setState(() {
        _savedEvent = null;
        _scheduleResponse = null;
        _generatedScheduleId = null;
        _selectedPlayerId = null;
        _progressSummary = null;
        _matchProgresses = const [];
        _errorMessage = l10n.scheduleNotFoundMessage;
        _isRefreshing = false;
        _isLoading = false;
      });
      _showMessage(
        l10n.scheduleNotFoundMessage,
        type: AppMessageType.error,
      );
      return false;
    } catch (e) {
      if (!mounted || requestSequence != _refreshRequestSequence) {
        return false;
      }

      final message = l10n.reloadScheduleFailedMessage(e.toString());
      setState(() {
        _errorMessage = message;
        _isRefreshing = false;
        _isLoading = false;
      });
      _showMessage(message, type: AppMessageType.error);
      return false;
    }
  }

  Future<void> _reloadSchedule({bool showSuccess = true}) async {
    await _refreshLatestAll(showSuccess: showSuccess);
  }

  Future<void> _adoptSchedule() async {
    final l10n = AppLocalizations.of(context);
    final displayedGeneratedScheduleId = _generatedScheduleId;

    if (displayedGeneratedScheduleId == null ||
        displayedGeneratedScheduleId.isEmpty) {
      _showMessage(
        l10n.adoptScheduleMissingIdMessage,
        type: AppMessageType.warning,
      );
      return;
    }

    if (_isAdopting || _hasAdoptedSchedule) return;

    setState(() {
      _isAdopting = true;
      _errorMessage = null;
    });

    try {
      final latestEvent = await _refreshSavedEventForAction();
      if (!mounted) return;

      if (latestEvent == null) {
        _showMessage(
          l10n.adoptEventMissingMessage,
          type: AppMessageType.error,
        );
        return;
      }

      if (latestEvent.event.hasAdoptedSchedule) {
        _showMessage(
          l10n.alreadyAdoptedScheduleMessage,
          type: AppMessageType.info,
        );
        await _reloadSchedule(showSuccess: false);
        return;
      }

      final latestCurrentGeneratedScheduleId =
          latestEvent.event.currentGeneratedScheduleId;

      if (latestCurrentGeneratedScheduleId != displayedGeneratedScheduleId) {
        _showMessage(
          l10n.scheduleUpdatedReloadMessage,
          type: AppMessageType.info,
        );
        await _reloadSchedule(showSuccess: false);
        return;
      }

      await _service.adopt(displayedGeneratedScheduleId);

      final updatedEvent =
          await appEventRepository.updateAdoptedGeneratedScheduleId(
        eventId: latestEvent.event.id,
        generatedScheduleId: displayedGeneratedScheduleId,
      );

      if (!mounted) return;

      final nextSavedEvent = replaceSavedEventInAggregate(
        latestEvent,
        updatedEvent,
      );
      setState(() {
        _savedEvent = nextSavedEvent;
      });
      await _saveScheduleHistory(nextSavedEvent);

      _showMessage(
        l10n.adoptScheduleCompletedMessage,
        type: AppMessageType.success,
      );
      await _reloadSchedule(showSuccess: false);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = l10n.adoptScheduleFailedMessage(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _isAdopting = false;
        });
      }
    }
  }

  Future<void> _saveScheduleHistory(SavedEventAggregate aggregate) async {
    await LocalScheduleHistoryStore().upsert(
      buildLocalScheduleHistoryItem(
        aggregate,
        now: DateTime.now(),
      ),
    );
  }

  Future<void> _changeCourtDisplay() async {
    if (_isOpeningSharedDataDialog || _isRefreshing) {
      return;
    }

    var dialogOpened = false;
    setState(() {
      _isOpeningSharedDataDialog = true;
    });

    try {
      final refreshed = await _refreshLatestAll(showSuccess: false);
      if (!mounted || !refreshed) {
        return;
      }

      final savedEvent = _savedEvent;
      if (savedEvent == null || _hasAdoptedSchedule) {
        return;
      }

      dialogOpened = true;
      final nextSettings = await showDialog<List<SavedEventCourtSetting>>(
        context: context,
        builder: (context) {
          return CourtDisplaySettingsDialog(
            courtCount: savedEvent.event.courtCount,
            initialSettings: _courtSettings,
          );
        },
      );

      if (!mounted || nextSettings == null) return;

      final updatedAggregate = await appEventRepository.updateCourtSettings(
        eventId: savedEvent.event.id,
        courtSettings: nextSettings,
      );

      if (!mounted) return;

      setState(() {
        _savedEvent = updatedAggregate;
      });

      await _saveScheduleHistory(updatedAggregate);
    } catch (e) {
      if (!mounted) return;

      final message = AppLocalizations.of(context)
          .reloadScheduleFailedMessage(e.toString());
      setState(() {
        _errorMessage = message;
      });
      _showMessage(message, type: AppMessageType.error);
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningSharedDataDialog = false;
        });
      }
      if (mounted && dialogOpened) {
        await _refreshLatestAll(showSuccess: false);
      }
    }
  }

  void _handleMenu(_ScheduleMenuAction action) {
    switch (action) {
      case _ScheduleMenuAction.top:
        _goTop();
        break;
      case _ScheduleMenuAction.list:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EventListPage(
              currentPublicId: _savedEvent?.event.publicId,
            ),
          ),
        );
        break;
      case _ScheduleMenuAction.support:
        openUrlInCurrentTab(_supportPagePath);
        break;
    }
  }

  void _goTop() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const EventSetupPage()),
      (_) => false,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      replaceUrl('/');
    });
  }

  Widget _buildSupportMenuItem(AppLocalizations l10n) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(l10n.supportMenuTitle),
        Text(
          l10n.supportMenuSubtitle,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  Widget _buildScheduleBody() {
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(4),
      children: [
        ScheduleEventSummaryCard(
          onShareUrl: _savedEvent == null ? null : _showShareDialog,
          onRefresh: () => _reloadSchedule(),
          canRefresh: _generatedScheduleId != null &&
              !_isLoading &&
              !_isOpeningSharedDataDialog,
          isRefreshing: _isRefreshing,
          progressText: _progressText,
        ),
        const SizedBox(height: 12),
        SchedulePlayersCard(
          title: l10n.schedulePlayersTitle(
            _displayCourtCount,
            _displayPlayerCount,
          ),
          players: _playerViewModels,
          selectedPlayerId: _selectedPlayerId,
          onPlayerSelected: _toggleSelectedPlayer,
        ),
        const SizedBox(height: 12),
        ScheduleSectionCard(
          child: ScheduleOperationPanel(
            courtDisplaySummary: _courtDisplaySummary,
            canChangeCourtDisplay: !_hasAdoptedSchedule &&
                _savedEvent != null &&
                !_isRefreshing &&
                !_isCheckingRegenerate &&
                !_isOpeningSharedDataDialog,
            onChangeCourtDisplay: _changeCourtDisplay,
            showActionButtons: !_hasAdoptedSchedule,
            isLoading: _isLoading ||
                _isRefreshing ||
                _isCheckingRegenerate ||
                _isOpeningSharedDataDialog,
            isAdopting: _isAdopting,
            generateButtonLabel: _generateButtonLabel(l10n),
            canAdopt: _generatedScheduleId != null && _scheduleResponse != null,
            onGenerate: _requestGenerateSchedule,
            onAdopt: _adoptSchedule,
          ),
        ),
        const SizedBox(height: 12),
        ScheduleSectionCard(
          title: l10n.matchTableTitle,
          child: _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(4),
                    child: CircularProgressIndicator(),
                  ),
                )
              : ScheduleRoundsView(
                  scheduleResponse: _scheduleResponse,
                  playerNameById: _playerNameById,
                  courtCount: _displayCourtCount,
                  selectedPlayerId: _selectedPlayerId,
                  onPlayerSelected: _toggleSelectedPlayer,
                  courtLabelByNumber: _courtLabelByNumber,
                ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          ScheduleSectionCard(
            title: l10n.errorTitle,
            child: Text(_errorMessage!),
          ),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final showInitialLoading = _isLoading && _scheduleResponse == null;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(_pageTitle),
        actions: [
          PopupMenuButton<_ScheduleMenuAction>(
            onSelected: _handleMenu,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _ScheduleMenuAction.top,
                child: Text(l10n.topPageMenu),
              ),
              PopupMenuItem(
                value: _ScheduleMenuAction.list,
                child: Text(l10n.matchTableList),
              ),
              PopupMenuItem(
                value: _ScheduleMenuAction.support,
                child: _buildSupportMenuItem(l10n),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: showInitialLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _buildScheduleBody(),
      ),
    );
  }
}
