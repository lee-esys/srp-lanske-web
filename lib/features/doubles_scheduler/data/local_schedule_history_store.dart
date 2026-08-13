import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'local_schedule_history_item.dart';
import 'local_schedule_history_policy.dart';

class LocalScheduleHistoryStore {
  static const _key = 'lanske_recent_schedules';
  static const _suppressedKey = 'lanske_suppressed_schedule_ids';

  Future<List<LocalScheduleHistoryItem>> findAll() async {
    final prefs = await SharedPreferences.getInstance();
    final suppressedPublicIds = _readSuppressedPublicIds(prefs);
    final items = await _readAll(prefs);
    final visibleItems = items
        .where(
          (item) =>
              !suppressedPublicIds.contains(_normalizePublicId(item.publicId)),
        )
        .toList(growable: true)
      ..sort((a, b) {
        final createdAtComparison = b.createdAt.compareTo(a.createdAt);
        if (createdAtComparison != 0) {
          return createdAtComparison;
        }
        return b.lastOpenedAt.compareTo(a.lastOpenedAt);
      });

    return visibleItems
        .take(LocalScheduleHistoryPolicy.displayLimit)
        .toList(growable: false);
  }

  Future<void> upsert(LocalScheduleHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedPublicId = _normalizePublicId(item.publicId);
    if (_readSuppressedPublicIds(prefs).contains(normalizedPublicId)) {
      return;
    }

    final current = await _readAll(prefs);
    final existing = {
      for (final currentItem in current) currentItem.publicId: currentItem,
    };

    final previous = existing[item.publicId];
    final sameGeneratedSchedule = previous?.generatedScheduleId != null &&
        item.generatedScheduleId != null &&
        previous!.generatedScheduleId == item.generatedScheduleId;
    final hasIncomingProgress =
        item.completedMatchCount != null && item.totalMatchCount != null;

    existing[item.publicId] = LocalScheduleHistoryItem(
      publicId: item.publicId,
      title: item.title,
      courtCount: item.courtCount,
      playerCount: item.playerCount,
      createdAt: item.createdAt,
      firstSavedAt: previous?.firstSavedAt ?? item.firstSavedAt,
      lastOpenedAt: item.lastOpenedAt,
      generatedScheduleId:
          item.generatedScheduleId ?? previous?.generatedScheduleId,
      isAdopted:
          item.isAdopted ?? (sameGeneratedSchedule ? previous.isAdopted : null),
      completedMatchCount: hasIncomingProgress
          ? item.completedMatchCount
          : sameGeneratedSchedule
              ? previous.completedMatchCount
              : null,
      totalMatchCount: hasIncomingProgress
          ? item.totalMatchCount
          : sameGeneratedSchedule
              ? previous.totalMatchCount
              : null,
      isPendingRemoval:
          (previous?.isPendingRemoval ?? false) || item.isPendingRemoval,
    );

    await _saveRetained(prefs, existing.values);
  }

