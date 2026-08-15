import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:srp_lanske/l10n/l10n.dart';

class DoublesNavigationMenuHintController {
  VoidCallback? _showHint;

  void attach(VoidCallback showHint) {
    _showHint = showHint;
  }

  void detach(VoidCallback showHint) {
    if (_showHint == showHint) {
      _showHint = null;
    }
  }

  void showHint() {
    _showHint?.call();
  }
}

class DoublesNavigationMenuButton extends StatefulWidget {
  const DoublesNavigationMenuButton({
    super.key,
    required this.onPressed,
    required this.hintController,
  });

  final VoidCallback onPressed;
  final DoublesNavigationMenuHintController hintController;

  @override
  State<DoublesNavigationMenuButton> createState() =>
      _DoublesNavigationMenuButtonState();
}

class _DoublesNavigationMenuButtonState
    extends State<DoublesNavigationMenuButton> {
  static const _hintShownKey = 'lanske_doubles_navigation_menu_hint_v1';
  static const _initialHintDelay = Duration(milliseconds: 700);

  final _tooltipKey = GlobalKey<TooltipState>();
  bool _initialHintScheduled = false;
  Timer? _initialHintTimer;

  @override
  void initState() {
    super.initState();
    widget.hintController.attach(_showHint);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialHintScheduled) return;

    _initialHintScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _initialHintTimer = Timer(_initialHintDelay, () {
        _initialHintTimer = null;
        unawaited(_showInitialHintIfNeeded());
      });
    });
  }

  @override
  void didUpdateWidget(covariant DoublesNavigationMenuButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hintController == widget.hintController) return;

    oldWidget.hintController.detach(_showHint);
    widget.hintController.attach(_showHint);
  }

  @override
  void dispose() {
    _initialHintTimer?.cancel();
    widget.hintController.detach(_showHint);
    super.dispose();
  }

  Future<void> _showInitialHintIfNeeded() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted || prefs.getBool(_hintShownKey) == true) return;

    _showHint();
    await prefs.setBool(_hintShownKey, true);
  }

  void _showHint() {
    if (!mounted) return;
    _tooltipKey.currentState?.ensureTooltipVisible();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Tooltip(
      key: _tooltipKey,
      message: l10n.doublesNavigationMenuTooltip,
      child: IconButton.filledTonal(
        onPressed: widget.onPressed,
        icon: const Icon(Icons.menu),
      ),
    );
  }
}
