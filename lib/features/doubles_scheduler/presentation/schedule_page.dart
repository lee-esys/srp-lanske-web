import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srp_lanske/app/config/app_config.dart';
import 'package:srp_lanske/shared/repositories/app_repositories.dart';
import 'package:srp_lanske/shared/utils/browser_url.dart';

import '../application/generated_schedule_service.dart';
import '../application/local_schedule_history_mapper.dart';
import '../application/saved_event_aggregate_helpers.dart';
import '../application/schedule_share_url.dart';
import '../data/local_schedule_history_store.dart';
import '../domain/saved_event_models.dart';
import '../infrastructure/generated_schedule_api_client.dart';
import 'event_list_page.dart';
import 'event_setup_page.dart';
import 'models/event_draft.dart';
import 'widgets/schedule_action_buttons.dart';
import 'widgets/schedule_event_summary_card.dart';
import 'widgets/schedule_players_card.dart';
import 'widgets/schedule_rounds_view.dart';
import 'widgets/schedule_section_card.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key, required this.draft});

  final EventDraft draft;

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

enum _ScheduleMenuAction { top, list }

class _SchedulePageState extends State<SchedulePage> {
  late final GeneratedScheduleService _service;

  bool _isLoading = true;
  bool _isAdopting = false;
  String? _errorMessage;
  String? _generatedScheduleId;
  String? _selectedPlayerId;
  Map<String, dynamic>? _scheduleResponse;

  SavedEventAggregate? _savedEvent;

  @override
  void initState() {
    super.initState();

    _service = GeneratedScheduleService(
      GeneratedScheduleApiClient(
        baseUrl: AppConfig.coreApiBaseUrl,
      ),
    );

    _generateSchedule();
  }

  bool get _isAdopted => _scheduleResponse?['adopted'] == true;

  bool get _hasAdoptedSchedule {
    return _isAdopted || (_savedEvent?.event.hasAdoptedSchedule ?? false);
  }

  String get _generateButtonLabel {
    final generatedScheduleId =
        _savedEvent?.event.displayGeneratedScheduleId ?? _generatedScheduleId;

    return generatedScheduleId == null || generatedScheduleId.isEmpty
        ? '生成'
        : '再生成';
  }

  bool get _hasGeneratedSchedule {
    final generatedScheduleId =
        _savedEvent?.event.displayGeneratedScheduleId ?? _generatedScheduleId;

    return generatedScheduleId != null && generatedScheduleId.isNotEmpty;
  }

  Map<String, String> get _playerNameById {
    return {
      for (final player in widget.draft.players) player.id: player.displayName,
    };
  }

  List<SchedulePlayerViewModel> get _playerViewModels {
    return widget.draft.players.asMap().entries.map((entry) {
      return SchedulePlayerViewModel(
        orderNo: entry.key + 1,
        displayName: entry.value.displayName,
        playerId: entry.value.id,
      );
    }).toList(growable: false);
  }

  void _toggleSelectedPlayer(String playerId) {
    setState(() {
      _selectedPlayerId = _selectedPlayerId == playerId ? null : playerId;
    });
  }

