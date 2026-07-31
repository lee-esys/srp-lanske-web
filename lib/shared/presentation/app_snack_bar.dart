import 'package:flutter/material.dart';

import 'app_message_type.dart';

abstract final class AppSnackBar {
  static const Duration _duplicateWindow = Duration(seconds: 2);
  static const Duration _persistentDuration = Duration(days: 1);
  static final Expando<_AppSnackBarState> _states =
      Expando<_AppSnackBarState>('appSnackBarState');

  static void show(
    BuildContext context, {
    required String message,
    AppMessageType type = AppMessageType.info,
    String? title,
    Duration? duration,
    bool persistent = false,
    bool? showCloseIcon,
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    if ((actionLabel == null) != (onAction == null)) {
      throw ArgumentError(
        'actionLabel and onAction must either both be set or both be null.',
      );
    }

    final messenger = ScaffoldMessenger.of(context);
    final state = _states[messenger] ?? _AppSnackBarState();
    _states[messenger] = state;

    final now = DateTime.now();
    final signature = _AppMessageSignature(
      type: type,
      title: title,
      message: message,
      actionLabel: actionLabel,
      persistent: persistent,
    );
    final lastShownAt = state.lastShownAt;

    if (state.lastSignature == signature &&
        lastShownAt != null &&
        now.difference(lastShownAt) < _duplicateWindow) {
      return;
    }

    final isLightweight =
        type == AppMessageType.success || type == AppMessageType.info;
    if (state.isPersistent && isLightweight) {
      return;
    }

    messenger.removeCurrentSnackBar(reason: SnackBarClosedReason.remove);
    messenger.clearSnackBars();

    final theme = Theme.of(context);
    final style = _AppMessageStyle.resolve(theme.colorScheme, type);
    final mediaWidth = MediaQuery.sizeOf(context).width;
    final useFixedWidth = mediaWidth >= 640;
    final shouldShowCloseIcon =
        showCloseIcon ??
        persistent ||
        type == AppMessageType.warning ||
        type == AppMessageType.error;

    state
      ..lastSignature = signature
      ..lastShownAt = now
      ..isPersistent = persistent;

    final controller = messenger.showSnackBar(
      SnackBar(
        key: const ValueKey<String>('app-snack-bar'),
        behavior: SnackBarBehavior.floating,
        width: useFixedWidth ? 560 : null,
        margin: useFixedWidth
            ? null
            : const EdgeInsets.fromLTRB(12, 0, 12, 12),
        elevation: 6,
        backgroundColor: style.backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(style.borderRadius),
          side: BorderSide(color: style.borderColor),
        ),
        clipBehavior: Clip.antiAlias,
        duration: persistent
            ? _persistentDuration
            : duration ?? _defaultDuration(type),
        showCloseIcon: shouldShowCloseIcon,
        closeIconColor: style.foregroundColor,
        action: actionLabel == null
            ? null
            : SnackBarAction(
                label: actionLabel,
                textColor: style.actionColor,
                onPressed: onAction!,
              ),
        content: Semantics(
          liveRegion: true,
          child: Row(
            crossAxisAlignment: title == null
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              Icon(
                style.icon,
                key: ValueKey<String>('app-snack-bar-${type.name}-icon'),
                color: style.iconColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: title == null
                    ? Text(
                        message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: style.foregroundColor,
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: style.foregroundColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            message,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: style.foregroundColor,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );

    controller.closed.then<void>((_) {
      if (state.lastSignature == signature) {
        state.isPersistent = false;
      }
    });
  }

  static Duration _defaultDuration(AppMessageType type) {
    return switch (type) {
      AppMessageType.success => const Duration(seconds: 3),
      AppMessageType.info => const Duration(seconds: 4),
      AppMessageType.warning => const Duration(seconds: 6),
      AppMessageType.error => const Duration(seconds: 8),
    };
  }
}

class _AppSnackBarState {
  _AppMessageSignature? lastSignature;
  DateTime? lastShownAt;
  bool isPersistent = false;
}

class _AppMessageSignature {
  const _AppMessageSignature({
    required this.type,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.persistent,
  });

  final AppMessageType type;
  final String? title;
  final String message;
  final String? actionLabel;
  final bool persistent;

  @override
  bool operator ==(Object other) {
    return other is _AppMessageSignature &&
        other.type == type &&
        other.title == title &&
        other.message == message &&
        other.actionLabel == actionLabel &&
        other.persistent == persistent;
  }

  @override
  int get hashCode => Object.hash(
        type,
        title,
        message,
        actionLabel,
        persistent,
      );
}

class _AppMessageStyle {
  const _AppMessageStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.iconColor,
    required this.actionColor,
    required this.borderColor,
    required this.icon,
    required this.borderRadius,
  });

  factory _AppMessageStyle.resolve(
    ColorScheme colors,
    AppMessageType type,
  ) {
    return switch (type) {
      AppMessageType.success => _AppMessageStyle(
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          iconColor: colors.primary,
          actionColor: colors.primary,
          borderColor: colors.primary.withAlpha(115),
          icon: Icons.check_circle_outline,
          borderRadius: 28,
        ),
      AppMessageType.info => _AppMessageStyle(
          backgroundColor: colors.secondaryContainer,
          foregroundColor: colors.onSecondaryContainer,
          iconColor: colors.secondary,
          actionColor: colors.secondary,
          borderColor: colors.secondary.withAlpha(115),
          icon: Icons.info_outline,
          borderRadius: 20,
        ),
      AppMessageType.warning => _AppMessageStyle(
          backgroundColor: colors.tertiaryContainer,
          foregroundColor: colors.onTertiaryContainer,
          iconColor: colors.tertiary,
          actionColor: colors.tertiary,
          borderColor: colors.tertiary.withAlpha(140),
          icon: Icons.warning_amber_rounded,
          borderRadius: 16,
        ),
      AppMessageType.error => _AppMessageStyle(
          backgroundColor: colors.errorContainer,
          foregroundColor: colors.onErrorContainer,
          iconColor: colors.error,
          actionColor: colors.error,
          borderColor: colors.error.withAlpha(166),
          icon: Icons.error_outline,
          borderRadius: 12,
        ),
    };
  }

  final Color backgroundColor;
  final Color foregroundColor;
  final Color iconColor;
  final Color actionColor;
  final Color borderColor;
  final IconData icon;
  final double borderRadius;
}
