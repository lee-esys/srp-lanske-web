import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srp_lanske/app/config/app_config.dart';
import 'package:srp_lanske/shared/repositories/app_repositories.dart';

import '../application/generated_schedule_service.dart';
import '../domain/participant_draft.dart';
import '../domain/public_id.dart';
import '../domain/saved_event_models.dart';
import '../infrastructure/generated_schedule_api_client.dart';
import 'models/event_draft.dart';
import 'widgets/schedule_action_buttons.dart';
import 'widgets/schedule_event_summary_card.dart';
import 'widgets/schedule_participants_card.dart';
import 'widgets/schedule_rounds_view.dart';
import 'widgets/schedule_section_card.dart';

class RestoredSchedulePage extends StatefulWidget {
  const RestoredSchedulePage({
    super.key,
    required this.publicId,
  });

  final String publicId;

  @override
  State<RestoredSchedulePage> createState() => _RestoredSchedulePageState();
}

class _RestoredSchedulePageState extends State<RestoredSchedulePage> {
  late final GeneratedScheduleService _service;

  bool _isLoading = true;
  bool _isAdopting = false;
  String? _errorMessage;

  SavedEventAggregate? _savedEvent;
  String? _generatedScheduleId;
  Map<String, dynamic>? _scheduleResponse;

  @override
  void initState() {
    super.initState();

    _service = GeneratedScheduleService(
      GeneratedScheduleApiClient(
        baseUrl: AppConfig.coreApiBaseUrl,
      ),
    );

    _restore();
  }

  bool get _isAdopted => _scheduleResponse?['adopted'] == true;

  bool get _hasAdoptedSchedule {
    return _isAdopted || (_savedEvent?.event.hasAdoptedSchedule ?? false);
  }

  String get _pageTitle {
    return _savedEvent?.event.title ?? '共有対戦表';
  }

  String get _eventStatusLabel {
    final event = _savedEvent?.event;
    if (event == null) return '-';

    if (_hasAdoptedSchedule) {
      return '採用済み';
    }

    final generatedScheduleId = event.displayGeneratedScheduleId;
    if (_isLoading &&
        (generatedScheduleId == null || generatedScheduleId.isEmpty)) {
      return '生成中';
    }

    if (_isLoading) {
      return '処理中';
    }

    if (generatedScheduleId == null || generatedScheduleId.isEmpty) {
      return '未生成';
    }

    if (_scheduleResponse == null && _errorMessage != null) {
      return '取得失敗';
    }

    return '生成済み';
  }

  String get _generateButtonLabel {
    final generatedScheduleId = _savedEvent?.event.displayGeneratedScheduleId;
    return generatedScheduleId == null || generatedScheduleId.isEmpty
        ? '生成'
        : '再生成';
  }

  List<SavedEventParticipant> get _orderedParticipants {
    final participants = _savedEvent?.participants.toList() ?? const [];
    if (participants.isEmpty) return const [];

    return participants.toList()
      ..sort((a, b) => a.orderNo.compareTo(b.orderNo));
  }

  Map<String, String> get _playerNameById {
    return {
      for (final participant in _orderedParticipants)
        participant.id: participant.displayName,
    };
  }

  List<ScheduleParticipantViewModel> get _participantViewModels {
    return _orderedParticipants.map((participant) {
      return ScheduleParticipantViewModel(
        orderNo: participant.orderNo,
        displayName: participant.displayName,
      );
    }).toList(growable: false);
  }

  Future<void> _restore() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final publicId = widget.publicId.trim().toUpperCase();

    if (!isValidPublicId(publicId)) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = '共有URLが正しくありません';
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
          _errorMessage = '対戦表が見つかりません';
          _isLoading = false;
        });
        return;
      }

      final generatedScheduleId = aggregate.event.displayGeneratedScheduleId;

      setState(() {
        _savedEvent = aggregate;
        _generatedScheduleId = generatedScheduleId;
      });

      if (aggregate.participants.isEmpty) {
        setState(() {
          _errorMessage = '参加者情報がありません';
          _isLoading = false;
        });
        return;
      }

      if (generatedScheduleId == null || generatedScheduleId.isEmpty) {
        setState(() {
          _errorMessage = 'まだ対戦表が生成されていません';
          _isLoading = false;
        });
        return;
      }

      await _fetchSchedule(generatedScheduleId);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _savedEvent = null;
        _scheduleResponse = null;
        _generatedScheduleId = null;
        _errorMessage = '共有情報を取得できませんでした: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSchedule(String generatedScheduleId) async {
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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _scheduleResponse = null;
        _errorMessage = '対戦表を取得できませんでした: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _reloadSchedule() async {
    final publicId =
        (_savedEvent?.event.publicId ?? widget.publicId).trim().toUpperCase();

    if (!isValidPublicId(publicId)) {
      _showMessage('共有URLが正しくありません');
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
          _errorMessage = '対戦表が見つかりません';
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
          _errorMessage = 'まだ対戦表が生成されていません';
          _isLoading = false;
        });
        return;
      }

      await _fetchSchedule(generatedScheduleId);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = '共有情報を再取得できませんでした: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _generateSchedule() async {
    final savedEvent = _savedEvent;
    if (savedEvent == null) {
      _showMessage('再生成するイベント情報がありません');
      return;
    }

    if (_hasAdoptedSchedule) {
      _showMessage('採用済みのため再生成できません');
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

        nextSavedEvent = _replaceSavedEvent(savedEvent, updatedEvent);
      }

      if (!mounted) return;

      setState(() {
        _savedEvent = nextSavedEvent;
        _scheduleResponse = response;
        _generatedScheduleId = generatedScheduleId;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = '対戦表を生成できませんでした: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _adoptSchedule() async {
    final savedEvent = _savedEvent;
    final generatedScheduleId = _generatedScheduleId;

    if (savedEvent == null) {
      _showMessage('採用するイベント情報がありません');
      return;
    }

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

  EventDraft _buildDraft(SavedEventAggregate aggregate) {
    return EventDraft(
      url: aggregate.event.sourceUrl ?? '',
      courts: aggregate.event.courtCount,
      eventName: aggregate.event.title,
      participants: _orderedParticipants.map((participant) {
        return ParticipantDraft(
          id: participant.id,
          displayName: participant.displayName,
        );
      }).toList(growable: false),
    );
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

  String _buildShareUrl() {
    final publicId = _savedEvent?.event.publicId ?? widget.publicId;

    return Uri.base.replace(
      queryParameters: {
        ...Uri.base.queryParameters,
        'sid': publicId,
      },
    ).toString();
  }

  Future<void> _copyShareUrl() async {
    await Clipboard.setData(ClipboardData(text: _buildShareUrl()));
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

  Widget _buildScheduleBody() {
    final savedEvent = _savedEvent;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (savedEvent == null)
          ScheduleSectionCard(
            title: '共有URL',
            child: Text('共有ID: ${widget.publicId}'),
          )
        else ...[
          ScheduleEventSummaryCard(
            eventName: savedEvent.event.title,
            courtCount: savedEvent.event.courtCount,
            participantCount: savedEvent.participants.length,
            publicId: savedEvent.event.publicId,
            statusLabel: _eventStatusLabel,
            onCopyShareUrl: _copyShareUrl,
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
              canAdopt:
                  _generatedScheduleId != null && _scheduleResponse != null,
              onGenerate: _generateSchedule,
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
        ],
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
    final showInitialLoading = _isLoading && _savedEvent == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitle),
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
