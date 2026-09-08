import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/external_identity/domain/external_identity.dart';
import 'package:srp_lanske/features/external_identity/domain/tennisbear_profile_url_parser.dart';

void main() {
  const parser = TennisBearProfileUrlParser();

  test('parses and canonicalizes a TennisBear profile URL', () {
    final identity = parser.parse(
      'https://tennisbear.net/user/899212/info/?from=test',
    );

    expect(identity.sourceType, ExternalIdentitySourceType.tennisbear);
    expect(identity.sourceUserId, '899212');
    expect(identity.mappingId, 'tennisbear_899212');
    expect(
      identity.profileUrl,
      'https://www.tennisbear.net/user/899212/info',
    );
  });

  test('rejects a non-profile TennisBear URL', () {
    expect(
      () => parser.parse(
        'https://www.tennisbear.net/user/899212/organized-event',
      ),
      throwsFormatException,
    );
  });

  test('rejects another host', () {
    expect(
      () => parser.parse('https://example.com/user/899212/info'),
      throwsFormatException,
    );
  });

  test('rejects a non-numeric TennisBear user ID', () {
    expect(
      () => parser.parse('https://www.tennisbear.net/user/test/info'),
      throwsFormatException,
    );
  });
}
