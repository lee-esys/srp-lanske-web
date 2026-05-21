String buildScheduleShareUrl({
  required Uri baseUri,
  required String publicId,
}) {
  return baseUri.replace(
    queryParameters: {
      ...baseUri.queryParameters,
      'sid': publicId,
    },
  ).toString();
}
