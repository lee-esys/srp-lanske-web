import 'schedule_progress_models.dart';

enum ScheduleProgressNavigationKind {
  inProgress,
  nextScheduled,
  completed,
}

class ScheduleProgressNavigation {
  const ScheduleProgressNavigation._({
    required this.kind,
    required this.primaryMatchKey,
    required this.inProgressMatchKeys,
  });

  factory ScheduleProgressNavigation.inProgress({
    required ScheduleMatchKey primaryMatchKey,
    required List<ScheduleMatchKey> inProgressMatchKeys,
  }) {
    if (inProgressMatchKeys.isEmpty) {
      throw ArgumentError.value(
        inProgressMatchKeys,
        'inProgressMatchKeys',
        'must not be empty',
      );
    }

    return ScheduleProgressNavigation._(
      kind: ScheduleProgressNavigationKind.inProgress,
      primaryMatchKey: primaryMatchKey,
      inProgressMatchKeys: List<ScheduleMatchKey>.unmodifiable(
        inProgressMatchKeys,
      ),
    );
  }

  const ScheduleProgressNavigation.nextScheduled({
    required ScheduleMatchKey primaryMatchKey,
  }) : this._(
          kind: ScheduleProgressNavigationKind.nextScheduled,
          primaryMatchKey: primaryMatchKey,
          inProgressMatchKeys: const [],
        );

  const ScheduleProgressNavigation.completed()
      : this._(
          kind: ScheduleProgressNavigationKind.completed,
          primaryMatchKey: null,
          inProgressMatchKeys: const [],
        );

  final ScheduleProgressNavigationKind kind;
  final ScheduleMatchKey? primaryMatchKey;
  final List<ScheduleMatchKey> inProgressMatchKeys;

  int get inProgressMatchCount => inProgressMatchKeys.length;
}

ScheduleProgressNavigation resolveScheduleProgressNavigation({
  required Iterable<ScheduleMatchKey> matchKeys,
  required Iterable<ScheduleMatchProgress> progresses,
}) {
  final orderedKeysByValue = <String, ScheduleMatchKey>{};
  for (final key in matchKeys) {
    orderedKeysByValue[key.value] = key;
  }

  final orderedKeys = orderedKeysByValue.values.toList(growable: false)..sort();
  if (orderedKeys.isEmpty) {
    return const ScheduleProgressNavigation.completed();
  }

  final progressByKey = <String, ScheduleMatchProgress>{
    for (final progress in progresses) progress.key.value: progress,
  };

  ScheduleMatchStatus statusFor(ScheduleMatchKey key) {
    return progressByKey[key.value]?.status ?? ScheduleMatchStatus.scheduled;
  }

  final inProgressMatchKeys = orderedKeys
      .where((key) => statusFor(key) == ScheduleMatchStatus.inProgress)
      .toList(growable: false);
  if (inProgressMatchKeys.isNotEmpty) {
    return ScheduleProgressNavigation.inProgress(
      primaryMatchKey: inProgressMatchKeys.first,
      inProgressMatchKeys: inProgressMatchKeys,
    );
  }

  for (final key in orderedKeys) {
    if (statusFor(key) == ScheduleMatchStatus.scheduled) {
      return ScheduleProgressNavigation.nextScheduled(primaryMatchKey: key);
    }
  }

  return const ScheduleProgressNavigation.completed();
}
