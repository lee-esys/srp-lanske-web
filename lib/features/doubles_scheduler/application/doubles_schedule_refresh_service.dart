import 'package:srp_lanske/features/schedule_progress/application/schedule_progress_repository.dart';
import 'package:srp_lanske/features/schedule_progress/domain/schedule_progress_models.dart';

import '../domain/saved_event_models.dart';
import 'event_repository.dart';

typedef GeneratedScheduleByIdLoader = Future<Map<String, dynamic>> Function(
  String generatedScheduleId,
);

class DoublesScheduleNotFoundException implements Exception {
  const DoublesScheduleNotFoundException(this.publicId);

  final String publicId;

  @override
  String toString() => 'DoublesScheduleNotFoundException($publicId)';
}

class DoublesScheduleRefreshSnapshot {
  DoublesScheduleRefreshSnapshot({
    required this.aggregate,
    required this.scheduleResponse,
    required this.progressScope,
    required this.progressSummary,
    required List<ScheduleMatchProgress> matches,
    required this.eventChanged,
    required this.scheduleChanged,
    required this.progressChanged,
  }) : matches = List<ScheduleMatchProgress>.unmodifiable(matches);

  factory DoublesScheduleRefreshSnapshot.fromCurrentState({
    required SavedEventAggregate aggregate,
    required Map<String, dynamic>? scheduleResponse,
    required ScheduleProgressSummary? progressSummary,
    required List<ScheduleMatchProgress> matches,
  }) {
    final generatedScheduleId = aggregate.event.displayGeneratedScheduleId;
    final progressScope = generatedScheduleId == null ||
            generatedScheduleId.isEmpty
        ? null
        : ScheduleProgressScope(
            scheduleType: ScheduleProgressScheduleType.doubles,
            shareId: aggregate.event.publicId,
            generatedScheduleId: generatedScheduleId,
          );

    return DoublesScheduleRefreshSnapshot(
      aggregate: aggregate,
      scheduleResponse: scheduleResponse,
      progressScope: progressScope,
      progressSummary: progressSummary,
      matches: matches,
      eventChanged: false,
      scheduleChanged: false,
      progressChanged: false,
    );
  }

  final SavedEventAggregate aggregate;
  final Map<String, dynamic>? scheduleResponse;
  final ScheduleProgressScope? progressScope;
  final ScheduleProgressSummary? progressSummary;
  final List<ScheduleMatchProgress> matches;
  final bool eventChanged;
  final bool scheduleChanged;
  final bool progressChanged;

  String? get generatedScheduleId {
    return aggregate.event.displayGeneratedScheduleId;
  }

  bool get hasChanges {
    return eventChanged || scheduleChanged || progressChanged;
  }

  String get progressText {
    final summary = progressSummary;
    if (summary == null) {
      return '- / -';
    }

    return '${summary.completedMatchCount} / ${summary.totalMatchCount}';
  }

  Map<String, ScheduleMatchProgress> get matchesByKey {
    return Map<String, ScheduleMatchProgress>.unmodifiable({
      for (final match in matches) match.key.value: match,
    });
  }
}

class DoublesScheduleRefreshService {
  DoublesScheduleRefreshService({
    required EventRepository eventRepository,
    required ScheduleProgressRepository progressRepository,
    required GeneratedScheduleByIdLoader loadGeneratedSchedule,
  })  : _eventRepository = eventRepository,
        _progressRepository = progressRepository,
        _loadGeneratedSchedule = loadGeneratedSchedule;

  final EventRepository _eventRepository;
  final ScheduleProgressRepository _progressRepository;
  final GeneratedScheduleByIdLoader _loadGeneratedSchedule;

  Future<DoublesScheduleRefreshSnapshot> loadLatestByPublicId({
    required String publicId,
    DoublesScheduleRefreshSnapshot? current,
  }) async {
    final aggregate = await _eventRepository.findByPublicId(publicId);
    if (aggregate == null) {
      throw DoublesScheduleNotFoundException(publicId);
    }

    final generatedScheduleId = aggregate.event.displayGeneratedScheduleId;
    final currentGeneratedScheduleId = current?.generatedScheduleId;
    final eventChanged = current == null ||
        current.aggregate.event.revision != aggregate.event.revision;
    final scheduleChanged = current == null ||
        currentGeneratedScheduleId != generatedScheduleId;

    Map<String, dynamic>? scheduleResponse;
    ScheduleProgressScope? progressScope;
    ScheduleProgressSummary? progressSummary;
    List<ScheduleMatchProgress> matches = const [];
    var progressChanged = false;

    if (generatedScheduleId != null && generatedScheduleId.isNotEmpty) {
      scheduleResponse = !scheduleChanged && current?.scheduleResponse != null
          ? current!.scheduleResponse
          : await _loadGeneratedSchedule(generatedScheduleId);

      progressScope = ScheduleProgressScope(
        scheduleType: ScheduleProgressScheduleType.doubles,
        shareId: aggregate.event.publicId,
        generatedScheduleId: generatedScheduleId,
      );
      progressSummary = await _progressRepository.findSummary(progressScope);

      final sameProgressScope =
          current?.progressScope?.storageKey == progressScope.storageKey;
      final sameProgressRevision = sameProgressScope &&
          current?.progressSummary?.revision == progressSummary?.revision;

      if (progressSummary == null) {
        matches = const [];
      } else if (sameProgressRevision) {
        matches = current!.matches;
      } else {
        matches = await _progressRepository.listMatches(progressScope);
      }

      progressChanged = current == null ||
          !sameProgressScope ||
          current.progressSummary?.revision != progressSummary?.revision;
    } else {
      progressChanged = current?.progressSummary != null ||
          (current?.matches.isNotEmpty ?? false);
    }

    return DoublesScheduleRefreshSnapshot(
      aggregate: aggregate,
      scheduleResponse: scheduleResponse,
      progressScope: progressScope,
      progressSummary: progressSummary,
      matches: matches,
      eventChanged: eventChanged,
      scheduleChanged: scheduleChanged,
      progressChanged: progressChanged,
    );
  }

  Future<ScheduleMatchProgress> findLatestMatch({
    required ScheduleProgressScope scope,
    required int roundNo,
    required int courtNo,
    int? matchNo,
  }) {
    return _progressRepository.findMatch(
      scope: scope,
      roundNo: roundNo,
      courtNo: courtNo,
      matchNo: matchNo,
    );
  }
}