  Future<void> updateProgress({
    required String publicId,
    required String generatedScheduleId,
    required int completedMatchCount,
    required int totalMatchCount,
    DateTime? lastOpenedAt,
  }) async {
    final normalizedPublicId = _normalizePublicId(publicId);
    final normalizedGeneratedScheduleId = generatedScheduleId.trim();
    if (normalizedPublicId.isEmpty || normalizedGeneratedScheduleId.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    if (_readSuppressedPublicIds(prefs).contains(normalizedPublicId)) {
      return;
    }

    final current = await _readAll(prefs);
    final index = current.indexWhere(
      (item) => _normalizePublicId(item.publicId) == normalizedPublicId,
    );
    if (index < 0) {
      return;
    }

    final item = current[index];
    final storedGeneratedScheduleId = item.generatedScheduleId?.trim();
    if (storedGeneratedScheduleId != null &&
        storedGeneratedScheduleId.isNotEmpty &&
        storedGeneratedScheduleId != normalizedGeneratedScheduleId) {
      return;
    }

    current[index] = LocalScheduleHistoryItem(
      publicId: item.publicId,
      title: item.title,
      courtCount: item.courtCount,
      playerCount: item.playerCount,
      createdAt: item.createdAt,
      firstSavedAt: item.firstSavedAt,
      lastOpenedAt: lastOpenedAt ?? DateTime.now(),
      generatedScheduleId: normalizedGeneratedScheduleId,
      isAdopted: true,
      completedMatchCount: completedMatchCount,
      totalMatchCount: totalMatchCount,
      isPendingRemoval: item.isPendingRemoval,
    );

    await _saveRetained(prefs, current);
  }

  Future<void> setPendingRemoval({
    required String publicId,
    required bool isPendingRemoval,
  }) async {
    await setPendingRemovalForPublicIds(
      [publicId],
      isPendingRemoval: isPendingRemoval,
    );
  }

  Future<void> setPendingRemovalForPublicIds(
    Iterable<String> publicIds, {
    required bool isPendingRemoval,
  }) async {
    final normalizedPublicIds = publicIds
        .map(_normalizePublicId)
        .where((publicId) => publicId.isNotEmpty)
        .toSet();
    if (normalizedPublicIds.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final current = await _readAll(prefs);
    var changed = false;

    for (var index = 0; index < current.length; index += 1) {
      final item = current[index];
      if (!normalizedPublicIds.contains(_normalizePublicId(item.publicId)) ||
          item.isPendingRemoval == isPendingRemoval) {
        continue;
      }

      current[index] = _copyWithPendingRemoval(item, isPendingRemoval);
      changed = true;
    }

    if (!changed) {
      return;
    }

    await _saveRetained(prefs, current);
  }

  Future<int> suppressPendingRemoval() async {
    final prefs = await SharedPreferences.getInstance();
    final current = await _readAll(prefs);
    final pending =
        current.where((item) => item.isPendingRemoval).toList(growable: false);
    if (pending.isEmpty) {
      return 0;
    }

    final suppressedPublicIds = _readSuppressedPublicIds(prefs)
      ..addAll(pending.map((item) => _normalizePublicId(item.publicId)));
    final retained =
        current.where((item) => !item.isPendingRemoval).toList(growable: false);

    await _saveSuppressedPublicIds(prefs, suppressedPublicIds);
    await _saveRetained(prefs, retained);
    return pending.length;
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final current = await _readAll(prefs);
    if (current.isEmpty) {
      await prefs.remove(_key);
      return;
    }

    final suppressedPublicIds = _readSuppressedPublicIds(prefs)
      ..addAll(current.map((item) => _normalizePublicId(item.publicId)));
    await _saveSuppressedPublicIds(prefs, suppressedPublicIds);
    await prefs.remove(_key);
  }

  Future<void> clearExceptPublicId(String publicId) async {
    final keepPublicId = _normalizePublicId(publicId);
    if (keepPublicId.isEmpty) {
      await clearAll();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final current = await _readAll(prefs);
    final suppressedPublicIds = _readSuppressedPublicIds(prefs);
    final kept = <LocalScheduleHistoryItem>[];

    for (final item in current) {
      if (_normalizePublicId(item.publicId) == keepPublicId) {
        kept.add(item);
      } else {
        suppressedPublicIds.add(_normalizePublicId(item.publicId));
      }
    }

    await _saveSuppressedPublicIds(prefs, suppressedPublicIds);
    if (kept.isEmpty) {
      await prefs.remove(_key);
      return;
    }

    await _saveRetained(prefs, kept);
  }

  Future<List<LocalScheduleHistoryItem>> _readAll(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <LocalScheduleHistoryItem>[];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return <LocalScheduleHistoryItem>[];

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(LocalScheduleHistoryItem.fromJson)
        .where((item) => item.publicId.isNotEmpty)
        .toList(growable: true);
  }

  Set<String> _readSuppressedPublicIds(SharedPreferences prefs) {
    return (prefs.getStringList(_suppressedKey) ?? const <String>[])
        .map(_normalizePublicId)
        .where((publicId) => publicId.isNotEmpty)
        .toSet();
  }

  Future<void> _saveSuppressedPublicIds(
    SharedPreferences prefs,
    Set<String> publicIds,
  ) async {
    final values = publicIds.toList(growable: false)..sort();
    await prefs.setStringList(_suppressedKey, values);
  }

  Future<void> _saveRetained(
    SharedPreferences prefs,
    Iterable<LocalScheduleHistoryItem> items,
  ) async {
    final retained = items.toList(growable: false)
      ..sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
    final encoded = retained
        .take(LocalScheduleHistoryPolicy.storageLimit)
        .map((item) => item.toJson())
        .toList(growable: false);

    if (encoded.isEmpty) {
      await prefs.remove(_key);
      return;
    }

    await prefs.setString(_key, jsonEncode(encoded));
  }

  LocalScheduleHistoryItem _copyWithPendingRemoval(
    LocalScheduleHistoryItem item,
    bool isPendingRemoval,
  ) {
    return LocalScheduleHistoryItem(
      publicId: item.publicId,
      title: item.title,
      courtCount: item.courtCount,
      playerCount: item.playerCount,
      createdAt: item.createdAt,
      firstSavedAt: item.firstSavedAt,
      lastOpenedAt: item.lastOpenedAt,
      generatedScheduleId: item.generatedScheduleId,
      isAdopted: item.isAdopted,
      completedMatchCount: item.completedMatchCount,
      totalMatchCount: item.totalMatchCount,
      isPendingRemoval: isPendingRemoval,
    );
  }

  String _normalizePublicId(String publicId) {
    return publicId.trim().toUpperCase();
  }
}
