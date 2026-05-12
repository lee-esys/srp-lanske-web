class AppConfig {
  static const String appName = 'Lanske';

  static const String coreApiBaseUrl = String.fromEnvironment(
    'LANSKE_CORE_API_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );
}
