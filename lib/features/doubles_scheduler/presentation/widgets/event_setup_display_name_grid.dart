import 'package:flutter/material.dart';
import 'package:srp_lanske/l10n/l10n.dart';
import 'package:srp_lanske/shared/utils/number_label_mapper.dart';

class EventSetupDisplayNameGrid extends StatelessWidget {
  const EventSetupDisplayNameGrid({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.sourceDisplayNames,
    required this.isLoadingEvent,
    required this.canRemovePlayer,
    required this.onRemovePlayer,
  });

  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final List<String?> sourceDisplayNames;
  final bool isLoadingEvent;
  final bool canRemovePlayer;
  final ValueChanged<int> onRemovePlayer;

  static const _horizontalPadding = 10.0;
  static const _itemSpacing = 20.0;
  static const _runSpacing = 12.0;
  static const _maxItemWidth = 300.0;

  int _columnCountForWidth(double width) {
    if (width >= 720) return 4;
    if (width >= 540) return 3;
    if (width >= 360) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final columnCount = _columnCountForWidth(maxWidth);
        final availableWidth = maxWidth - (_horizontalPadding * 2);
        final itemWidth =
            ((availableWidth - (_itemSpacing * (columnCount - 1))) /
                    columnCount)
                .clamp(0.0, _maxItemWidth)
                .toDouble();
        final gridWidth =
            itemWidth * columnCount + _itemSpacing * (columnCount - 1);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: _horizontalPadding),
          child: Align(
            alignment: Alignment.center,
            child: SizedBox(
              width: gridWidth,
              child: Wrap(
                alignment: WrapAlignment.start,
                spacing: _itemSpacing,
                runSpacing: _runSpacing,
                children: List.generate(controllers.length, (index) {
                  final sourceName =
                      sourceDisplayNames[index] ?? circledNumber(index + 1);

                  return SizedBox(
                    width: itemWidth,
                    child: TextFormField(
                      controller: controllers[index],
                      focusNode: focusNodes[index],
                      enabled: !isLoadingEvent,
                      decoration: InputDecoration(
                        labelText: l10n.playerDisplayNameInputLabel(
                          index + 1,
                          sourceName,
                        ),
                        border: const OutlineInputBorder(),
                        isDense: true,
                        suffixIcon: IconButton(
                          tooltip: canRemovePlayer
                              ? l10n.removePlayerTooltip
                              : l10n.cannotRemovePlayerTooltip,
                          onPressed: isLoadingEvent || !canRemovePlayer
                              ? null
                              : () => onRemovePlayer(index),
                          icon: const Icon(Icons.remove_circle_outline),
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                        ),
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }
}
