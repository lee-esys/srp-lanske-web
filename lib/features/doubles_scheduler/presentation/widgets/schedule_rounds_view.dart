import 'package:flutter/material.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/doubles_match_progress_service.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/local_schedule_history_mapper.dart';
import 'package:srp_lanske/features/doubles_scheduler/data/local_schedule_history_store.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/doubles_match_save_registry.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/doubles_progress_ui_store.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';
import 'package:srp_lanske/l10n/l10n.dart';
import 'package:srp_lanske/shared/repositories/app_repositories.dart';

import 'schedule_rounds_view_impl.dart' as impl;

export 'doubles_match_card.dart';
export 'schedule_rounds_view_impl.dart' hide ScheduleRoundsView;

class ScheduleRoundsView extends StatefulWidget {
  const ScheduleRoundsView({
    super.key,
    required this.scheduleResponse,
    required this.playerNameById,
    required this.courtCount,
    this.selectedPlayerId,
    this.onPlayerSelected,
    required this.courtLabelByNumber,
  });

  final Map<String, dynamic>? scheduleResponse;
  final Map<String, String> playerNameById;
  final int courtCount;
  final String? selectedPlayerId;
  final ValueChanged<String>? onPlayerSelected;
  final Map<int, String> courtLabelByNumber;

  @override
  State<ScheduleRoundsView> createState() => _ScheduleRoundsViewState();
}

class _ScheduleRoundsViewState extends State<ScheduleRoundsView> {
  static const _floatingNavigationRevealTop = 240.0;
  static const _floatingNavigationHideOffset = 48.0;

  late final DoublesMatchProgressService _progressService;
  final GlobalKey _floatingNavigationAnchorKey = GlobalKey();
  final ValueNotifier<bool> _floatingNavigationVisible = ValueNotifier(false);

