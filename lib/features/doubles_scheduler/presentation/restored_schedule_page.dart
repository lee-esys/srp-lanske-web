import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srp_lanske/app/config/app_config.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/event_setup_page.dart';
import 'package:srp_lanske/l10n/l10n.dart';
import 'package:srp_lanske/shared/repositories/app_repositories.dart';
import 'package:srp_lanske/shared/utils/browser_url.dart';
import 'package:srp_lanske/shared/utils/external_link.dart';

import '../application/generated_schedule_service.dart';
import '../application/local_schedule_history_mapper.dart';
import '../application/saved_event_aggregate_helpers.dart';
import '../application/schedule_share_url.dart';
import '../data/local_schedule_history_store.dart';
import '../domain/player_draft.dart';
import '../domain/public_id.dart';
import '../domain/saved_event_models.dart';
import 'package:srp_lanske/shared/infrastructure/generated_schedule_api_client.dart';
import 'event_list_page.dart';
import 'models/event_draft.dart';
import 'widgets/court_display_settings_dialog.dart';
import 'widgets/schedule_event_summary_card.dart';
import 'widgets/schedule_operation_panel.dart';
import 'widgets/schedule_players_card.dart';
import 'widgets/schedule_rounds_view.dart';
import 'widgets/schedule_section_card.dart';
import 'widgets/schedule_share_dialog.dart';

const _supportPagePath = '/support/index.html';

class RestoredSchedulePage extends StatefulWidget {
  const RestoredSchedulePage({
    super.key,
    required this.publicId,
  });

  final String publicId;

  @override
  State<RestoredSchedulePage> createState() => _RestoredSchedulePageState();
}

enum _ScheduleMenuAction { top, list, support }

class _RestoredSchedulePageState extends State<RestoredSchedulePage> {
  late final GeneratedScheduleService _service;

  bool _isLoading = true;
  bool _isAdopting = false;
  String? _errorMessage;

  SavedEventAggregate? _savedEvent;
  String? _generatedScheduleId;
  String? _selectedPlayerId;
  Map<String, dynamic>? _scheduleResponse;

