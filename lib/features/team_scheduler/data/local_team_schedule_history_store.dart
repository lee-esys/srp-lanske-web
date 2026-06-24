import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'local_team_schedule_history_item.dart';

class LocalTeamScheduleHistoryStore {
  static const String _storageKey = 'team_schedule_history_items';
  static const int _maxItems = 20;

  Future<List<LocalTeamScheduleHistoryItem>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final rawItems = prefs.getStringList(_storageKey) ?? const [];

    final items = <LocalTeamScheduleHistoryItem>[];

    for (final rawItem in rawItems) {
      try {
        final decoded = jsonDecode(rawItem);
        if (decoded is! Map<String, dynamic>) {
          continue;
        }

        final item = LocalTeamScheduleHistoryItem.fromJson(decoded);
        if (item.shareId.isEmpty) {
          continue;
        }

        items.add(item);
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }

    items.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return items;
  }

  Future<void> upsert(LocalTeamScheduleHistoryItem item) async {
    final normalizedShareId = item.shareId.trim().toUpperCase();

    if (normalizedShareId.isEmpty) {
      return;
    }

    final now = DateTime.now();
    final existingItems = await loadItems();

    LocalTeamScheduleHistoryItem? existingItem;
    final nextItems = <LocalTeamScheduleHistoryItem>[];

    for (final currentItem in existingItems) {
      if (currentItem.shareId == normalizedShareId) {
        existingItem = currentItem;
        continue;
      }

      nextItems.add(currentItem);
    }

    final nextItem = item.copyWith(
      shareId: normalizedShareId,
      firstSavedAt: existingItem?.firstSavedAt ?? item.firstSavedAt,
      updatedAt: now,
    );

    nextItems.insert(0, nextItem);

    await _saveItems(nextItems.take(_maxItems).toList(growable: false));
  }

  Future<void> remove(String shareId) async {
    final normalizedShareId = shareId.trim().toUpperCase();

    if (normalizedShareId.isEmpty) {
      return;
    }

    final existingItems = await loadItems();
    final nextItems = existingItems
        .where((item) => item.shareId != normalizedShareId)
        .toList(growable: false);

    await _saveItems(nextItems);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> _saveItems(List<LocalTeamScheduleHistoryItem> items) async {
    final prefs = await SharedPreferences.getInstance();

    final rawItems =
        items.map((item) => jsonEncode(item.toJson())).toList(growable: false);

    await prefs.setStringList(_storageKey, rawItems);
  }
}
