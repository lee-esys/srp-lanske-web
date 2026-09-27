import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/event_capabilities.dart';

void main() {
  group('resolveEventCapabilities', () {
    test('allows owner-only capabilities when UIDs match', () {
      final capabilities = resolveEventCapabilities(
        ownerUid: 'owner-uid',
        currentUid: 'owner-uid',
      );

      expect(capabilities.isOwner, isTrue);
      expect(capabilities.canEditDisplay, isTrue);
      expect(capabilities.canEditCourtSettings, isTrue);
    });

    test('denies owner-only capabilities when UIDs differ', () {
      final capabilities = resolveEventCapabilities(
        ownerUid: 'owner-uid',
        currentUid: 'shared-user-uid',
      );

      expect(capabilities.isOwner, isFalse);
      expect(capabilities.canEditDisplay, isFalse);
      expect(capabilities.canEditCourtSettings, isFalse);
    });

    test('treats legacy event without ownerUid as non-owner', () {
      final capabilities = resolveEventCapabilities(
        ownerUid: null,
        currentUid: 'current-uid',
      );

      expect(capabilities.isOwner, isFalse);
      expect(capabilities.canEditDisplay, isFalse);
      expect(capabilities.canEditCourtSettings, isFalse);
    });

    test('treats signed-out session as non-owner', () {
      final capabilities = resolveEventCapabilities(
        ownerUid: 'owner-uid',
        currentUid: null,
      );

      expect(capabilities.isOwner, isFalse);
      expect(capabilities.canEditDisplay, isFalse);
      expect(capabilities.canEditCourtSettings, isFalse);
    });

    test('ignores blank UIDs', () {
      final ownerBlank = resolveEventCapabilities(
        ownerUid: ' ',
        currentUid: 'owner-uid',
      );
      final currentBlank = resolveEventCapabilities(
        ownerUid: 'owner-uid',
        currentUid: ' ',
      );

      expect(ownerBlank.isOwner, isFalse);
      expect(currentBlank.isOwner, isFalse);
    });
  });
}
