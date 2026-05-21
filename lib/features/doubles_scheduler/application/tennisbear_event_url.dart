class TennisbearEventUrl {
  const TennisbearEventUrl({
    required this.original,
    required this.eventId,
    required this.canonicalUrl,
  });

  final String original;
  final String eventId;
  final String canonicalUrl;
}

TennisbearEventUrl? parseTennisbearEventUrl(String value) {
  final original = value.trim();
  if (original.isEmpty) return null;

  final uri = Uri.tryParse(original);
  if (uri == null) return null;

  if (uri.scheme != 'https') return null;

  final host = uri.host.toLowerCase();
  if (host != 'www.tennisbear.net' && host != 'tennisbear.net') {
    return null;
  }

  final segments = uri.pathSegments
      .map((segment) => segment.trim())
      .where((segment) => segment.isNotEmpty)
      .toList(growable: false);

  if (segments.length < 2) return null;
  if (segments[0] != 'event') return null;

  final eventId = segments[1];
  if (!RegExp(r'^\d+$').hasMatch(eventId)) return null;

  if (segments.length >= 3 && segments[2] != 'info') {
    return null;
  }

  return TennisbearEventUrl(
    original: original,
    eventId: eventId,
    canonicalUrl: 'https://www.tennisbear.net/event/$eventId/info',
  );
}
