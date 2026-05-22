import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:srp_lanske/app/config/app_config.dart';
import 'package:srp_lanske/l10n/l10n.dart';
import 'package:srp_lanske/shared/utils/number_label_mapper.dart';

import '../application/tennisbear_event_url.dart';
import '../domain/player_draft.dart';
import '../infrastructure/tennisbear_import_preview_api_client.dart';
import 'event_list_page.dart';
import 'models/event_draft.dart';
import 'schedule_page.dart';
import 'widgets/event_setup_detail_section.dart';
import 'widgets/event_setup_stepper_field.dart';
import 'widgets/event_setup_url_section.dart';

class EventSetupPage extends StatefulWidget {
  // TODO: 編集時の initialDraft 対応
  const EventSetupPage({super.key});

  @override
  State<EventSetupPage> createState() => _EventSetupPageState();
}

enum _EventSetupMenuAction { list }

class _EventSetupPageState extends State<EventSetupPage> {
  final _formKey = GlobalKey<FormState>();

  final _urlController = TextEditingController();
  final _courtsController = TextEditingController(text: '1');
  final _playerCountController = TextEditingController(text: '6');
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

  static const _minCourts = 1;
  static const _maxCourts = 2;

  int get _minPlayerCount => _courts * 4;
  int get _maxPlayerCount => _maxPlayerCountForCourts(_courts);

  int _maxPlayerCountForCourts(int courts) => courts * 8 - 1;

  bool get _hasUrlInput => _urlController.text.trim().isNotEmpty;

  TennisbearEventUrl? get _parsedTennisbearEventUrl {
    return parseTennisbearEventUrl(_urlController.text);
  }

  bool get _isValidTennisbearEventUrl {
    return _parsedTennisbearEventUrl != null;
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

  bool get _canRemovePlayer => _displayNameControllers.length > _minPlayerCount;

  @override
  void initState() {
    super.initState();

    _tennisbearImportPreviewClient = TennisbearImportPreviewApiClient(
      baseUrl: AppConfig.coreApiBaseUrl,
    );

    _syncPlayerCountWithinRange(resetToDefault: true);
    _syncDisplayNameControllers();
  }

  @override
  void dispose() {
    _urlController.dispose();
    _courtsController.dispose();
    _playerCountController.dispose();
    _eventNameController.dispose();

    for (final controller in _displayNameControllers) {
      controller.dispose();
    }
    for (final node in _displayNameFocusNodes) {
      node.dispose();
    }

    super.dispose();
  }

  void _handleMenu(_EventSetupMenuAction action) {
    switch (action) {
      case _EventSetupMenuAction.list:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const EventListPage()),
        );
        break;
    }
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

  void _syncPlayerCountWithinRange({bool resetToDefault = false}) {
    final defaultPlayerCount = (_courts * 4) + 2;
    final currentPlayerCount = int.tryParse(_playerCountController.text);

    int nextPlayerCount;
    if (resetToDefault || currentPlayerCount == null) {
      nextPlayerCount = defaultPlayerCount;
    } else {
      nextPlayerCount =
          currentPlayerCount.clamp(_minPlayerCount, _maxPlayerCount);
    }

    _playerCountController.text = nextPlayerCount.toString();
  }

  void _syncDisplayNameControllers() {
    final playerCount =
        int.tryParse(_playerCountController.text) ?? _minPlayerCount;

    while (_displayNameControllers.length < playerCount) {
      final index = _displayNameControllers.length;
      final defaultName = circledNumber(index + 1);

      final controller = TextEditingController(text: defaultName);
      final focusNode = FocusNode();

      _defaultDisplayNames.add(defaultName);
      _sourceDisplayNames.add(defaultName);

      focusNode.addListener(() {
        final currentIndex = _displayNameFocusNodes.indexOf(focusNode);
        if (currentIndex < 0) return;
        if (currentIndex >= _displayNameControllers.length) return;

        final controller = _displayNameControllers[currentIndex];
        final currentDefault = _defaultDisplayNames[currentIndex];

        if (focusNode.hasFocus) {
          if (controller.text == currentDefault) {
            controller.clear();
          }
          return;
        }

        if (controller.text.trim().isEmpty) {
          final fallback = _sourceDisplayNames[currentIndex];
          controller.text = (fallback != null && fallback.isNotEmpty)
              ? fallback
              : currentDefault;
        }
      });

      _displayNameControllers.add(controller);
      _displayNameFocusNodes.add(focusNode);
    }

    while (_displayNameControllers.length > playerCount) {
      _displayNameControllers.removeLast().dispose();
      _displayNameFocusNodes.removeLast().dispose();
      _defaultDisplayNames.removeLast();
      _sourceDisplayNames.removeLast();
    }

    _refreshManualDisplayNameDefaults();
  }

