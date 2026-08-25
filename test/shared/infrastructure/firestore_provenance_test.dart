import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/app/config/app_config.dart';
import 'package:srp_lanske/shared/infrastructure/firestore_provenance.dart';

void main() {
  group('normalizeAppEnvironment', () {
    test('accepts supported values and normalizes casing', () {
      expect(normalizeAppEnvironment('prod'), 'prod');
      expect(normalizeAppEnvironment(' Preview '), 'preview');
      expect(normalizeAppEnvironment('DEV'), 'dev');
      expect(normalizeAppEnvironment('local'), 'local');
      expect(normalizeAppEnvironment('unknown'), 'unknown');
    });

    test('falls back to unknown for unsupported values', () {
      expect(normalizeAppEnvironment(''), 'unknown');
      expect(normalizeAppEnvironment('codespaces'), 'unknown');
      expect(normalizeAppEnvironment('staging'), 'unknown');
    });
  });

  test('create provenance records the same origin for create and write', () {
    final origin = FirestoreWriteOrigin(
      environment: 'preview',
      host: 'preview.example.test',
      firebaseProjectId: 'firebase-project',
      appVersion: '0.2.0',
    );

    expect(
      createFirestoreProvenance(origin),
      <String, dynamic>{
        'createdFrom': <String, dynamic>{
          'environment': 'preview',
          'host': 'preview.example.test',
          'firebaseProjectId': 'firebase-project',
          'appVersion': '0.2.0',
        },
        'lastWrittenFrom': <String, dynamic>{
          'environment': 'preview',
          'host': 'preview.example.test',
          'firebaseProjectId': 'firebase-project',
          'appVersion': '0.2.0',
        },
      },
    );
  });

  test('update provenance preserves createdFrom and replaces lastWrittenFrom', () {
    final updated = updateFirestoreProvenance(
      current: <String, dynamic>{
        'createdFrom': <String, dynamic>{
          'environment': 'prod',
          'host': 'lanske.jp',
          'firebaseProjectId': 'lanske-srp',
          'appVersion': '0.1.6',
        },
        'lastWrittenFrom': <String, dynamic>{
          'environment': 'prod',
          'host': 'lanske.jp',
          'firebaseProjectId': 'lanske-srp',
          'appVersion': '0.1.6',
        },
      },
      origin: FirestoreWriteOrigin(
        environment: 'dev',
        host: 'codespace-3000.app.github.dev',
        firebaseProjectId: 'lanske-srp',
        appVersion: '0.2.0',
      ),
    );

    expect(
      updated['createdFrom'],
      <String, dynamic>{
        'environment': 'prod',
        'host': 'lanske.jp',
        'firebaseProjectId': 'lanske-srp',
        'appVersion': '0.1.6',
      },
    );
    expect(
      updated['lastWrittenFrom'],
      <String, dynamic>{
        'environment': 'dev',
        'host': 'codespace-3000.app.github.dev',
        'firebaseProjectId': 'lanske-srp',
        'appVersion': '0.2.0',
      },
    );
  });

  test('legacy update does not invent createdFrom', () {
    final updated = updateFirestoreProvenance(
      current: null,
      origin: FirestoreWriteOrigin(
        environment: 'local',
        host: 'web.lanske.localhost',
        firebaseProjectId: 'lanske-srp',
        appVersion: '0.2.0',
      ),
    );

    expect(updated.containsKey('createdFrom'), isFalse);
    expect(updated['lastWrittenFrom'], isA<Map<String, dynamic>>());
  });

  test('blank metadata values are stored as unknown', () {
    final origin = FirestoreWriteOrigin(
      environment: 'unexpected',
      host: ' ',
      firebaseProjectId: '',
      appVersion: '',
    );

    expect(origin.environment, 'unknown');
    expect(origin.host, 'unknown');
    expect(origin.firebaseProjectId, 'unknown');
    expect(origin.appVersion, 'unknown');
  });
}
