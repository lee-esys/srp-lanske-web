import 'package:flutter/material.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/doubles_match_progress_service.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/local_schedule_history_mapper.dart';
import 'package:srp_lanske/features/doubles_scheduler/data/local_schedule_history_store.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/doubles_match_save_registry.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';
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
  late final DoublesMatchProgressService _progressService;

  DoublesMatchSaveRegistration? _saveRegistration;

  @override
  void initState() {
    super.initState();
    _progressService = DoublesMatchProgressService(
      repository: appScheduleProgressRepository,
    );
    _syncSaveRegistration();
  }

  @override
  void didUpdateWidget(covariant ScheduleRoundsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncSaveRegistration();
  }

  @override
  void dispose() {
    DoublesMatchSaveRegistry.unregister(_saveRegistration);
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
    return impl.ScheduleRoundsView(
      scheduleResponse: widget.scheduleResponse,
      playerNameById: widget.playerNameById,
      courtCount: widget.courtCount,
      selectedPlayerId: widget.selectedPlayerId,
      onPlayerSelected: widget.onPlayerSelected,
      courtLabelByNumber: widget.courtLabelByNumber,
    );
  }
}
