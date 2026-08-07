class AppConfig {
  static const String appName = 'Lanske';
  static const String releaseVersion = '0.1.6+2';

  static const String coreApiBaseUrl = String.fromEnvironment(
    'LANSKE_CORE_API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const String eventRepositoryMode = String.fromEnvironment(
    'LANSKE_EVENT_REPOSITORY',
    defaultValue: 'memory',
  );

  static bool get usesFirestoreEventRepository {
    return eventRepositoryMode == 'firestore';
  }
}
