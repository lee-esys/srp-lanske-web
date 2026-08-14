import 'package:flutter/material.dart';

class DoublesScrollRefreshAction extends StatefulWidget {
  const DoublesScrollRefreshAction({
    super.key,
    required this.scrollController,
    required this.tooltip,
    required this.isAvailable,
    required this.isRefreshing,
    required this.onPressed,
  });

  final ScrollController scrollController;
  final String tooltip;
  final bool isAvailable;
  final bool isRefreshing;
  final VoidCallback? onPressed;

  @override
  State<DoublesScrollRefreshAction> createState() =>
      _DoublesScrollRefreshActionState();
}

class _DoublesScrollRefreshActionState
    extends State<DoublesScrollRefreshAction> {
  static const _revealViewportFraction = 0.5;
  static const _hideViewportFraction = 0.4;

  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_handleScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateVisibility();
      }
    });
  }

  @override
  void didUpdateWidget(covariant DoublesScrollRefreshAction oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.scrollController, widget.scrollController)) {
      oldWidget.scrollController.removeListener(_handleScroll);
      widget.scrollController.addListener(_handleScroll);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateVisibility();
      }
    });
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_handleScroll);
    super.dispose();
  }

  void _handleScroll() {
    _updateVisibility();
  }

  void _updateVisibility() {
    if (!widget.scrollController.hasClients) {
      _setVisible(false);
      return;
    }

    final height = MediaQuery.sizeOf(context).height;
    final revealThreshold = height * _revealViewportFraction;
    final hideThreshold = height * _hideViewportFraction;
    final offset = widget.scrollController.offset;
    final shouldShow = _isVisible
        ? offset >= hideThreshold
        : offset >= revealThreshold;

    _setVisible(shouldShow);
  }

  void _setVisible(bool visible) {
    if (visible == _isVisible) return;
    setState(() {
      _isVisible = visible;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible || !widget.isAvailable) {
      return const SizedBox.shrink();
    }

    return IconButton(
      tooltip: widget.tooltip,
      onPressed: widget.onPressed,
      icon: widget.isRefreshing
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.sync),
    );
  }
}
