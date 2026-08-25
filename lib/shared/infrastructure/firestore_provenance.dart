import 'package:srp_lanske/app/config/app_config.dart';

class FirestoreWriteOrigin {
  FirestoreWriteOrigin({
    required String environment,
    required String host,
    required String firebaseProjectId,
    required String appVersion,
  })  : environment = normalizeAppEnvironment(environment),
        host = _normalizeMetadataValue(host),
        firebaseProjectId = _normalizeMetadataValue(firebaseProjectId),
        appVersion = _normalizeMetadataValue(appVersion);

  factory FirestoreWriteOrigin.current({
    required String firebaseProjectId,
    String? host,
  }) {
    return FirestoreWriteOrigin(
      environment: AppConfig.appEnvironment,
      host: host ?? Uri.base.host,
      firebaseProjectId: firebaseProjectId,
      appVersion: AppConfig.releaseVersion,
    );
  }

  final String environment;
  final String host;
  final String firebaseProjectId;
  final String appVersion;

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'environment': environment,
      'host': host,
      'firebaseProjectId': firebaseProjectId,
      'appVersion': appVersion,
    };
  }
}

Map<String, dynamic> createFirestoreProvenance(
  FirestoreWriteOrigin origin,
) {
  final originJson = origin.toJson();
  return <String, dynamic>{
    'createdFrom': Map<String, dynamic>.from(originJson),
    'lastWrittenFrom': Map<String, dynamic>.from(originJson),
  };
}

Map<String, dynamic> updateFirestoreProvenance({
  required Object? current,
  required FirestoreWriteOrigin origin,
}) {
  return <String, dynamic>{
    ..._asStringKeyedMap(current),
    'lastWrittenFrom': origin.toJson(),
  };
}

Map<String, dynamic> withCreatedFirestoreProvenance({
  required Map<String, dynamic> data,
  required FirestoreWriteOrigin origin,
}) {
  return <String, dynamic>{
    ...data,
    'provenance': createFirestoreProvenance(origin),
  };
}

Map<String, dynamic> withUpdatedFirestoreProvenance({
  required Map<String, dynamic> data,
  required Object? currentProvenance,
  required FirestoreWriteOrigin origin,
}) {
  return <String, dynamic>{
    ...data,
    'provenance': updateFirestoreProvenance(
      current: currentProvenance,
      origin: origin,
    ),
  };
}

Map<String, dynamic> _asStringKeyedMap(Object? value) {
  if (value is! Map) {
    return <String, dynamic>{};
  }

  return value.map(
    (key, item) => MapEntry(key.toString(), item),
  );
}

String _normalizeMetadataValue(String value) {
  final normalized = value.trim();
  return normalized.isEmpty ? 'unknown' : normalized;
}