  void _setCourts(int value, {bool resetPlayerCountToDefault = false}) {
    final clamped = value.clamp(_minCourts, _maxCourts);
    setState(() {
      _courts = clamped;
      _syncCourtsController();
      _syncPlayerCountWithinRange(resetToDefault: resetPlayerCountToDefault);
      _syncDisplayNameControllers();
    });
  }

  void _setPlayerCount(int value) {
    final clamped = value.clamp(_minPlayerCount, _maxPlayerCount);
    setState(() {
      _playerCountController.text = clamped.toString();
      _syncDisplayNameControllers();
    });
  }

  void _removePlayerAt(int index) {
    if (!_canRemovePlayer) return;
    if (index < 0 || index >= _displayNameControllers.length) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _displayNameControllers.removeAt(index).dispose();
      _displayNameFocusNodes.removeAt(index).dispose();
      _defaultDisplayNames.removeAt(index);
      _sourceDisplayNames.removeAt(index);

      _playerCountController.text = _displayNameControllers.length.toString();
      _refreshManualDisplayNameDefaults();
    });
  }

  void _refreshManualDisplayNameDefaults() {
    if (_loadedFromUrl) return;

    for (var i = 0; i < _displayNameControllers.length; i++) {
      final previousDefault = _defaultDisplayNames[i];
      final previousSource = _sourceDisplayNames[i];
      final currentText = _displayNameControllers[i].text.trim();
      final nextDefault = circledNumber(i + 1);

      _defaultDisplayNames[i] = nextDefault;
      _sourceDisplayNames[i] = nextDefault;

      if (currentText.isEmpty ||
          currentText == previousDefault ||
          currentText == previousSource) {
        _displayNameControllers[i].text = nextDefault;
      }
    }
  }

  void _decrementCourts() =>
      _setCourts(_courts - 1, resetPlayerCountToDefault: true);
  void _incrementCourts() =>
      _setCourts(_courts + 1, resetPlayerCountToDefault: true);

  void _decrementPlayerCount() {
    final currentPlayerCount =
        int.tryParse(_playerCountController.text) ?? _minPlayerCount;
    _setPlayerCount(currentPlayerCount - 1);
  }

  void _incrementPlayerCount() {
    final currentPlayerCount =
        int.tryParse(_playerCountController.text) ?? _minPlayerCount;
    _setPlayerCount(currentPlayerCount + 1);
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
      _syncPlayerCountWithinRange(resetToDefault: true);
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

    final players = displayNames
        .map((name) => PlayerDraft.create(displayName: name))
        .toList(growable: false);

    final draft = EventDraft(
      url: _urlController.text.trim(),
      courts: _courts,
      eventName: eventName,
      players: players,
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

    final l10n = AppLocalizations.of(context);

    FocusScope.of(context).unfocus();

    final originalUrl = _urlController.text.trim();
    final parsedUrl = parseTennisbearEventUrl(originalUrl);
    if (originalUrl.isEmpty) {
      _showMessage(l10n.enterUrlMessage);
      return;
    }

    if (parsedUrl == null) {
      _showMessage(l10n.enterTennisbearEventUrlMessage);
      return;
    }

    setState(() {
      _isLoadingEvent = true;
    });

    final startedAt = DateTime.now();

    try {
      final preview = await _tennisbearImportPreviewClient.preview(
        sourceUrl: parsedUrl.canonicalUrl,
      );

      final elapsed = DateTime.now().difference(startedAt);
      const minLoading = Duration(milliseconds: 500);
      if (elapsed < minLoading) {
        await Future.delayed(minLoading - elapsed);
      }

      if (!mounted) return;

      final playerDisplayNames = _playerDisplayNamesFromPreview(preview);
      final playerCount = playerDisplayNames.isNotEmpty
          ? playerDisplayNames.length
          : (preview.participantSummary?.currentCount ?? 0);

      setState(() {
        _loadedFromUrl = true;
        _isUrlImportCompleted = true;
        _importedSourceUrl = originalUrl;

        if (playerCount > 0) {
          _courts = _inferCourtsForPlayerCount(playerCount);
        }

        final eventCourtCount = preview.eventCandidate?.courtCount ?? 0;
        if (eventCourtCount > 0) {
          _courts = eventCourtCount.clamp(_minCourts, _maxCourts);
        }

        _syncCourtsController();

        if (playerCount > 0) {
          _playerCountController.text =
              playerCount.clamp(_minPlayerCount, _maxPlayerCount).toString();
        }

        _syncDisplayNameControllers();

        _eventNameController.text = _eventNameFromPreview(preview);

        for (var i = 0; i < _displayNameControllers.length; i++) {
          final fallback = circledNumber(i + 1);
          final name =
              i < playerDisplayNames.length ? playerDisplayNames[i] : fallback;

          _sourceDisplayNames[i] = name;
          _defaultDisplayNames[i] = name;
          _displayNameControllers[i].text = name;
        }
      });

      final warnings = preview.warnings;
      if (warnings.isEmpty) {
        _showMessage(l10n.eventInfoLoadedMessage);
      } else {
        _showMessage(l10n.eventInfoPartiallyLoadedMessage);
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
      _showMessage(l10n.eventInfoLoadFailedMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingEvent = false;
        });
      }
    }
  }

  int _inferCourtsForPlayerCount(int playerCount) {
    final eventCourts = _courts;

    if (playerCount >= _minPlayerCount && playerCount <= _maxPlayerCount) {
      return eventCourts;
    }

    for (var courts = _minCourts; courts <= _maxCourts; courts++) {
      final minPlayerCount = courts * 4;
      final maxPlayerCount = _maxPlayerCountForCourts(courts);

      if (playerCount >= minPlayerCount && playerCount <= maxPlayerCount) {
        return courts;
      }
    }

    return eventCourts;
  }

  List<String> _playerDisplayNamesFromPreview(
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

    final l10n = AppLocalizations.of(context);

    final data = await Clipboard.getData('text/plain');
    final text = data?.text?.trim() ?? '';

    if (text.isEmpty) {
      _showMessage(l10n.clipboardUrlNotFoundMessage);
      return;
    }

    setState(() {
      _isUrlImportCompleted = false;
      _importedSourceUrl = null;
      _loadedFromUrl = false;

      _urlController.text = text;
      _urlController.selection = TextSelection.collapsed(offset: text.length);
    });

    if (parseTennisbearEventUrl(text) == null) {
      _showMessage(l10n.pasteTennisbearEventUrlMessage);
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final urlText = _urlController.text.trim();
    final showUrlError = urlText.isNotEmpty && !_isValidTennisbearEventUrl;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.eventSetupTitle),
        actions: [
          PopupMenuButton<_EventSetupMenuAction>(
            onSelected: _handleMenu,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _EventSetupMenuAction.list,
                child: Text(l10n.matchTableList),
              ),
            ],
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
                      Text(
                        l10n.eventSetupInstruction,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.eventSetupSupportedConditions,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),
                      EventSetupUrlSection(
                        controller: _urlController,
                        isLoadingEvent: _isLoadingEvent,
                        hasUrlInput: _hasUrlInput,
                        showUrlError: showUrlError,
                        canClearEventUrl: _canClearEventUrl,
                        canPasteEventUrl: _canPasteEventUrl,
                        canImportEventUrl: _canImportEventUrl,
                        onChanged: _handleUrlChanged,
                        onClear: _clearEventUrl,
                        onPaste: _pasteEventUrl,
                        onImport: _fetchEventInfo,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          EventSetupStepperField(
                            label: l10n.courtCountLabel,
                            controller: _courtsController,
                            isLoadingEvent: _isLoadingEvent,
                            onDecrement: _decrementCourts,
                            onIncrement: _incrementCourts,
                            tooltipDecrement: l10n.decrementCourtCountTooltip,
                            tooltipIncrement: l10n.incrementCourtCountTooltip,
                          ),
                          const SizedBox(width: 12),
                          EventSetupStepperField(
                            label: l10n.playerCountLabel,
                            controller: _playerCountController,
                            isLoadingEvent: _isLoadingEvent,
                            onDecrement: _decrementPlayerCount,
                            onIncrement: _incrementPlayerCount,
                            tooltipDecrement: l10n.decrementPlayerCountTooltip,
                            tooltipIncrement: l10n.incrementPlayerCountTooltip,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.playerCountRangeHelp(
                          _minPlayerCount,
                          _maxPlayerCount,
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 24),
                      EventSetupDetailSection(
                        eventNameController: _eventNameController,
                        displayNameControllers: _displayNameControllers,
                        displayNameFocusNodes: _displayNameFocusNodes,
                        sourceDisplayNames: _sourceDisplayNames,
                        isLoadingEvent: _isLoadingEvent,
                        onReset: _resetInputs,
                        onSubmit: _submitForm,
                        canRemovePlayer: _canRemovePlayer,
                        onRemovePlayer: _removePlayerAt,
                      ),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ),
            if (_isLoadingEvent)
              Positioned.fill(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(l10n.loadingEventInfo),
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
