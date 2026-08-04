import 'dart:async';

import 'package:flutter/material.dart';

import 'app_footer.dart';

class AppFooterController extends ChangeNotifier {
  bool _isDisposed = false;
  int _resetRevision = 0;
  int _suspensionDepth = 0;

  int get resetRevision => _resetRevision;
  bool get isSuspended => _suspensionDepth > 0;

  void reset() {
    if (_isDisposed) return;

    _resetRevision += 1;
    _suspensionDepth = 0;
    notifyListeners();
  }

  void suspend() {
    if (_isDisposed) return;

    _suspensionDepth += 1;
    notifyListeners();
  }

  void resume() {
    if (_isDisposed || _suspensionDepth == 0) return;

    _suspensionDepth -= 1;
    notifyListeners();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }
}

class AppFooterNavigatorObserver extends NavigatorObserver {
  AppFooterNavigatorObserver(this.controller);

  final AppFooterController controller;

  void _schedule(VoidCallback action) {
    scheduleMicrotask(action);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);

    if (route is PageRoute<dynamic>) {
      _schedule(controller.reset);
    } else if (route is PopupRoute<dynamic>) {
      _schedule(controller.suspend);
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);

    if (route is PageRoute<dynamic>) {
      _schedule(controller.reset);
    } else if (route is PopupRoute<dynamic>) {
      _schedule(controller.resume);
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didRemove(route, previousRoute);

    if (route is PageRoute<dynamic>) {
      _schedule(controller.reset);
    } else if (route is PopupRoute<dynamic>) {
      _schedule(controller.resume);
    }
  }

  @override
  void didReplace({
    Route<dynamic>? newRoute,
    Route<dynamic>? oldRoute,
  }) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);

    if (newRoute is PageRoute<dynamic> || oldRoute is PageRoute<dynamic>) {
      _schedule(controller.reset);
      return;
    }

    final replacesPopupWithPopup =
        newRoute is PopupRoute<dynamic> && oldRoute is PopupRoute<dynamic>;
    if (replacesPopupWithPopup) return;

    if (oldRoute is PopupRoute<dynamic>) {
      _schedule(controller.resume);
    }
    if (newRoute is PopupRoute<dynamic>) {
      _schedule(controller.suspend);
    }
  }
}

class AppFooterHost extends StatefulWidget {
  const AppFooterHost({
    super.key,
    required this.child,
    required this.controller,
  });

  final Widget child;
  final AppFooterController controller;

  @override
  State<AppFooterHost> createState() => _AppFooterHostState();
}

class _AppFooterHostState extends State<AppFooterHost> {
  static const _endTolerance = 1.0;
  static const _hideDistanceFromEnd = 48.0;

  bool _showFooter = true;
  bool _revealedAtScrollableEnd = false;
  bool _suppressReveal = false;
  late int _lastResetRevision;

  @override
  void initState() {
    super.initState();
    _lastResetRevision = widget.controller.resetRevision;
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(AppFooterHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller == widget.controller) return;

    oldWidget.controller.removeListener(_handleControllerChanged);
    _lastResetRevision = widget.controller.resetRevision;
    widget.controller.addListener(_handleControllerChanged);
    _resetFooter();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }

  void _handleControllerChanged() {
    final resetRevision = widget.controller.resetRevision;
    if (_lastResetRevision == resetRevision) return;

    _lastResetRevision = resetRevision;
    _resetFooter();
  }

  void _resetFooter() {
    _updateFooterState(
      showFooter: true,
      revealedAtScrollableEnd: false,
      suppressReveal: false,
    );
  }

  bool _handleScrollMetricsNotification(
    ScrollMetricsNotification notification,
  ) {
    if (widget.controller.isSuspended || notification.depth != 0) {
      return false;
    }

    _updateFromMetrics(notification.metrics, isScrollEvent: false);
    return false;
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (widget.controller.isSuspended || notification.depth != 0) {
      return false;
    }

    _updateFromMetrics(notification.metrics, isScrollEvent: true);
    return false;
  }

  void _updateFromMetrics(
    ScrollMetrics metrics, {
    required bool isScrollEvent,
  }) {
    if (metrics.axis != Axis.vertical) return;

    final maxScrollExtent = metrics.maxScrollExtent;
    if (!maxScrollExtent.isFinite) return;

    if (maxScrollExtent <= _endTolerance) {
      _updateFooterState(
        showFooter: true,
        revealedAtScrollableEnd: false,
        suppressReveal: false,
      );
      return;
    }

    final distanceFromEnd = maxScrollExtent - metrics.pixels;
    final isAtEnd = distanceFromEnd <= _endTolerance;

    if (isAtEnd) {
      if (_suppressReveal && !isScrollEvent) return;

      _updateFooterState(
        showFooter: true,
        revealedAtScrollableEnd: true,
        suppressReveal: false,
      );
      return;
    }

    if (_revealedAtScrollableEnd) {
      if (isScrollEvent && distanceFromEnd > _hideDistanceFromEnd) {
        _updateFooterState(
          showFooter: false,
          revealedAtScrollableEnd: false,
          suppressReveal: true,
        );
      }
      return;
    }

    if (_suppressReveal && isScrollEvent) {
      _updateFooterState(
        showFooter: false,
        revealedAtScrollableEnd: false,
        suppressReveal: false,
      );
      return;
    }

    _updateFooterState(
      showFooter: false,
      revealedAtScrollableEnd: false,
      suppressReveal: _suppressReveal,
    );
  }

  void _updateFooterState({
    required bool showFooter,
    required bool revealedAtScrollableEnd,
    required bool suppressReveal,
  }) {
    if (_showFooter == showFooter &&
        _revealedAtScrollableEnd == revealedAtScrollableEnd &&
        _suppressReveal == suppressReveal) {
      return;
    }

    if (!mounted) return;

    setState(() {
      _showFooter = showFooter;
      _revealedAtScrollableEnd = revealedAtScrollableEnd;
      _suppressReveal = suppressReveal;
    });
  }

  @override
  Widget build(BuildContext context) {
    final keyboardIsVisible = MediaQuery.of(context).viewInsets.bottom > 0;
    final showFooter = _showFooter && !keyboardIsVisible;

    return NotificationListener<ScrollMetricsNotification>(
      onNotification: _handleScrollMetricsNotification,
      child: NotificationListener<ScrollNotification>(
        onNotification: _handleScrollNotification,
        child: Column(
          children: [
            Expanded(child: widget.child),
            if (showFooter)
              const SafeArea(
                top: false,
                child: AppFooter(),
              ),
          ],
        ),
      ),
    );
  }
}
