import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'local_schedule_history_item.dart';

class LocalScheduleHistoryStore {
  static const _key = 'lanske_recent_schedules';
  static const _maxItems = 20;

  Future<List<LocalScheduleHistoryItem>> findAll() async {
    final items = await _readAll();

    return items
      ..sort((a, b) {
        final createdAtComparison = b.createdAt.compareTo(a.createdAt);
        if (createdAtComparison != 0) {
          return createdAtComparison;
        }
        return b.lastOpenedAt.compareTo(a.lastOpenedAt);
      });
  }

  Future<void> upsert(LocalScheduleHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await _readAll();
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
    final normalizedPublicId = publicId.trim().toUpperCase();
    final normalizedGeneratedScheduleId = generatedScheduleId.trim();
    if (normalizedPublicId.isEmpty || normalizedGeneratedScheduleId.isEmpty) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final current = await _readAll();
    final index = current.indexWhere(
      (item) => item.publicId.trim().toUpperCase() == normalizedPublicId,
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
    );

    await _saveRetained(prefs, current);
  }

  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  Future<void> clearExceptPublicId(String publicId) async {
    final keepPublicId = publicId.trim().toUpperCase();
    if (keepPublicId.isEmpty) {
      await clearAll();
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final current = await _readAll();
    final kept = current
        .where((item) => item.publicId.trim().toUpperCase() == keepPublicId)
        .map((item) => item.toJson())
        .toList(growable: false);

    if (kept.isEmpty) {
      await prefs.remove(_key);
      return;
    }

    await prefs.setString(_key, jsonEncode(kept));
  }

  Future<List<LocalScheduleHistoryItem>> _readAll() async {
    final prefs = await SharedPreferences.getInstance();
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

  Future<void> _saveRetained(
    SharedPreferences prefs,
    Iterable<LocalScheduleHistoryItem> items,
  ) async {
    final retained = items.toList(growable: false)
      ..sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
    final encoded = retained
        .take(_maxItems)
        .map((item) => item.toJson())
        .toList(growable: false);

    await prefs.setString(_key, jsonEncode(encoded));
  }
}
