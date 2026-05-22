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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
      ],
    );
  }
}
