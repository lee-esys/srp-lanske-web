import 'package:flutter/widgets.dart';

import '../application/auth_repository.dart';
import '../application/auth_session_controller.dart';

class AuthScope extends StatefulWidget {
  const AuthScope({
    super.key,
    required this.repository,
    required this.child,
  });

  final AuthRepository repository;
  final Widget child;

  static AuthSessionController of(BuildContext context) {
    final controller = maybeOf(context);
    if (controller == null) {
      throw FlutterError('AuthScope was not found in the widget tree.');
    }
    return controller;
  }

  static AuthSessionController? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_AuthInheritedNotifier>()
        ?.notifier;
  }

  @override
  State<AuthScope> createState() => _AuthScopeState();
}

class _AuthScopeState extends State<AuthScope> {
  late AuthSessionController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AuthSessionController(widget.repository);
  }

  @override
  void didUpdateWidget(covariant AuthScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.repository, widget.repository)) {
      _controller.dispose();
      _controller = AuthSessionController(widget.repository);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthInheritedNotifier(
      controller: _controller,
      child: widget.child,
    );
  }
}

class _AuthInheritedNotifier extends InheritedNotifier<AuthSessionController> {
  const _AuthInheritedNotifier({
    required AuthSessionController controller,
    required super.child,
  }) : super(notifier: controller);
}
