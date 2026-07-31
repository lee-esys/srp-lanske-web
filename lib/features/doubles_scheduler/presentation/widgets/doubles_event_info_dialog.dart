import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

import '../../application/event_repository.dart';
import '../../domain/saved_event_models.dart';

class DoublesEventInfoDialog extends StatefulWidget {
  const DoublesEventInfoDialog({
    super.key,
    required this.initialAggregate,
    required this.repository,
  });

  final SavedEventAggregate initialAggregate;
  final EventRepository repository;

  @override
  State<DoublesEventInfoDialog> createState() =>
      _DoublesEventInfoDialogState();
}

class _DoublesEventInfoDialogState extends State<DoublesEventInfoDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _memoController;
  final Map<String, TextEditingController> _playerControllers = {};

  late SavedEventAggregate _latestAggregate;
  late int _expectedRevision;
  bool _isSaving = false;
  bool _showsConflict = false;
  String? _message;

  List<SavedEventPlayer> get _orderedPlayers {
    final players = _latestAggregate.players.toList()
      ..sort((a, b) => a.orderNo.compareTo(b.orderNo));
    return players;
  }

  @override
  void initState() {
    super.initState();
    _latestAggregate = widget.initialAggregate;
    _expectedRevision = widget.initialAggregate.event.revision;
    _titleController = TextEditingController(
      text: widget.initialAggregate.event.title,
    );
    _memoController = TextEditingController(
      text: widget.initialAggregate.event.memo,
    );

    for (final player in widget.initialAggregate.players) {
      _playerControllers[player.id] = TextEditingController(
        text: player.displayName,
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _memoController.dispose();
    for (final controller in _playerControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving || !(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final l10n = AppLocalizations.of(context);
    setState(() {
      _isSaving = true;
      _showsConflict = false;
      _message = null;
    });

    try {
      final updated = await widget.repository.updateDisplayInfo(
        publicId: _latestAggregate.event.publicId,
        expectedRevision: _expectedRevision,
        title: _titleController.text,
        memo: _memoController.text,
        playerDisplayNamesById: {
          for (final player in _orderedPlayers)
            player.id: _playerControllers[player.id]!.text,
        },
      );

      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });
      Navigator.pop(context, updated);
    } on EventRevisionConflictException {
      await _handleConflict(l10n);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _showsConflict = false;
        _message = l10n.doublesEventInfoSaveFailedMessage(error.toString());
      });
    }
  }

  Future<void> _handleConflict(AppLocalizations l10n) async {
    try {
      final latest = await widget.repository.findByPublicId(
        _latestAggregate.event.publicId,
      );
      if (!mounted) return;

      if (latest == null || !_hasSamePlayers(latest)) {
        setState(() {
          _isSaving = false;
          _showsConflict = false;
          _message = l10n.doublesEventInfoLatestLoadFailedMessage;
        });
        return;
      }

      setState(() {
        _latestAggregate = latest;
        _expectedRevision = latest.event.revision;
        _isSaving = false;
        _showsConflict = true;
        _message = l10n.doublesEventInfoConflictMessage;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _showsConflict = false;
        _message = l10n.doublesEventInfoSaveFailedMessage(error.toString());
      });
    }
  }

  bool _hasSamePlayers(SavedEventAggregate latest) {
    final currentIds = _playerControllers.keys.toSet();
    final latestIds = latest.players.map((player) => player.id).toSet();
    return currentIds.length == latestIds.length &&
        currentIds.containsAll(latestIds);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope(
      canPop: !_isSaving,
      child: AlertDialog(
        title: Text(l10n.editDoublesEventInfoDialogTitle),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_message != null) ...[
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: _showsConflict
                            ? colorScheme.tertiaryContainer
                            : colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          _message!,
                          style: TextStyle(
                            color: _showsConflict
                                ? colorScheme.onTertiaryContainer
                                : colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _titleController,
                    enabled: !_isSaving,
                    decoration: InputDecoration(
                      labelText: l10n.doublesEventTitleLabel,
                      border: const OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return l10n.doublesEventTitleRequiredMessage;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _memoController,
                    enabled: !_isSaving,
                    decoration: InputDecoration(
                      labelText: l10n.doublesEventMemoLabel,
                      border: const OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    minLines: 2,
                    maxLines: 4,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    l10n.playerDisplayNameSectionTitle,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  for (final player in _orderedPlayers) ...[
                    TextFormField(
                      key: ValueKey('doubles-player-${player.id}'),
                      controller: _playerControllers[player.id],
                      enabled: !_isSaving,
                      decoration: InputDecoration(
                        labelText: l10n.playerDisplayNameInputLabel(
                          player.orderNo,
                          player.initialDisplayName,
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      textInputAction: player == _orderedPlayers.last
                          ? TextInputAction.done
                          : TextInputAction.next,
                      validator: (value) {
                        if ((value ?? '').trim().isEmpty) {
                          return l10n.doublesPlayerDisplayNameRequiredMessage;
                        }
                        return null;
                      },
                      onFieldSubmitted: (_) {
                        if (player == _orderedPlayers.last) {
                          _save();
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(context),
            child: Text(l10n.cancelButton),
          ),
          FilledButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(l10n.saveButton),
          ),
        ],
      ),
    );
  }
}
