import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

class TeamParticipantNameInputCard extends StatefulWidget {
  const TeamParticipantNameInputCard({
    super.key,
    required this.participantNames,
    required this.participantCount,
    required this.maxParticipantCount,
    required this.onApply,
  });

  final List<String> participantNames;
  final int participantCount;
  final int maxParticipantCount;
  final ValueChanged<List<String>> onApply;

  @override
  State<TeamParticipantNameInputCard> createState() =>
      _TeamParticipantNameInputCardState();
}

class _TeamParticipantNameInputCardState
    extends State<TeamParticipantNameInputCard> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.participantNames.join('\n'),
    );
  }

  @override
  void didUpdateWidget(covariant TeamParticipantNameInputCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.participantNames != widget.participantNames) {
      final nextText = widget.participantNames.join('\n');
      if (_controller.text != nextText) {
        _controller.text = nextText;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> _parseParticipantNames(String rawText) {
    final normalizedText = rawText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final hasNewLine = normalizedText.contains('\n');
    final hasComma = normalizedText.contains(',') || normalizedText.contains('、');
    final hasTab = normalizedText.contains('\t');

    final separator = hasNewLine
        ? RegExp(r'\n+')
        : hasComma
            ? RegExp(r'[,、]+')
            : hasTab
                ? RegExp(r'\t+')
                : RegExp(r'\n+');

    return normalizedText
        .split(separator)
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .take(widget.maxParticipantCount)
        .toList(growable: false);
  }

  int _parsedCountBeforeLimit(String rawText) {
    final normalizedText = rawText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final hasNewLine = normalizedText.contains('\n');
    final hasComma = normalizedText.contains(',') || normalizedText.contains('、');
    final hasTab = normalizedText.contains('\t');

    final separator = hasNewLine
        ? RegExp(r'\n+')
        : hasComma
            ? RegExp(r'[,、]+')
            : hasTab
                ? RegExp(r'\t+')
                : RegExp(r'\n+');

    return normalizedText
        .split(separator)
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .length;
  }

  void _applyParticipantNames() {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final rawText = _controller.text;
    final parsedCountBeforeLimit = _parsedCountBeforeLimit(rawText);
    final names = _parseParticipantNames(rawText);

    messenger.hideCurrentSnackBar();

    if (rawText.trim().isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.participantNamesEmptyMessage)),
      );
      return;
    }

    if (names.length < 2) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.participantNamesTooFewMessage)),
      );
      return;
    }

    widget.onApply(names);

    final message = parsedCountBeforeLimit > widget.maxParticipantCount
        ? l10n.participantNamesTrimmedMessage(widget.maxParticipantCount)
        : l10n.participantNamesAppliedMessage(names.length);

    messenger.showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.teamParticipantInputTitle,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(l10n.teamParticipantInputDescription),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.multiline,
              minLines: 4,
              maxLines: 8,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: l10n.teamParticipantInputLabel,
                hintText: l10n.teamParticipantInputHint,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.participantNameCountStatus(
                widget.participantNames.length,
                widget.participantCount,
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: _applyParticipantNames,
                child: Text(l10n.applyParticipantNamesButton),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
