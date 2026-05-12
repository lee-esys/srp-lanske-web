import 'package:flutter/material.dart';
import 'package:srp_lanske/shared/utils/number_label_mapper.dart';

import '../domain/participant_draft.dart';
import 'models/event_draft.dart';
import 'schedule_page.dart';

class EventSetupPage extends StatefulWidget {
  // TODO: 編集時の initialDraft 対応
  const EventSetupPage({super.key});

  @override
  State<EventSetupPage> createState() => _EventSetupPageState();
}

class _EventSetupPageState extends State<EventSetupPage> {
  final _formKey = GlobalKey<FormState>();

  final _urlController = TextEditingController();
  final _courtsController = TextEditingController(text: '1');
  final _playersController = TextEditingController(text: '6');
  final _eventNameController = TextEditingController();

  final List<TextEditingController> _displayNameControllers = [];
  final List<FocusNode> _displayNameFocusNodes = [];
  final List<String> _defaultDisplayNames = [];
  final List<String?> _sourceDisplayNames = [];

  bool _isLoadingEvent = false;
  bool _loadedFromUrl = false;

  int _courts = 1;

  int get _minPlayers => _courts * 4;
  int get _maxPlayers => (_courts * 4) + 10;

  @override
  void initState() {
    super.initState();
    _syncPlayersWithinRange(resetToDefault: true);
    _syncDisplayNameControllers();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _courtsController.dispose();
    _playersController.dispose();
    _eventNameController.dispose();

    for (final controller in _displayNameControllers) {
      controller.dispose();
    }
    for (final node in _displayNameFocusNodes) {
      node.dispose();
    }

    super.dispose();
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

  void _syncCourtsController() {
    _courtsController.text = _courts.toString();
  }

  void _syncPlayersWithinRange({bool resetToDefault = false}) {
    final defaultPlayers = (_courts * 4) + 2;
    final current = int.tryParse(_playersController.text);

    int nextPlayers;
    if (resetToDefault || current == null) {
      nextPlayers = defaultPlayers;
    } else {
      nextPlayers = current.clamp(_minPlayers, _maxPlayers);
    }

    _playersController.text = nextPlayers.toString();
  }

  void _syncDisplayNameControllers() {
    final players = int.tryParse(_playersController.text) ?? _minPlayers;

    while (_displayNameControllers.length < players) {
      final index = _displayNameControllers.length;
      final defaultName = circledNumber(index + 1);

      final controller = TextEditingController(text: defaultName);
      final focusNode = FocusNode();

      _defaultDisplayNames.add(defaultName);
      _sourceDisplayNames.add(defaultName);

      focusNode.addListener(() {
        if (!focusNode.hasFocus) return;

        final currentDefault = _defaultDisplayNames[index];
        if (_displayNameControllers[index].text == currentDefault) {
          _displayNameControllers[index].clear();
        }
      });

      _displayNameControllers.add(controller);
      _displayNameFocusNodes.add(focusNode);
    }

    while (_displayNameControllers.length > players) {
      _displayNameControllers.removeLast().dispose();
      _displayNameFocusNodes.removeLast().dispose();
      _defaultDisplayNames.removeLast();
      _sourceDisplayNames.removeLast();
    }

    if (!_loadedFromUrl) {
      for (var i = 0; i < _displayNameControllers.length; i++) {
        final defaultName = circledNumber(i + 1);
        final currentText = _displayNameControllers[i].text.trim();

        _defaultDisplayNames[i] = defaultName;
        _sourceDisplayNames[i] = defaultName;

        if (currentText.isEmpty || currentText == _defaultDisplayNames[i]) {
          _displayNameControllers[i].text = defaultName;
        }
      }
    }
  }

  void _setCourts(int value, {bool resetPlayersToDefault = false}) {
    final clamped = value.clamp(1, 10);
    setState(() {
      _courts = clamped;
      _syncCourtsController();
      _syncPlayersWithinRange(resetToDefault: resetPlayersToDefault);
      _syncDisplayNameControllers();
    });
  }

  void _setPlayers(int value) {
    final clamped = value.clamp(_minPlayers, _maxPlayers);
    setState(() {
      _playersController.text = clamped.toString();
      _syncDisplayNameControllers();
    });
  }

  void _decrementCourts() =>
      _setCourts(_courts - 1, resetPlayersToDefault: true);
  void _incrementCourts() =>
      _setCourts(_courts + 1, resetPlayersToDefault: true);

  void _decrementPlayers() {
    final current = int.tryParse(_playersController.text) ?? _minPlayers;
    _setPlayers(current - 1);
  }

  void _incrementPlayers() {
    final current = int.tryParse(_playersController.text) ?? _minPlayers;
    _setPlayers(current + 1);
  }

  void _resetInputs() {
    FocusScope.of(context).unfocus();

    setState(() {
      _loadedFromUrl = false;
      _courts = 1;

      _urlController.clear();
      _eventNameController.clear();

      _syncCourtsController();
      _syncPlayersWithinRange(resetToDefault: true);
      _syncDisplayNameControllers();

      for (var i = 0; i < _displayNameControllers.length; i++) {
        final defaultName = circledNumber(i + 1);
        _defaultDisplayNames[i] = defaultName;
        _sourceDisplayNames[i] = defaultName;
        _displayNameControllers[i].text = defaultName;
      }
    });
  }

  void _submitForm() {
    FocusScope.of(context).unfocus();

    final eventName = _buildEffectiveEventName();
    final displayNames = _buildEffectiveDisplayNames();

    final participants = displayNames
        .map((name) => ParticipantDraft.create(displayName: name))
        .toList(growable: false);

    final draft = EventDraft(
      url: _urlController.text.trim(),
      courts: _courts,
      eventName: eventName,
      participants: participants,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SchedulePage(draft: draft),
      ),
    );
  }

