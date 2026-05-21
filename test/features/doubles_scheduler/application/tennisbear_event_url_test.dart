import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/tennisbear_event_url.dart';

void main() {
  group('parseTennisbearEventUrl', () {
    test('accepts canonical and external share event URLs', () {
      const cases = [
        'https://www.tennisbear.net/event/1178229/info',
        'https://www.tennisbear.net/event/1178229/info/',
        'https://www.tennisbear.net/event/1178229/info/?openExternalBrowser=1',
        'https://tennisbear.net/event/1178229/info/?openExternalBrowser=1',
      ];

      for (final value in cases) {
        final parsed = parseTennisbearEventUrl(value);

        expect(parsed, isNotNull, reason: value);
        expect(parsed!.original, value);
        expect(parsed.eventId, '1178229');
        expect(
          parsed.canonicalUrl,
          'https://www.tennisbear.net/event/1178229/info',
        );
      }
    });

    test('accepts event URL without info path and canonicalizes it', () {
      final parsed = parseTennisbearEventUrl(
        'https://www.tennisbear.net/event/1178229',
      );

      expect(parsed, isNotNull);
      expect(parsed!.eventId, '1178229');
      expect(
        parsed.canonicalUrl,
        'https://www.tennisbear.net/event/1178229/info',
      );
    });

    test('rejects non event URLs', () {
      const cases = [
        '',
        'https://example.com/event/1178229/info',
        'https://www.tennisbear.net/event/abc/info',
        'https://www.tennisbear.net/user/1178229',
        'http://www.tennisbear.net/event/1178229/info',
      ];

      for (final value in cases) {
        expect(parseTennisbearEventUrl(value), isNull, reason: value);
      }
    });
  });
}
