import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/auth/domain/event_ownership_transfer.dart';
import 'package:srp_lanske/features/auth/infrastructure/browser_event_ownership_transfer_handoff_store.dart';

void main() {
  test('persists and clears ownership handoff data', () {
    final store = BrowserEventOwnershipTransferHandoffStore();
    store.clear();

    final handoff = EventOwnershipTransferHandoff(
      sourceUid: 'source-anon',
      handoffSecret: 'handoff-secret',
      expiresAt: DateTime.utc(2026, 9, 29),
    );

    store.save(handoff);

    final restored = store.load();
    expect(restored, isNotNull);
    expect(restored!.sourceUid, handoff.sourceUid);
    expect(restored.handoffSecret, handoff.handoffSecret);
    expect(restored.expiresAt, handoff.expiresAt);

    store.clear();
    expect(store.load(), isNull);
  });
}
