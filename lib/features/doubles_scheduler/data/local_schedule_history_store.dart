import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'local_schedule_history_item.dart';

class LocalScheduleHistoryStore {
  static const _key = 'lanske_recent_schedules';

  Future<List<LocalScheduleHistoryItem>> findAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return const [];

    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];

    return decoded
        .whereType<Map<String, dynamic>>()
        .map(LocalScheduleHistoryItem.fromJson)
        .where((item) => item.publicId.isNotEmpty)
        .toList(growable: false)
      ..sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));
  }

  Future<void> upsert(LocalScheduleHistoryItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final current = await findAll();

    final existing = {
      for (final currentItem in current) currentItem.publicId: currentItem,
    };

    final previous = existing[item.publicId];
    existing[item.publicId] = LocalScheduleHistoryItem(
      publicId: item.publicId,
      title: item.title,
      courtCount: item.courtCount,
      playerCount: item.playerCount,
      firstSavedAt: previous?.firstSavedAt ?? item.firstSavedAt,
      lastOpenedAt: item.lastOpenedAt,
    );

    final next = existing.values.toList(growable: false)
      ..sort((a, b) => b.lastOpenedAt.compareTo(a.lastOpenedAt));

    final limited = next.take(20).map((item) => item.toJson()).toList();

    await prefs.setString(_key, jsonEncode(limited));
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
    final current = await findAll();

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
}
