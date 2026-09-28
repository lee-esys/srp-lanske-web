import 'dart:convert';

import '../application/event_ownership_transfer_handoff_store.dart';
import '../domain/event_ownership_transfer.dart';
import 'browser_storage.dart';

class BrowserEventOwnershipTransferHandoffStore
    implements EventOwnershipTransferHandoffStore {
  static const String _storageKey =
      'lanske_event_ownership_transfer_handoff_v1';

  @override
  EventOwnershipTransferHandoff? load() {
    final raw = readBrowserValue(_storageKey);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        clear();
        return null;
      }
      return EventOwnershipTransferHandoff.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (_) {
      clear();
      return null;
    }
  }

  @override
  void save(EventOwnershipTransferHandoff handoff) {
    writeBrowserValue(_storageKey, jsonEncode(handoff.toJson()));
  }

  @override
  void clear() {
    removeBrowserValue(_storageKey);
  }
}
