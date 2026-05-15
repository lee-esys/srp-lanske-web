import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srp_lanske/app/config/app_config.dart';
import 'package:srp_lanske/shared/repositories/app_repositories.dart';

import '../application/generated_schedule_service.dart';
import '../domain/saved_event_models.dart';
import '../infrastructure/generated_schedule_api_client.dart';
import 'event_list_page.dart';
import 'models/event_draft.dart';
import 'widgets/schedule_action_buttons.dart';
import 'widgets/schedule_event_summary_card.dart';
import 'widgets/schedule_participants_card.dart';
import 'widgets/schedule_rounds_view.dart';
import 'widgets/schedule_section_card.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key, required this.draft});

  final EventDraft draft;

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

enum _ScheduleMenuAction { edit, list }

class _SchedulePageState extends State<SchedulePage> {
  late final GeneratedScheduleService _service;

  bool _isLoading = true;
  bool _isAdopting = false;
  String? _errorMessage;
  String? _generatedScheduleId;
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

  String get _eventStatusLabel {
    if (_hasAdoptedSchedule) {
      return '採用済み';
    }

    if (_isLoading && _scheduleResponse == null) {
      return '生成中';
    }

    if (_errorMessage != null && _scheduleResponse == null) {
      return '生成失敗';
    }

    final generatedScheduleId =
        _savedEvent?.event.displayGeneratedScheduleId ?? _generatedScheduleId;

    if (generatedScheduleId == null || generatedScheduleId.isEmpty) {
      return '未生成';
    }

    if (_isLoading) {
      return '処理中';
    }

    return '生成済み';
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
      for (final participant in widget.draft.participants)
        participant.id: participant.displayName,
    };
  }

  List<ScheduleParticipantViewModel> get _participantViewModels {
    return widget.draft.participants.asMap().entries.map((entry) {
      return ScheduleParticipantViewModel(
        orderNo: entry.key + 1,
        displayName: entry.value.displayName,
      );
    }).toList(growable: false);
  }

  Future<void> _requestGenerateSchedule() async {
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

    await _generateSchedule();
  }

  Future<SavedEventAggregate> _ensureSavedEvent() async {
    final existing = _savedEvent;
    if (existing != null) return existing;

    final savedEvent = await appEventRepository.createFromDraft(widget.draft);
    _savedEvent = savedEvent;
    return savedEvent;
  }

  SavedEventAggregate _replaceSavedEvent(
    SavedEventAggregate aggregate,
    SavedEvent event,
  ) {
    return SavedEventAggregate(
      event: event,
      participants: aggregate.participants,
      share: aggregate.share,
      importRecord: aggregate.importRecord,
    );
  }

  String? _buildShareUrl() {
    final publicId = _savedEvent?.event.publicId;
    if (publicId == null || publicId.isEmpty) return null;

    return Uri.base.replace(
      queryParameters: {
        ...Uri.base.queryParameters,
        'sid': publicId,
      },
    ).toString();
  }

  Future<void> _copyShareUrl() async {
    final shareUrl = _buildShareUrl();
    if (shareUrl == null) {
      _showMessage('共有URLを作成できませんでした');
      return;
    }

    await Clipboard.setData(ClipboardData(text: shareUrl));
    _showMessage('共有URLをコピーしました');
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

        nextSavedEvent = _replaceSavedEvent(savedEvent, updatedEvent);
      }

      if (!mounted) return;

      setState(() {
        _savedEvent = nextSavedEvent;
        _scheduleResponse = response;
        _generatedScheduleId = generatedScheduleId;
      });
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
    final generatedScheduleId = _generatedScheduleId;
    if (generatedScheduleId == null || generatedScheduleId.isEmpty) {
      _showMessage('採用する generated_schedule_id がありません');
      return;
    }

    if (_isAdopting || _hasAdoptedSchedule) return;

    setState(() {
      _isAdopting = true;
      _errorMessage = null;
    });

    try {
      final savedEvent = await _ensureSavedEvent();

      await _service.adopt(generatedScheduleId);

      final updatedEvent =
          await appEventRepository.updateAdoptedGeneratedScheduleId(
        eventId: savedEvent.event.id,
        generatedScheduleId: generatedScheduleId,
      );

      if (!mounted) return;

      setState(() {
        _savedEvent = _replaceSavedEvent(savedEvent, updatedEvent);
      });

      _showMessage('採用しました');
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

  void _handleMenu(_ScheduleMenuAction action) {
    switch (action) {
      case _ScheduleMenuAction.edit:
        Navigator.pop(context);
        break;
      case _ScheduleMenuAction.list:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EventListPage()),
        );
        break;
    }
  }

  Widget _buildScheduleBody() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ScheduleEventSummaryCard(
          eventName: widget.draft.eventName,
          courtCount: widget.draft.courts,
          participantCount: widget.draft.players,
          publicId: _savedEvent?.event.publicId,
          statusLabel: _eventStatusLabel,
          onCopyShareUrl: _savedEvent == null ? null : _copyShareUrl,
        ),
        const SizedBox(height: 12),
        ScheduleParticipantsCard(
          participants: _participantViewModels,
        ),
        const SizedBox(height: 12),
        ScheduleSectionCard(
          title: '操作',
          child: ScheduleActionButtons(
            hasAdoptedSchedule: _hasAdoptedSchedule,
            isLoading: _isLoading,
            isAdopting: _isAdopting,
            generateButtonLabel: _generateButtonLabel,
            canReload: _generatedScheduleId != null,
            canAdopt: _generatedScheduleId != null && _scheduleResponse != null,
            onGenerate: _requestGenerateSchedule,
            onReload: _reloadSchedule,
            onAdopt: _adoptSchedule,
          ),
        ),
        const SizedBox(height: 12),
        ScheduleSectionCard(
          title: '対戦表',
          child: _isLoading
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                )
              : ScheduleRoundsView(
                  scheduleResponse: _scheduleResponse,
                  playerNameById: _playerNameById,
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
        title: Text(widget.draft.eventName),
        actions: [
          PopupMenuButton<_ScheduleMenuAction>(
            onSelected: _handleMenu,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _ScheduleMenuAction.edit,
                child: Text('このイベントを編集'),
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