  Future<void> _requestGenerateSchedule() async {
    final latestEvent = await _refreshSavedEventForAction();
    if (!mounted) return;

    if (latestEvent?.event.hasAdoptedSchedule == true) {
      _showMessage('採用済みのため再生成できません');
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
          title: const Text('再生成しますか？'),
          content: const Text(
            '現在表示している対戦表を新しい対戦表に差し替えます。\n'
            '共有URLから表示される未採用の対戦表も、再生成後の内容に更新されます。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('再生成する'),
            ),
          ],
        );
      },
    );

    if (!mounted || confirmed != true) return;

    final latestBeforeGenerate = await _refreshSavedEventForAction();
    if (!mounted) return;

    if (latestBeforeGenerate?.event.hasAdoptedSchedule == true) {
      _showMessage('採用済みのため再生成できません');
      await _reloadSchedule();
      return;
    }

    await _generateSchedule();
  }

  Future<SavedEventAggregate?> _refreshSavedEventForAction() async {
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
        _errorMessage = '対戦表が見つかりません';
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
    final shareUrl = _buildShareUrl();
    if (shareUrl == null) {
      _showMessage('URLを作成できませんでした');
      return;
    }

    await Clipboard.setData(ClipboardData(text: shareUrl));
    _showMessage('URLをコピーしました');
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

  Future<void> _generateSchedule() async {
    if (_hasAdoptedSchedule) {
      _showMessage('採用済みのため再生成できません');
      return;
    }

    setState(() {
      _isLoading = true;
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
      });

      _replaceBrowserUrlWithPublicId(nextSavedEvent.event.publicId);
      await _saveScheduleHistory(nextSavedEvent);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = '対戦表を生成できませんでした: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _reloadSchedule() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      var generatedScheduleId = _generatedScheduleId;

      final savedEvent = _savedEvent;
      if (savedEvent != null) {
        final aggregate =
            await appEventRepository.findByPublicId(savedEvent.event.publicId);
        if (!mounted) return;

        if (aggregate != null) {
          generatedScheduleId = aggregate.event.displayGeneratedScheduleId;

          setState(() {
            _savedEvent = aggregate;
            _generatedScheduleId = generatedScheduleId;
          });
        }
      }

      if (generatedScheduleId == null || generatedScheduleId.isEmpty) {
        if (!mounted) return;

        setState(() {
          _scheduleResponse = null;
          _errorMessage = '再取得する generated_schedule_id がありません';
          _isLoading = false;
        });
        return;
      }

      final response = await _service.getById(generatedScheduleId);
      if (!mounted) return;

      setState(() {
        _scheduleResponse = response;
        _generatedScheduleId = response['generated_schedule_id']?.toString() ??
            generatedScheduleId;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = '対戦表を取得できませんでした: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _adoptSchedule() async {
    final displayedGeneratedScheduleId = _generatedScheduleId;

    if (displayedGeneratedScheduleId == null ||
        displayedGeneratedScheduleId.isEmpty) {
      _showMessage('採用する generated_schedule_id がありません');
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
        _showMessage('採用するイベント情報がありません');
        return;
      }

      if (latestEvent.event.hasAdoptedSchedule) {
        _showMessage('すでに採用済みです');
        await _reloadSchedule();
        return;
      }

      final latestCurrentGeneratedScheduleId =
          latestEvent.event.currentGeneratedScheduleId;

      if (latestCurrentGeneratedScheduleId != displayedGeneratedScheduleId) {
        _showMessage('対戦表が更新されています。最新の情報に更新します');
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

      _showMessage('この対戦表を採用しました');
      await _reloadSchedule();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = '対戦表を採用できませんでした: $e';
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

  void _handleMenu(_ScheduleMenuAction action) {
    switch (action) {
      case _ScheduleMenuAction.top:
        _goTop();
        break;
      case _ScheduleMenuAction.list:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EventListPage()),
        );
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

  Widget _buildScheduleBody() {
    return ListView(
      padding: const EdgeInsets.all(4),
      children: [
        ScheduleEventSummaryCard(
          onCopyShareUrl: _savedEvent == null ? null : _copyShareUrl,
          onRefresh: _reloadSchedule,
          canRefresh: _generatedScheduleId != null,
        ),
        const SizedBox(height: 12),
        SchedulePlayersCard(
          title:
              '面数: ${widget.draft.courts}　　参加者: ${widget.draft.playerCount}人',
          players: _playerViewModels,
          selectedPlayerId: _selectedPlayerId,
          onPlayerSelected: _toggleSelectedPlayer,
        ),
        if (!_hasAdoptedSchedule) ...[
          const SizedBox(height: 12),
          ScheduleSectionCard(
            child: ScheduleActionButtons(
              isLoading: _isLoading,
              isAdopting: _isAdopting,
              generateButtonLabel: _generateButtonLabel,
              canAdopt:
                  _generatedScheduleId != null && _scheduleResponse != null,
              onGenerate: _requestGenerateSchedule,
              onAdopt: _adoptSchedule,
            ),
          ),
        ],
        const SizedBox(height: 12),
        ScheduleSectionCard(
          title: '対戦表',
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
                  courtCount: widget.draft.courts,
                  selectedParticipantId: _selectedPlayerId,
                  onParticipantSelected: _toggleSelectedPlayer,
                ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 12),
          ScheduleSectionCard(
            title: 'エラー',
            child: Text(_errorMessage!),
          ),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final showInitialLoading = _isLoading && _scheduleResponse == null;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(widget.draft.eventName),
        actions: [
          PopupMenuButton<_ScheduleMenuAction>(
            onSelected: _handleMenu,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _ScheduleMenuAction.top,
                child: Text('TOPへ'),
              ),
              PopupMenuItem(
                value: _ScheduleMenuAction.list,
                child: Text('対戦表一覧'),
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
