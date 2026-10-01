import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';

class EventSetupUrlSection extends StatelessWidget {
  const EventSetupUrlSection({
    super.key,
    required this.controller,
    required this.isLoadingEvent,
    required this.hasUrlInput,
    required this.showUrlError,
    required this.canClearEventUrl,
    required this.canPasteEventUrl,
    required this.canImportEventUrl,
    required this.onChanged,
    required this.onClear,
    required this.onPaste,
    required this.onImport,
    this.importedSourceUrl,
    this.showEventTitleImportWarning = false,
    this.showParticipantDisplayNamesImportWarning = false,
    this.onOpenSourceEvent,
  });

  final TextEditingController controller;
  final bool isLoadingEvent;
  final bool hasUrlInput;
  final bool showUrlError;
  final bool canClearEventUrl;
  final bool canPasteEventUrl;
  final bool canImportEventUrl;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onPaste;
  final VoidCallback onImport;
  final String? importedSourceUrl;
  final bool showEventTitleImportWarning;
  final bool showParticipantDisplayNamesImportWarning;
  final VoidCallback? onOpenSourceEvent;

  bool get _hasImportFeedback {
    final sourceUrl = importedSourceUrl?.trim() ?? '';
    return sourceUrl.isNotEmpty ||
        showEventTitleImportWarning ||
        showParticipantDisplayNamesImportWarning;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final sourceUrl = importedSourceUrl?.trim() ?? '';
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          enabled: !isLoadingEvent,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: l10n.tennisbearEventUrlLabel,
            helperText: l10n.tennisbearEventUrlHelper,
            errorText: showUrlError ? l10n.tennisbearEventUrlError : null,
            border: const OutlineInputBorder(),
            suffixIcon: hasUrlInput
                ? IconButton(
                    tooltip: l10n.clearUrlTooltip,
                    onPressed: canClearEventUrl ? onClear : null,
                    icon: const Icon(Icons.cancel_outlined),
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: canPasteEventUrl ? onPaste : null,
                icon: const Icon(Icons.content_paste),
                label: Text(l10n.pasteButton),
              ),
              FilledButton.icon(
                onPressed: canImportEventUrl ? onImport : null,
                icon: const Icon(Icons.download),
                label: Text(l10n.importButton),
              ),
            ],
          ),
        ),
        if (_hasImportFeedback) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              border: Border.all(color: colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showEventTitleImportWarning)
                  _ImportWarningRow(
                    text: l10n.tennisbearEventTitleImportFailedWarning,
                  ),
                if (showParticipantDisplayNamesImportWarning) ...[
                  if (showEventTitleImportWarning) const SizedBox(height: 4),
                  _ImportWarningRow(
                    text:
                        l10n.tennisbearParticipantDisplayNamesImportFailedWarning,
                  ),
                ],
                if (sourceUrl.isNotEmpty && onOpenSourceEvent != null) ...[
                  if (showEventTitleImportWarning ||
                      showParticipantDisplayNamesImportWarning)
                    const SizedBox(height: 4),
                  TextButton.icon(
                    key: const ValueKey('open-tennisbear-source-event-button'),
                    onPressed: onOpenSourceEvent,
                    icon: const Icon(Icons.open_in_new),
                    label: Text(l10n.openTennisbearEventButton),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ImportWarningRow extends StatelessWidget {
  const _ImportWarningRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.warning_amber_rounded,
          size: 20,
          color: colorScheme.error,
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.error,
                ),
          ),
        ),
      ],
    );
  }
}
