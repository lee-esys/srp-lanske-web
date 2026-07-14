import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

class TeamParticipantNameInputCard extends StatefulWidget {
  const TeamParticipantNameInputCard({
    super.key,
    required this.participantNames,
    required this.participantCount,
    required this.maxParticipantCount,
    required this.onApply,
    this.expandToFillHeight = false,
  });

  final List<String> participantNames;
  final int participantCount;
  final int maxParticipantCount;
  final ValueChanged<List<String>> onApply;
  final bool expandToFillHeight;

  @override
  State<TeamParticipantNameInputCard> createState() =>
      _TeamParticipantNameInputCardState();
}

class _TeamParticipantNameInputCardState
    extends State<TeamParticipantNameInputCard> {
  late final TextEditingController _controller;
  late List<String> _appliedParticipantNames;
  late int _appliedParticipantCount;
  String? _statusMessage;
  bool _isStatusError = false;

  @override
  void initState() {
    super.initState();
    _appliedParticipantNames = widget.participantNames;
    _appliedParticipantCount = widget.participantCount;
    _controller = TextEditingController(
      text: widget.participantNames.join('\n'),
    );
  }

  @override
  void didUpdateWidget(covariant TeamParticipantNameInputCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.participantNames != widget.participantNames) {
      _appliedParticipantNames = widget.participantNames;
      final nextText = widget.participantNames.join('\n');
      if (_controller.text != nextText) {
        _controller.text = nextText;
      }
    }

    if (oldWidget.participantCount != widget.participantCount) {
      _appliedParticipantCount = widget.participantCount;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<String> _parseParticipantNames(String rawText) {
    final normalizedText =
        rawText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final hasNewLine = normalizedText.contains('\n');
    final hasComma =
        normalizedText.contains(',') || normalizedText.contains('、');
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
    final normalizedText =
        rawText.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final hasNewLine = normalizedText.contains('\n');
    final hasComma =
        normalizedText.contains(',') || normalizedText.contains('、');
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
    final rawText = _controller.text;
    final parsedCountBeforeLimit = _parsedCountBeforeLimit(rawText);
    final names = _parseParticipantNames(rawText);

    if (rawText.trim().isEmpty) {
      setState(() {
        _statusMessage = l10n.participantNamesEmptyMessage;
        _isStatusError = true;
      });
      return;
    }

    if (names.length < 2) {
      setState(() {
        _statusMessage = l10n.participantNamesTooFewMessage;
        _isStatusError = true;
      });
      return;
    }

    widget.onApply(names);

    final message = parsedCountBeforeLimit > widget.maxParticipantCount
        ? l10n.participantNamesTrimmedMessage(widget.maxParticipantCount)
        : l10n.participantNamesAppliedMessage(names.length);

    setState(() {
      _appliedParticipantNames = names;
      _appliedParticipantCount = names.length;
      _statusMessage = message;
      _isStatusError = false;
    });
  }

  String _participantInputTitle(AppLocalizations l10n) {
    if (l10n.localeName.startsWith('ja')) {
      return '参加者入力';
    }

    return l10n.teamParticipantInputTitle;
  }

  Widget _buildTextField(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return TextField(
      controller: _controller,
      keyboardType: TextInputType.multiline,
      minLines: 10,
      maxLines: 10,
      expands: false,
      textAlignVertical: TextAlignVertical.top,
      decoration: InputDecoration(
        border: const OutlineInputBorder(),
        labelText: l10n.teamParticipantInputLabel,
        hintText: l10n.teamParticipantInputHint,
        alignLabelWithHint: true,
      ),
    );
  }

  Widget _buildStatusMessage(BuildContext context) {
    final message = _statusMessage;
    if (message == null || message.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Text(
      message,
      style: theme.textTheme.bodySmall?.copyWith(
        color: _isStatusError ? theme.colorScheme.error : theme.colorScheme.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textField = _buildTextField(context);

    return Card(
      elevation: 0,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _participantInputTitle(l10n),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(l10n.teamParticipantInputDescription),
            const SizedBox(height: 12),
            if (widget.expandToFillHeight)
              Expanded(child: textField)
            else
              textField,
            const SizedBox(height: 8),
            Text(
              l10n.participantNameCountStatus(
                _appliedParticipantNames.length,
                _appliedParticipantCount,
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (_statusMessage != null) ...[
              const SizedBox(height: 4),
              _buildStatusMessage(context),
            ],
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