  @override
  void initState() {
    super.initState();

    _service = GeneratedScheduleService(
      GeneratedScheduleApiClient(
        baseUrl: AppConfig.coreApiBaseUrl,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _restore();
      }
    });
  }

  bool get _isAdopted => _scheduleResponse?['adopted'] == true;

  bool get _hasAdoptedSchedule {
    return _isAdopted || (_savedEvent?.event.hasAdoptedSchedule ?? false);
  }

  String _pageTitle(AppLocalizations l10n) {
    return _savedEvent?.event.title ?? l10n.matchTableTitle;
  }

  String _generateButtonLabel(AppLocalizations l10n) {
    final generatedScheduleId = _savedEvent?.event.displayGeneratedScheduleId;
    return generatedScheduleId == null || generatedScheduleId.isEmpty
        ? l10n.generateButton
        : l10n.regenerateButton;
  }

  bool get _hasGeneratedSchedule {
    final generatedScheduleId =
        _savedEvent?.event.displayGeneratedScheduleId ?? _generatedScheduleId;

    return generatedScheduleId != null && generatedScheduleId.isNotEmpty;
  }

  List<SavedEventPlayer> get _orderedPlayers {
    final players = _savedEvent?.players.toList() ?? const [];
    if (players.isEmpty) return const [];

    return players.toList()..sort((a, b) => a.orderNo.compareTo(b.orderNo));
  }

  Map<String, String> get _playerNameById {
    return {
      for (final player in _orderedPlayers) player.id: player.displayName,
    };
  }

  List<SchedulePlayerViewModel> get _playerViewModels {
    return _orderedPlayers.map((player) {
      return SchedulePlayerViewModel(
        orderNo: player.orderNo,
        displayName: player.displayName,
        playerId: player.id,
      );
    }).toList(growable: false);
  }

  List<SavedEventCourtSetting> get _courtSettings {
    return _savedEvent?.courtSettings ??
        buildDefaultCourtSettings(_savedEvent?.courtSettings.length ??
            _savedEvent?.event.courtCount ??
            0);
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

  void _toggleSelectedPlayer(String playerId) {
    setState(() {
      _selectedPlayerId = _selectedPlayerId == playerId ? null : playerId;
    });
  }

  Future<void> _requestGenerateSchedule() async {
    final l10n = AppLocalizations.of(context);
    final latestEvent = await _refreshSavedEventForAction();
    if (!mounted) return;

    if (latestEvent?.event.hasAdoptedSchedule == true) {
      _showMessage(l10n.cannotRegenerateAdoptedScheduleMessage);
      await _reloadSchedule();
      return;
    }

    if (!_hasGeneratedSchedule) {
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

    final latestBeforeGenerate = await _refreshSavedEventForAction();
    if (!mounted) return;

    if (latestBeforeGenerate?.event.hasAdoptedSchedule == true) {
      _showMessage(l10n.cannotRegenerateAdoptedScheduleMessage);
      await _reloadSchedule();
      return;
    }

    await _generateSchedule();
  }

  Future<SavedEventAggregate?> _refreshSavedEventForAction() async {
    final l10n = AppLocalizations.of(context);
    final publicId =
        (_savedEvent?.event.publicId ?? widget.publicId).trim().toUpperCase();

    if (!isValidPublicId(publicId)) {
      setState(() {
        _errorMessage = l10n.scheduleNotFoundMessage;
      });
      return null;
    }

    final aggregate = await appEventRepository.findByPublicId(publicId);
    if (!mounted) return null;

    if (aggregate == null) {
      setState(() {
        _savedEvent = null;
        _scheduleResponse = null;
        _generatedScheduleId = null;
        _selectedPlayerId = null;
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

  Future<void> _restore() async {
    final l10n = AppLocalizations.of(context);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final publicId = widget.publicId.trim().toUpperCase();

    if (!isValidPublicId(publicId)) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = l10n.scheduleNotFoundMessage;
      });
      return;
    }

    try {
      final aggregate = await appEventRepository.findByPublicId(publicId);
      if (!mounted) return;

      if (aggregate == null) {
        setState(() {
          _savedEvent = null;
          _scheduleResponse = null;
          _generatedScheduleId = null;
          _selectedPlayerId = null;
          _errorMessage = l10n.scheduleNotFoundMessage;
          _isLoading = false;
        });
        return;
      }

      final generatedScheduleId = aggregate.event.displayGeneratedScheduleId;

      setState(() {
        _savedEvent = aggregate;
        _generatedScheduleId = generatedScheduleId;
      });

      if (aggregate.players.isEmpty) {
        setState(() {
          _selectedPlayerId = null;
          _errorMessage = l10n.noPlayersMessage;
          _isLoading = false;
        });
        return;
      }

      if (generatedScheduleId == null || generatedScheduleId.isEmpty) {
        setState(() {
          _errorMessage = l10n.scheduleNotLoadedMessage;
          _isLoading = false;
        });
        return;
      }

      await _fetchSchedule(generatedScheduleId);
    } catch (e, stackTrace) {
      debugPrint('Failed to restore schedule: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _savedEvent = null;
        _scheduleResponse = null;
        _generatedScheduleId = null;
        _selectedPlayerId = null;
        _errorMessage = l10n.reloadScheduleFailedMessage(e.toString());
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSchedule(String generatedScheduleId) async {
    final l10n = AppLocalizations.of(context);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _service.getById(generatedScheduleId);
      if (!mounted) return;

      setState(() {
        _scheduleResponse = response;
        _generatedScheduleId = response['generated_schedule_id']?.toString() ??
            generatedScheduleId;
        _isLoading = false;
      });

      final aggregate = _savedEvent;
      if (aggregate != null) {
        await _saveScheduleHistory(aggregate);
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _scheduleResponse = null;
        _errorMessage = l10n.reloadScheduleFailedMessage(e.toString());
        _isLoading = false;
      });
    }
  }

  Future<void> _reloadSchedule() async {
    final l10n = AppLocalizations.of(context);
    final publicId =
        (_savedEvent?.event.publicId ?? widget.publicId).trim().toUpperCase();

    if (!isValidPublicId(publicId)) {
      _showMessage(l10n.scheduleNotFoundMessage);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final aggregate = await appEventRepository.findByPublicId(publicId);
      if (!mounted) return;

      if (aggregate == null) {
        setState(() {
          _savedEvent = null;
          _scheduleResponse = null;
          _generatedScheduleId = null;
          _selectedPlayerId = null;
          _errorMessage = l10n.scheduleNotFoundMessage;
          _isLoading = false;
        });
        return;
      }

      final generatedScheduleId = aggregate.event.displayGeneratedScheduleId;

      setState(() {
        _savedEvent = aggregate;
        _generatedScheduleId = generatedScheduleId;
      });

      if (generatedScheduleId == null || generatedScheduleId.isEmpty) {
        setState(() {
          _scheduleResponse = null;
          _errorMessage = l10n.scheduleNotLoadedMessage;
          _isLoading = false;
        });
        return;
      }

      await _fetchSchedule(generatedScheduleId);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = l10n.reloadScheduleFailedMessage(e.toString());
        _isLoading = false;
      });
    }
  }

  Future<void> _generateSchedule() async {
    final l10n = AppLocalizations.of(context);
    final savedEvent = _savedEvent;
    if (savedEvent == null) {
      _showMessage(l10n.adoptEventMissingMessage);
      return;
    }

    if (_hasAdoptedSchedule) {
      _showMessage(l10n.cannotRegenerateAdoptedScheduleMessage);
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final draft = _buildDraft(savedEvent);
      final response = await _service.generateFromDraft(draft);
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
        _isLoading = false;
      });

      await _saveScheduleHistory(nextSavedEvent);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = l10n.generateScheduleFailedMessage(e.toString());
        _isLoading = false;
      });
    }
  }

  Future<void> _adoptSchedule() async {
    final l10n = AppLocalizations.of(context);
    final displayedGeneratedScheduleId = _generatedScheduleId;

    if (displayedGeneratedScheduleId == null ||
        displayedGeneratedScheduleId.isEmpty) {
      _showMessage(l10n.adoptScheduleMissingIdMessage);
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
        _showMessage(l10n.adoptEventMissingMessage);
        return;
      }

      if (latestEvent.event.hasAdoptedSchedule) {
        _showMessage(l10n.alreadyAdoptedScheduleMessage);
        await _reloadSchedule();
        return;
      }

      final latestCurrentGeneratedScheduleId =
          latestEvent.event.currentGeneratedScheduleId;

      if (latestCurrentGeneratedScheduleId != displayedGeneratedScheduleId) {
        _showMessage(l10n.scheduleUpdatedReloadMessage);
        await _reloadSchedule();
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

      _showMessage(l10n.adoptScheduleCompletedMessage);
      await _reloadSchedule();
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
    final savedEvent = _savedEvent;
    if (savedEvent == null || _hasAdoptedSchedule) return;

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
              currentPublicId: _savedEvent?.event.publicId ?? widget.publicId,
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

  EventDraft _buildDraft(SavedEventAggregate aggregate) {
    return EventDraft(
      url: aggregate.event.sourceUrl ?? '',
      courts: aggregate.event.courtCount,
      eventName: aggregate.event.title,
      players: _orderedPlayers.map((player) {
        return PlayerDraft(
          id: player.id,
          displayName: player.displayName,
        );
      }).toList(growable: false),
    );
  }

  String _buildShareUrl() {
    final publicId = _savedEvent?.event.publicId ?? widget.publicId;

    return buildScheduleShareUrl(baseUri: Uri.base, publicId: publicId);
  }

  Future<void> _copyShareUrl() async {
    final l10n = AppLocalizations.of(context);
    await Clipboard.setData(ClipboardData(text: _buildShareUrl()));
    _showMessage(l10n.shareUrlCopiedMessage);
  }

  void _showShareDialog() {
    showDialog<void>(
      context: context,
      builder: (_) {
        return ScheduleShareDialog(
          shareUrl: _buildShareUrl(),
          onCopyShareUrl: _copyShareUrl,
        );
      },
    );
  }

  void _showMessage(String message) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
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
    final savedEvent = _savedEvent;

    return ListView(
      padding: const EdgeInsets.all(4),
      children: [
        if (savedEvent == null)
          ScheduleSectionCard(
            title: 'URL',
            child: Text('ID: ${widget.publicId}'),
          )
        else ...[
          ScheduleEventSummaryCard(
            onShareUrl: _showShareDialog,
            onRefresh: _reloadSchedule,
            canRefresh: _generatedScheduleId != null,
          ),
          const SizedBox(height: 12),
          SchedulePlayersCard(
            title: l10n.schedulePlayersTitle(
              savedEvent.event.courtCount,
              savedEvent.players.length,
            ),
            players: _playerViewModels,
            selectedPlayerId: _selectedPlayerId,
            onPlayerSelected: _toggleSelectedPlayer,
          ),
          const SizedBox(height: 12),
          ScheduleSectionCard(
            child: ScheduleOperationPanel(
              courtDisplaySummary: _courtDisplaySummary,
              canChangeCourtDisplay:
                  !_hasAdoptedSchedule && _savedEvent != null,
              onChangeCourtDisplay: _changeCourtDisplay,
              showActionButtons: !_hasAdoptedSchedule,
              isLoading: _isLoading,
              isAdopting: _isAdopting,
              generateButtonLabel: _generateButtonLabel(l10n),
              canAdopt:
                  _generatedScheduleId != null && _scheduleResponse != null,
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
                    courtCount: savedEvent.event.courtCount,
                    selectedPlayerId: _selectedPlayerId,
                    onPlayerSelected: _toggleSelectedPlayer,
                    courtLabelByNumber: _courtLabelByNumber,
                  ),
          ),
        ],
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
    final showInitialLoading = _isLoading && _savedEvent == null;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(
          _pageTitle(l10n),
          overflow: TextOverflow.ellipsis,
        ),
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
