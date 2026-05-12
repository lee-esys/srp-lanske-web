import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srp_lanske/shared/config/app_config.dart';
import 'package:srp_lanske/shared/repositories/app_repositories.dart';

import '../application/generated_schedule_service.dart';
import '../domain/saved_event_models.dart';
import '../infrastructure/generated_schedule_api_client.dart';
import 'models/event_draft.dart';
import 'event_list_page.dart';

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

  Map<String, String> get _playerNameById {
    return {
      for (final participant in widget.draft.participants)
        participant.id: participant.displayName,
    };
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
        _errorMessage = e.toString();
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
    final generatedScheduleId = _generatedScheduleId;
    if (generatedScheduleId == null || generatedScheduleId.isEmpty) {
      _showMessage('再取得する generated_schedule_id がありません');
      return;
    }

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
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
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

    if (_isAdopting) return;

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
      List<int> slots, Map<int, String> slotToPlayerId) {
    if (slots.isEmpty) return '-';

    return slots
        .map((slot) => '$slot: ${_playerLabelFromSlot(slot, slotToPlayerId)}')
        .join(' / ');
  }

  String _formatRestPlayersBySlots(
      List<int> slotNumbers, Map<int, String> slotToPlayerId) {
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
    return _buildSectionCard(
      title: '入力内容',
      child: Wrap(
        spacing: 16,
        runSpacing: 8,
        children: [
          Text('イベント名: ${widget.draft.eventName}'),
          Text('面数: ${widget.draft.courts}'),
          Text('人数: ${widget.draft.players}'),
          if (_savedEvent != null) Text('共有ID: ${_savedEvent!.event.publicId}'),
          if (_savedEvent != null)
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
    return _buildSectionCard(
      title: '参加者',
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: widget.draft.participants.asMap().entries.map((entry) {
          final index = entry.key;
          final participant = entry.value;

          return Chip(
            label: Text('${index + 1}: ${participant.displayName}'),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton.icon(
          onPressed: _isLoading ? null : _generateSchedule,
          icon: const Icon(Icons.refresh),
          label: const Text('再生成'),
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
                  _isAdopted)
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
                        // const SizedBox(height: 2),
                        // Text(
                        //   '${team1Slots.join(" / ")}  vs  ${team2Slots.join(" / ")}',
                        //   style: Theme.of(context).textTheme.bodySmall,
                        // ),
                      ],
                    ),
                  );
                }),
                const Divider(),
                Text(
                    '休憩: ${_formatRestPlayersBySlots(restSlotNumbers, slotToPlayerId)}'),
              ],
            ),
          ),
        );
      }).toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
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
        child: _isLoading && _scheduleResponse == null
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildSummaryCard(),
                  const SizedBox(height: 12),
                  _buildPlayersCard(),
                  const SizedBox(height: 12),
                  _buildSectionCard(
                    title: '操作',
                    child: _buildActionButtons(),
                  ),
                  const SizedBox(height: 12),
                  _buildSectionCard(
                    title: '対戦表',
                    child: _buildScheduleRounds(),
                  ),
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