  Future<void> _fetchEventInfo() async {
    if (_isLoadingEvent) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoadingEvent = true;
    });

    final startedAt = DateTime.now();

    try {
      // TODO: URLからイベント情報を取得するAPI/パーサ処理に置き換える
      final mockFuture = Future<Map<String, dynamic>>.delayed(
        const Duration(milliseconds: 150),
        () => {
          'eventName': 'らんすけ公園庭球場 ${DateTime.now().toIso8601String()}',
          'courts': 1,
          'players': 6,
          'playerNames': ['らん助', 'すけ太', 'もか', 'ゆき', 'はる', 'あお'],
        },
      );

      final mockData = await mockFuture;

      final elapsed = DateTime.now().difference(startedAt);
      const minLoading = Duration(milliseconds: 500);
      if (elapsed < minLoading) {
        await Future.delayed(minLoading - elapsed);
      }

      if (!mounted) return;

      setState(() {
        _loadedFromUrl = true;

        _courts = (mockData['courts'] as int).clamp(1, 10);
        _syncCourtsController();

        final mockPlayers = mockData['players'] as int;
        _playersController.text =
            mockPlayers.clamp(_minPlayers, _maxPlayers).toString();

        _syncDisplayNameControllers();

        _eventNameController.text = mockData['eventName'] as String;

        final mockNames =
            (mockData['playerNames'] as List<dynamic>).cast<String>();
        for (var i = 0; i < _displayNameControllers.length; i++) {
          final fallback = circledNumber(i + 1);
          final name = i < mockNames.length ? mockNames[i] : fallback;

          _sourceDisplayNames[i] = name;
          _defaultDisplayNames[i] = name;
          _displayNameControllers[i].text = name;
        }
      });

      _showMessage('イベント情報を取得しました');
    } catch (_) {
      final elapsed = DateTime.now().difference(startedAt);
      const minLoading = Duration(milliseconds: 500);
      if (elapsed < minLoading) {
        await Future.delayed(minLoading - elapsed);
      }

      if (!mounted) return;
      // TODO: イベント情報取得失敗時のエラーログを送る仕組みができたら、ここで例外内容も送る。adminにメール送信するのもあり。
      _showMessage('イベント情報の取得に失敗しました');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingEvent = false;
        });
      }
    }
  }

  String _formatDateTimeLabel(DateTime dateTime) {
    final y = dateTime.year.toString().padLeft(4, '0');
    final m = dateTime.month.toString().padLeft(2, '0');
    final d = dateTime.day.toString().padLeft(2, '0');
    final hh = dateTime.hour.toString().padLeft(2, '0');
    final mm = dateTime.minute.toString().padLeft(2, '0');

    return '$y/$m/$d $hh:$mm';
  }

  String _buildEffectiveEventName() {
    final raw = _eventNameController.text.trim();
    if (raw.isNotEmpty) return raw;
    return _formatDateTimeLabel(DateTime.now());
  }

  List<String> _buildEffectiveDisplayNames() {
    return List.generate(_displayNameControllers.length, (index) {
      final raw = _displayNameControllers[index].text.trim();
      if (raw.isNotEmpty) return raw;

      final fallback = _sourceDisplayNames[index];
      if (fallback != null && fallback.isNotEmpty) return fallback;

      return circledNumber(index + 1);
    });
  }

  // TODO: 分離・共通化できそうなUI部品は切り出す
  Widget _buildStepperField({
    required String label,
    required TextEditingController controller,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    required String tooltipDecrement,
    required String tooltipIncrement,
  }) {
    return Expanded(
      child: Row(
        children: [
          IconButton(
            onPressed: _isLoadingEvent ? null : onDecrement,
            tooltip: tooltipDecrement,
            icon: const Icon(Icons.remove_circle_outline),
          ),
          Expanded(
            child: SizedBox(
              width: 84,
              child: TextFormField(
                controller: controller,
                readOnly: true,
                enabled: !_isLoadingEvent,
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: label,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: _isLoadingEvent ? null : onIncrement,
            tooltip: tooltipIncrement,
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
    );
  }

  Widget _buildUrlSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _urlController,
          enabled: !_isLoadingEvent,
          decoration: const InputDecoration(
            labelText: 'テニスベア / テニスオフ のイベントURL',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: FilledButton.tonal(
            onPressed: _fetchEventInfo,
            style: FilledButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('イベント情報を取得する'),
          ),
        ),
      ],
    );
  }

  Widget _buildDisplayNameGrid() {
    final items = List.generate(_displayNameControllers.length, (index) {
      final sourceName = _sourceDisplayNames[index] ?? circledNumber(index + 1);
      final labelSuffix = '：$sourceName';

      return TextFormField(
        controller: _displayNameControllers[index],
        focusNode: _displayNameFocusNodes[index],
        enabled: !_isLoadingEvent,
        decoration: InputDecoration(
          labelText: '参加者${participantLabelNumber(index)}$labelSuffix',
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      );
    });

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: List.generate(items.length, (index) {
        return SizedBox(
          width: 140,
          child: items[index],
        );
      }),
    );
  }

  Widget _buildDetailSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32),
        TextFormField(
          controller: _eventNameController,
          enabled: !_isLoadingEvent,
          decoration: const InputDecoration(
            labelText: 'イベント名',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          '参加者表示名',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        _buildDisplayNameGrid(),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FilledButton.tonal(
              onPressed: _isLoadingEvent ? null : _resetInputs,
              style: FilledButton.styleFrom(
                minimumSize: Size.zero,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                '入力項目のリセット',
                style: TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: _isLoadingEvent ? null : _submitForm,
              style: FilledButton.styleFrom(
                minimumSize: Size.zero,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                '対戦表の生成',
                style: TextStyle(fontSize: 22),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('テニス乱数表ジェネレーター'),
        actions: [
          IconButton(
            tooltip: '対戦表一覧',
            onPressed: () {
              // TODO: 対戦表一覧ページへ遷移
            },
            icon: const Icon(Icons.history),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Form(
              key: _formKey,
              child: IgnorePointer(
                ignoring: _isLoadingEvent,
                child: Opacity(
                  opacity: _isLoadingEvent ? 0.5 : 1,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      const Text(
                        'URLを貼るか、手動で面数・人数を入力してください。',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '面数は1〜10まで対応しています。',
                        style: TextStyle(fontSize: 12, color: Colors.black54),
                      ),
                      const SizedBox(height: 16),
                      _buildUrlSection(),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildStepperField(
                            label: '面数',
                            controller: _courtsController,
                            onDecrement: _decrementCourts,
                            onIncrement: _incrementCourts,
                            tooltipDecrement: '面数を減らす',
                            tooltipIncrement: '面数を増やす',
                          ),
                          const SizedBox(width: 12),
                          _buildStepperField(
                            label: '人数',
                            controller: _playersController,
                            onDecrement: _decrementPlayers,
                            onIncrement: _incrementPlayers,
                            tooltipDecrement: '人数を減らす',
                            tooltipIncrement: '人数を増やす',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '人数は $_minPlayers 人以上、$_maxPlayers 人以下で入力してください。',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 24),
                      _buildDetailSection(),
                    ],
                  ),
                ),
              ),
            ),
            if (_isLoadingEvent)
              const Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text('イベント情報を取得中...'),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
