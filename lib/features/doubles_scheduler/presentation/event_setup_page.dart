import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srp_lanske/app/config/app_config.dart';
import 'package:srp_lanske/shared/utils/number_label_mapper.dart';

import '../domain/participant_draft.dart';
import '../infrastructure/tennisbear_import_preview_api_client.dart';
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

  late final TennisbearImportPreviewApiClient _tennisbearImportPreviewClient;

  bool _isLoadingEvent = false;
  bool _loadedFromUrl = false;
  bool _isUrlImportCompleted = false;

  String? _importedSourceUrl;

  int _courts = 1;

  int get _minPlayers => _courts * 4;
  int get _maxPlayers => (_courts * 4) + 10;

  bool get _hasUrlInput => _urlController.text.trim().isNotEmpty;

  bool get _isValidTennisbearEventUrl {
    return _isTennisbearEventUrl(_urlController.text.trim());
  }

  bool get _canPasteEventUrl {
    if (_isLoadingEvent) return false;
    if (_isUrlImportCompleted) return false;
    return !_isValidTennisbearEventUrl;
  }

  bool get _canImportEventUrl {
    if (_isLoadingEvent) return false;
    if (_isUrlImportCompleted) return false;
    return _isValidTennisbearEventUrl;
  }

  bool get _canClearEventUrl {
    if (_isLoadingEvent) return false;
    return _hasUrlInput;
  }

  @override
  void initState() {
    super.initState();

    _tennisbearImportPreviewClient = TennisbearImportPreviewApiClient(
      baseUrl: AppConfig.coreApiBaseUrl,
    );

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
        if (index >= _displayNameControllers.length) return;

        final controller = _displayNameControllers[index];
        final currentDefault = _defaultDisplayNames[index];

        if (focusNode.hasFocus) {
          if (controller.text == currentDefault) {
            controller.clear();
          }
          return;
        }

        if (controller.text.trim().isEmpty) {
          final fallback = _sourceDisplayNames[index];
          controller.text = (fallback != null && fallback.isNotEmpty)
              ? fallback
              : currentDefault;
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
      _isUrlImportCompleted = false;
      _importedSourceUrl = null;

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

    final sourceUrl = _urlController.text.trim();
    if (sourceUrl.isEmpty) {
      _showMessage('URLを入力してください');
      return;
    }

    if (!_isTennisbearEventUrl(sourceUrl)) {
      _showMessage('テニスベアのイベントURLを入力してください');
      return;
    }

    setState(() {
      _isLoadingEvent = true;
    });

    final startedAt = DateTime.now();

    try {
      final preview = await _tennisbearImportPreviewClient.preview(
        sourceUrl: sourceUrl,
      );

      final elapsed = DateTime.now().difference(startedAt);
      const minLoading = Duration(milliseconds: 500);
      if (elapsed < minLoading) {
        await Future.delayed(minLoading - elapsed);
      }

      if (!mounted) return;

      final participantNames = _participantNamesFromPreview(preview);
      final participantCount = participantNames.isNotEmpty
          ? participantNames.length
          : (preview.participantSummary?.currentCount ?? 0);

      setState(() {
        _loadedFromUrl = true;
        _isUrlImportCompleted = true;
        _importedSourceUrl = sourceUrl;

        if (participantCount > 0) {
          _courts = _inferCourtsForPlayers(participantCount);
        }

        final eventCourtCount = preview.eventCandidate?.courtCount ?? 0;
        if (eventCourtCount > 0) {
          _courts = eventCourtCount.clamp(1, 10);
        }

        _syncCourtsController();

        if (participantCount > 0) {
          _playersController.text =
              participantCount.clamp(_minPlayers, _maxPlayers).toString();
        }

        _syncDisplayNameControllers();

        _eventNameController.text = _eventNameFromPreview(preview);

        for (var i = 0; i < _displayNameControllers.length; i++) {
          final fallback = circledNumber(i + 1);
          final name =
              i < participantNames.length ? participantNames[i] : fallback;

          _sourceDisplayNames[i] = name;
          _defaultDisplayNames[i] = name;
          _displayNameControllers[i].text = name;
        }
      });

      final warnings = preview.warnings;
      if (warnings.isEmpty) {
        _showMessage('イベント情報を取得しました');
      } else {
        _showMessage('イベント情報を取得しました（一部情報は取得できませんでした）');
      }
    } on TennisbearImportPreviewApiException catch (e) {
      final elapsed = DateTime.now().difference(startedAt);
      const minLoading = Duration(milliseconds: 500);
      if (elapsed < minLoading) {
        await Future.delayed(minLoading - elapsed);
      }

      if (!mounted) return;
      _showMessage(e.message);
    } catch (_) {
      final elapsed = DateTime.now().difference(startedAt);
      const minLoading = Duration(milliseconds: 500);
      if (elapsed < minLoading) {
        await Future.delayed(minLoading - elapsed);
      }

      if (!mounted) return;
      // TODO: イベント情報取得失敗時のエラーログを送る仕組みができたら、ここで例外内容も送る。adminにメール送信するのもあり。
      _showMessage('取得できませんでした。URLを確認して再度お試しください');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingEvent = false;
        });
      }
    }
  }

  int _inferCourtsForPlayers(int players) {
    final eventCourts = _courts;

    if (players >= eventCourts * 4 && players <= (eventCourts * 4) + 10) {
      return eventCourts;
    }

    for (var courts = 1; courts <= 10; courts++) {
      if (players >= courts * 4 && players <= (courts * 4) + 10) {
        return courts;
      }
    }

    return eventCourts;
  }

  List<String> _participantNamesFromPreview(
    TennisbearImportPreviewResponse preview,
  ) {
    return preview.participantCandidates
        .map((candidate) => candidate.displayName.trim())
        .where((name) => name.isNotEmpty)
        .toList(growable: false);
  }

  String _eventNameFromPreview(TennisbearImportPreviewResponse preview) {
    final title = preview.eventCandidate?.title.trim() ?? '';
    if (title.isNotEmpty) return title;

    return _buildEffectiveEventName();
  }

  bool _isTennisbearEventUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;

    if (uri.scheme != 'https') return false;
    if (uri.host != 'www.tennisbear.net' && uri.host != 'tennisbear.net') {
      return false;
    }

    final segments = uri.pathSegments;
    if (segments.length != 3) return false;
    if (segments[0] != 'event' || segments[2] != 'info') return false;

    return RegExp(r'^\d+$').hasMatch(segments[1]);
  }

  void _handleUrlChanged(String value) {
    final current = value.trim();

    setState(() {
      if (_isUrlImportCompleted && current != _importedSourceUrl) {
        _isUrlImportCompleted = false;
        _importedSourceUrl = null;
        _loadedFromUrl = false;
      }
    });
  }

  Future<void> _pasteEventUrl() async {
    if (!_canPasteEventUrl) return;

    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim() ?? '';

    if (text.isEmpty) {
      _showMessage('クリップボードにURLがありません');
      return;
    }

    setState(() {
      _isUrlImportCompleted = false;
      _importedSourceUrl = null;
      _loadedFromUrl = false;

      _urlController.text = text;
      _urlController.selection = TextSelection.collapsed(offset: text.length);
    });

    if (!_isTennisbearEventUrl(text)) {
      _showMessage('テニスベアのイベントURLを貼り付けてください');
    }
  }

  void _clearEventUrl() {
    if (!_canClearEventUrl) return;

    setState(() {
      _urlController.clear();
      _isUrlImportCompleted = false;
      _importedSourceUrl = null;
      _loadedFromUrl = false;
    });
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
    final urlText = _urlController.text.trim();
    final showUrlError = urlText.isNotEmpty && !_isValidTennisbearEventUrl;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _urlController,
          enabled: !_isLoadingEvent,
          onChanged: _handleUrlChanged,
          decoration: InputDecoration(
            labelText: 'テニスベアのイベントURL',
            helperText: '例: https://www.tennisbear.net/event/1156506/info',
            errorText: showUrlError ? 'テニスベアのイベントURLを入力してください' : null,
            border: const OutlineInputBorder(),
            suffixIcon: _hasUrlInput
                ? IconButton(
                    tooltip: 'URLをクリア',
                    onPressed: _canClearEventUrl ? _clearEventUrl : null,
                    icon: const Icon(Icons.cancel_outlined),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            OutlinedButton.icon(
              onPressed: _canPasteEventUrl ? _pasteEventUrl : null,
              icon: const Icon(Icons.content_paste),
              label: const Text('貼り付け'),
            ),
            FilledButton.icon(
              onPressed: _canImportEventUrl ? _fetchEventInfo : null,
              icon: const Icon(Icons.download),
              label: const Text('取り込み'),
            ),
          ],
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
                    padding: const EdgeInsets.all(4),
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
