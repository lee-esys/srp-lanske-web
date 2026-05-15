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

    if (event.hasAdoptedSchedule) {
      return '採用済み';
    }

    final generatedScheduleId = event.displayGeneratedScheduleId;
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
    final generatedScheduleId =
        _generatedScheduleId ?? _savedEvent?.event.displayGeneratedScheduleId;

    if (generatedScheduleId == null || generatedScheduleId.isEmpty) {
      _showMessage('再取得する generated_schedule_id がありません');
      return;
    }

    await _fetchSchedule(generatedScheduleId);
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
        _errorMessage = e.toString();
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
        _errorMessage = e.toString();
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

  List<Map<String, dynamic>> _asObjectList(Object? value) {
    if (value is! List) return const [];

    return value
        .whereType<Map>()
        .map((e) => e.map((key, value) => MapEntry(key.toString(), value)))
        .toList(growable: false);
  }

  List<int> _asIntList(Object? value) {
    if (value is! List) return const [];

    return value
        .map((e) {
          if (e is int) return e;
          return int.tryParse(e.toString());
        })
        .whereType<int>()
        .toList(growable: false);
  }

  Map<int, String> _buildSlotToPlayerId() {
    final assignment = _asObjectList(_scheduleResponse?['assignment']);

    return {
      for (final row in assignment)
        if (row['slot_number'] != null && row['player_id'] != null)
          int.parse(row['slot_number'].toString()): row['player_id'].toString(),
    };
  }

  String _playerLabelFromId(String playerId) {
    return _playerNameById[playerId] ?? playerId;
  }

  String _playerLabelFromSlot(int slotNumber, Map<int, String> slotToPlayerId) {
    final playerId = slotToPlayerId[slotNumber];
    if (playerId == null) return 'slot:$slotNumber';
    return _playerLabelFromId(playerId);
  }

  String _formatTeamFromSlots(
    List<int> slots,
    Map<int, String> slotToPlayerId,
  ) {
    if (slots.isEmpty) return '-';

    return slots
        .map((slot) => '$slot: ${_playerLabelFromSlot(slot, slotToPlayerId)}')
        .join(' / ');
  }

  String _formatRestPlayersBySlots(
    List<int> slotNumbers,
    Map<int, String> slotToPlayerId,
  ) {
    if (slotNumbers.isEmpty) return '-';

    return slotNumbers
        .map((slot) => '$slot: ${_playerLabelFromSlot(slot, slotToPlayerId)}')
        .join(' / ');
  }

  Widget _buildSectionCard({
    required String title,
    required Widget child,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final savedEvent = _savedEvent;
    if (savedEvent == null) {
      return _buildSectionCard(
        title: '共有URL',
        child: Text('共有ID: ${widget.publicId}'),
      );
    }

    final event = savedEvent.event;

    return _buildSectionCard(
      title: 'イベント情報',
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('イベント名: ${event.title}'),
          Text('面数: ${event.courtCount}'),
          Text('人数: ${savedEvent.participants.length}'),
          Text('共有ID: ${event.publicId}'),
          Text('状態: $_eventStatusLabel'),
          OutlinedButton.icon(
            onPressed: _copyShareUrl,
            icon: const Icon(Icons.copy),
            label: const Text('共有URLをコピー'),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersCard() {
    final participants = _orderedParticipants;

    if (participants.isEmpty) {
      return _buildSectionCard(
        title: '参加者',
        child: const Text('参加者情報がありません'),
      );
    }

    return _buildSectionCard(
      title: '参加者',
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: participants.map((participant) {
          return Chip(
            label: Text('${participant.orderNo}: ${participant.displayName}'),
          );
        }).toList(growable: false),
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_hasAdoptedSchedule) {
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Chip(
            avatar: Icon(Icons.check),
            label: Text('採用済み'),
          ),
          FilledButton.tonalIcon(
            onPressed: _isLoading ? null : _reloadSchedule,
            icon: const Icon(Icons.download),
            label: const Text('再取得'),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          onPressed: _isLoading ? null : _generateSchedule,
          icon: const Icon(Icons.refresh),
          label: Text(_generateButtonLabel),
        ),
        FilledButton.tonalIcon(
          onPressed: (_isLoading || _generatedScheduleId == null)
              ? null
              : _reloadSchedule,
          icon: const Icon(Icons.download),
          label: const Text('再取得'),
        ),
        FilledButton(
          onPressed: (_isLoading ||
                  _isAdopting ||
                  _generatedScheduleId == null ||
                  _scheduleResponse == null ||
                  _hasAdoptedSchedule)
              ? null
              : _adoptSchedule,
          child: _isAdopting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('採用'),
        ),
      ],
    );
  }

  Widget _buildScheduleRounds() {
    final rounds = _asObjectList(_scheduleResponse?['rounds']);
    final slotToPlayerId = _buildSlotToPlayerId();

    if (_scheduleResponse == null) {
      return const Text('対戦表を取得できていません');
    }

    if (rounds.isEmpty) {
      return const Text('対戦表データがありません');
    }

    return Column(
      children: rounds.map((round) {
        final roundNumber = round['round_number']?.toString() ?? '-';
        final restSlotNumbers = _asIntList(round['rest_slot_numbers']);
        final courts = _asObjectList(round['courts']);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '第$roundNumber試合',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                ...courts.map((court) {
                  final courtNumber = court['court_number']?.toString() ?? '-';
                  final team1Slots = _asIntList(court['team1_player_slots']);
                  final team2Slots = _asIntList(court['team2_player_slots']);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'コート$courtNumber',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_formatTeamFromSlots(team1Slots, slotToPlayerId)}  vs  ${_formatTeamFromSlots(team2Slots, slotToPlayerId)}',
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(),
                Text(
                  '休憩: ${_formatRestPlayersBySlots(restSlotNumbers, slotToPlayerId)}',
                ),
              ],
            ),
          ),
        );
      }).toList(growable: false),
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
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 12),
                  if (_savedEvent != null) ...[
                    _buildPlayersCard(),
                    const SizedBox(height: 12),
                    _buildSectionCard(
                      title: '操作',
                      child: _buildActionButtons(),
                    ),
                    const SizedBox(height: 12),
                    _buildSectionCard(
                      title: '対戦表',
                      child: _isLoading
                          ? const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          : _buildScheduleRounds(),
                    ),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    _buildSectionCard(
                      title: 'エラー',
                      child: Text(_errorMessage!),
                    ),
                  ],
                  const SizedBox(height: 80),
                ],
              ),
      ),
    );
  }
}
