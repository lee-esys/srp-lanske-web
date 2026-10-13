class AppConfig {
  static const String appName = 'Lanske';
  static const String releaseVersion = '0.2.0+2';

  // Firebase target is independent of provenance LANSKE_APP_ENV.
  // Never silently fall back to production for an invalid target.
  static const String firebaseProject = String.fromEnvironment(
    'LANSKE_FIREBASE_PROJECT',
    defaultValue: 'prod',
  );

  static const String firebaseDevApiKey = String.fromEnvironment(
    'LANSKE_FIREBASE_DEV_API_KEY',
  );
  static const String firebaseDevAppId = String.fromEnvironment(
    'LANSKE_FIREBASE_DEV_APP_ID',
  );
  static const String firebaseDevMessagingSenderId = String.fromEnvironment(
    'LANSKE_FIREBASE_DEV_MESSAGING_SENDER_ID',
  );

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

void validateFirebaseProject(String project) {
  if (project != 'prod' && project != 'dev') {
    throw StateError(
        'Invalid LANSKE_FIREBASE_PROJECT: $project (expected prod or dev)');
  }
}
