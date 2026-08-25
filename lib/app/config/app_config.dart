class AppConfig {
  static const String appName = 'Lanske';
  static const String releaseVersion = '0.1.6';

  static const String coreApiBaseUrl = String.fromEnvironment(
    'LANSKE_CORE_API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const String eventRepositoryMode = String.fromEnvironment(
    'LANSKE_EVENT_REPOSITORY',
    defaultValue: 'memory',
  );

  static const String configuredAppEnvironment = String.fromEnvironment(
    'LANSKE_APP_ENV',
    defaultValue: 'unknown',
  );

  static bool get usesFirestoreEventRepository {
    return eventRepositoryMode == 'firestore';
  }

  static String get appEnvironment {
    return normalizeAppEnvironment(configuredAppEnvironment);
  }
}

const Set<String> supportedAppEnvironments = <String>{
  'prod',
  'preview',
  'dev',
  'local',
  'unknown',
};

String normalizeAppEnvironment(String value) {
  final normalized = value.trim().toLowerCase();
  if (supportedAppEnvironments.contains(normalized)) {
    return normalized;
  }
  return 'unknown';
}
