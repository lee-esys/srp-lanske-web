import 'external_identity.dart';

class TennisBearProfileUrlParser {
  const TennisBearProfileUrlParser();

  static const _canonicalHost = 'www.tennisbear.net';
  static final _userIdPattern = RegExp(r'^\d{1,20}$');

  ExternalIdentity parse(String rawUrl) {
    final uri = Uri.tryParse(rawUrl.trim());
    if (uri == null ||
        uri.scheme != 'https' ||
        (uri.host != _canonicalHost && uri.host != 'tennisbear.net')) {
      throw const FormatException('Invalid TennisBear profile URL.');
    }

    final segments =
        uri.pathSegments.where((segment) => segment.isNotEmpty).toList();
    if (segments.length != 3 ||
        segments[0] != 'user' ||
        segments[2] != 'info') {
      throw const FormatException('Invalid TennisBear profile URL path.');
    }

    final sourceUserId = segments[1];
    if (!_userIdPattern.hasMatch(sourceUserId)) {
      throw const FormatException('Invalid TennisBear user ID.');
    }

    final canonicalProfileUrl = Uri(
      scheme: 'https',
      host: _canonicalHost,
      pathSegments: <String>['user', sourceUserId, 'info'],
    ).toString();

    return ExternalIdentity(
      sourceType: ExternalIdentitySourceType.tennisbear,
      sourceUserId: sourceUserId,
      profileUrl: canonicalProfileUrl,
    );
  }
}
