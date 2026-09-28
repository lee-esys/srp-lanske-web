import 'dart:convert';

import '../application/event_ownership_transfer_handoff_store.dart';
import '../domain/event_ownership_transfer.dart';
import 'session_storage.dart';

class SessionEventOwnershipTransferHandoffStore
    implements EventOwnershipTransferHandoffStore {
  static const String _storageKey =
      'lanske_event_ownership_transfer_handoff_v1';

  @override
  EventOwnershipTransferHandoff? load() {
    final raw = readSessionValue(_storageKey);
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
    writeSessionValue(_storageKey, jsonEncode(handoff.toJson()));
  }

  @override
  void clear() {
    removeSessionValue(_storageKey);
  }
}