  DoublesMatchSaveRegistration? _saveRegistration;
  ScrollPosition? _parentScrollPosition;
  OverlayEntry? _floatingNavigationEntry;
  Animation<double>? _routeSecondaryAnimation;
  bool _floatingVisibilityCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    _progressService = DoublesMatchProgressService(
      repository: appScheduleProgressRepository,
    );
    DoublesProgressUiStore.navigation.addListener(_handleNavigationChanged);
    _syncSaveRegistration();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRouteTransitionListener();
    _syncParentScrollPosition();
    _scheduleFloatingNavigationVisibilityCheck();
  }

  @override
  void didUpdateWidget(covariant ScheduleRoundsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSaveRegistration();
    _scheduleFloatingNavigationVisibilityCheck();
  }

  @override
  void dispose() {
    DoublesMatchSaveRegistry.unregister(_saveRegistration);
    DoublesProgressUiStore.navigation.removeListener(_handleNavigationChanged);
    DoublesProgressUiStore.setCompletedNavigation(null);
    _routeSecondaryAnimation?.removeListener(_handleRouteTransition);
    _parentScrollPosition?.removeListener(_handleParentScroll);
    _floatingNavigationEntry?.remove();
    _floatingNavigationEntry = null;
    _floatingNavigationVisible.dispose();
    super.dispose();
  }

  String? get _publicId {
    final value = Uri.base.queryParameters['sid']?.trim().toUpperCase();
    return value == null || value.isEmpty ? null : value;
  }

  String? get _generatedScheduleId {
    final value = widget.scheduleResponse?['generated_schedule_id']?.toString();
    return value == null || value.isEmpty ? null : value;
  }

  int get _totalMatchCount {
    return countDoublesScheduleMatches(widget.scheduleResponse);
  }

  ScheduleProgressScope? get _progressScope {
    final publicId = _publicId;
    final generatedScheduleId = _generatedScheduleId;
    if (publicId == null || generatedScheduleId == null) {
      return null;
    }

    return ScheduleProgressScope(
      scheduleType: ScheduleProgressScheduleType.doubles,
      shareId: publicId,
      generatedScheduleId: generatedScheduleId,
    );
  }

  void _syncSaveRegistration() {
    DoublesMatchSaveRegistry.unregister(_saveRegistration);
    _saveRegistration = null;

    final generatedScheduleId = _generatedScheduleId;
    if (_progressScope == null ||
        generatedScheduleId == null ||
        _totalMatchCount <= 0) {
      return;
    }

    _saveRegistration = DoublesMatchSaveRegistry.register(
      generatedScheduleId: generatedScheduleId,
      onSave: _saveMatch,
    );
  }

  void _syncRouteTransitionListener() {
    final nextAnimation = ModalRoute.of(context)?.secondaryAnimation;
    if (identical(nextAnimation, _routeSecondaryAnimation)) {
      return;
    }

    _routeSecondaryAnimation?.removeListener(_handleRouteTransition);
    _routeSecondaryAnimation = nextAnimation;
    _routeSecondaryAnimation?.addListener(_handleRouteTransition);
  }

  void _handleRouteTransition() {
    _scheduleFloatingNavigationVisibilityCheck();
  }

  void _syncParentScrollPosition() {
    final nextPosition = Scrollable.maybeOf(context)?.position;
    if (identical(nextPosition, _parentScrollPosition)) {
      return;
    }

    _parentScrollPosition?.removeListener(_handleParentScroll);
    _parentScrollPosition = nextPosition;
    _parentScrollPosition?.addListener(_handleParentScroll);
  }

  void _handleParentScroll() {
    _scheduleFloatingNavigationVisibilityCheck();
  }

  void _handleNavigationChanged() {
    final navigation = DoublesProgressUiStore.navigation.value;
    DoublesProgressUiStore.setCompletedNavigation(
      navigation?.kind == DoublesProgressNavigationUiKind.completed
          ? _scrollToBottom
          : null,
    );
    _scheduleFloatingNavigationVisibilityCheck();
  }

  void _scheduleFloatingNavigationVisibilityCheck() {
    if (_floatingVisibilityCheckScheduled) {
      return;
    }

    _floatingVisibilityCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _floatingVisibilityCheckScheduled = false;
      if (mounted) {
        _ensureFloatingNavigationEntry();
        _updateFloatingNavigationVisibility();
      }
    });
  }

  void _ensureFloatingNavigationEntry() {
    if (_floatingNavigationEntry != null) {
      return;
    }

    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) {
      return;
    }

    final entry = OverlayEntry(
      builder: (context) {
        return ValueListenableBuilder<bool>(
          valueListenable: _floatingNavigationVisible,
          builder: (context, visible, child) {
            if (!visible) {
              return const SizedBox.shrink();
            }
            return _buildFloatingNavigationOverlay(context);
          },
        );
      },
    );
    _floatingNavigationEntry = entry;
    overlay.insert(entry);
  }

  void _updateFloatingNavigationVisibility() {
    if (!(ModalRoute.of(context)?.isCurrent ?? true)) {
      _setFloatingNavigationVisible(false);
      return;
    }

    final navigation = DoublesProgressUiStore.navigation.value;
    final anchorContext = _floatingNavigationAnchorKey.currentContext;
    final renderObject = anchorContext?.findRenderObject();

    if (navigation == null ||
        renderObject is! RenderBox ||
        !renderObject.attached) {
      _setFloatingNavigationVisible(false);
      return;
    }

    final screenHeight = MediaQuery.sizeOf(context).height;
    final revealTop = (screenHeight * 0.3).clamp(
      180.0,
      _floatingNavigationRevealTop,
    );
    final hideTop = revealTop + _floatingNavigationHideOffset;
    final anchorTop = renderObject.localToGlobal(Offset.zero).dy;
    final shouldShow = _floatingNavigationVisible.value
        ? anchorTop <= hideTop
        : anchorTop <= revealTop;

    _setFloatingNavigationVisible(shouldShow);
  }

  void _setFloatingNavigationVisible(bool visible) {
    if (_floatingNavigationVisible.value == visible) {
      return;
    }
    _floatingNavigationVisible.value = visible;
  }

  Widget _buildFloatingNavigationOverlay(BuildContext context) {
    return Positioned(
      right: 40,
      bottom: 12,
      child: SafeArea(
        top: false,
        left: false,
        child: ValueListenableBuilder<DoublesProgressNavigationUiState?>(
          valueListenable: DoublesProgressUiStore.navigation,
          builder: (context, navigation, child) {
            if (navigation == null) {
              return const SizedBox.shrink();
            }

            final l10n = AppLocalizations.of(context);
            final colorScheme = Theme.of(context).colorScheme;
            final primaryLabel = switch (navigation.kind) {
              DoublesProgressNavigationUiKind.inProgress =>
                l10n.doublesProgressInProgressTitle,
              DoublesProgressNavigationUiKind.nextMatch =>
                l10n.doublesProgressNextMatchTitle,
              DoublesProgressNavigationUiKind.completed =>
                l10n.doublesProgressAllCompletedLabel,
            };
            final primaryIcon = switch (navigation.kind) {
              DoublesProgressNavigationUiKind.inProgress => Icons.my_location,
              DoublesProgressNavigationUiKind.nextMatch => Icons.arrow_downward,
              DoublesProgressNavigationUiKind.completed =>
                Icons.vertical_align_bottom,
            };
            final canUsePrimary =
                navigation.kind == DoublesProgressNavigationUiKind.completed ||
                    navigation.canNavigate;

            return Material(
              key: const ValueKey('doubles-schedule-floating-navigation'),
              elevation: 6,
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(28),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FilledButton.tonalIcon(
                      key: const ValueKey(
                        'doubles-schedule-floating-primary-button',
                      ),
                      onPressed: canUsePrimary
                          ? () {
                              if (navigation.kind ==
                                  DoublesProgressNavigationUiKind.completed) {
                                _scrollToBottom();
                              } else {
                                navigation.onNavigate?.call();
                              }
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 42),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: Icon(primaryIcon, size: 18),
                      label: Text(primaryLabel),
                    ),
                    const SizedBox(width: 4),
                    IconButton.filledTonal(
                      key: const ValueKey(
                        'doubles-schedule-floating-top-button',
                      ),
                      onPressed: _scrollToTop,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.vertical_align_top),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _scrollToTop() async {
    final position = _parentScrollPosition;
    if (position == null || !position.hasPixels) {
      return;
    }

    await position.animateTo(
      position.minScrollExtent,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _scrollToBottom() async {
    final position = _parentScrollPosition;
    if (position == null || !position.hasPixels) {
      return;
    }

    await position.animateTo(
      position.maxScrollExtent,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  Future<DoublesMatchProgressSaveResult> _saveMatch({
    required ScheduleMatchProgress current,
    required DoublesMatchProgressInput input,
  }) async {
    final scope = _progressScope;
    final totalMatchCount = _totalMatchCount;
    if (scope == null || totalMatchCount <= 0) {
      throw StateError('doubles match save scope is unavailable');
    }
    if (current.generatedScheduleId != scope.generatedScheduleId) {
      throw StateError('displayed doubles schedule changed while editing');
    }

    final saved = await _progressService.save(
      scope: scope,
      current: current,
      input: input,
      totalMatchCount: totalMatchCount,
    );

    try {
      final aggregate = await appEventRepository.findByPublicId(scope.shareId);
      if (aggregate != null) {
        await LocalScheduleHistoryStore().upsert(
          buildLocalScheduleHistoryItem(
            aggregate,
            now: DateTime.now(),
          ),
        );
      }
    } catch (error, stackTrace) {
      debugPrint('Failed to update local schedule history: $error');
      debugPrintStack(stackTrace: stackTrace);
    }

    return saved;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: _floatingNavigationAnchorKey,
      child: impl.ScheduleRoundsView(
        scheduleResponse: widget.scheduleResponse,
        playerNameById: widget.playerNameById,
        courtCount: widget.courtCount,
        selectedPlayerId: widget.selectedPlayerId,
        onPlayerSelected: widget.onPlayerSelected,
        courtLabelByNumber: widget.courtLabelByNumber,
      ),
    );
  }
}
