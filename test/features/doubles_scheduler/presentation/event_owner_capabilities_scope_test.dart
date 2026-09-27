import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/auth/application/auth_repository.dart';
import 'package:srp_lanske/features/auth/domain/auth_session.dart';
import 'package:srp_lanske/features/auth/presentation/auth_scope.dart';
import 'package:srp_lanske/features/doubles_scheduler/application/event_capabilities.dart';

void main() {
  testWidgets('updates owner capabilities when auth session changes',
      (tester) async {
    final repository = _FakeAuthRepository(
      initialSession: const AuthSession.anonymous('owner-uid'),
    );
    addTearDown(repository.close);

    await tester.pumpWidget(
      AuthScope(
        repository: repository,
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              final capabilities = resolveEventCapabilities(
                ownerUid: 'owner-uid',
                currentUid: AuthScope.of(context).session.uid,
              );

              return Text(
                capabilities.canEditDisplay ? 'owner-edit' : 'shared',
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('owner-edit'), findsOneWidget);

    repository.emit(const AuthSession.account('owner-uid'));
    await tester.pump();
    expect(find.text('owner-edit'), findsOneWidget);

    repository.emit(const AuthSession.account('other-uid'));
    await tester.pump();
    expect(find.text('shared'), findsOneWidget);

    repository.emit(const AuthSession.signedOut());
    await tester.pump();
    expect(find.text('shared'), findsOneWidget);
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({
    required AuthSession initialSession,
  }) : _currentSession = initialSession;

  final StreamController<AuthSession> _sessionController =
      StreamController<AuthSession>.broadcast(sync: true);

  AuthSession _currentSession;

  @override
  AuthSession get currentSession => _currentSession;

  @override
  Stream<AuthSession> sessionChanges() => _sessionController.stream;

  @override
  Future<AuthSession> ensureAnonymousSession() async {
    return _currentSession;
  }

  @override
  Future<void> signOut() async {
    emit(const AuthSession.signedOut());
  }

  void emit(AuthSession session) {
    _currentSession = session;
    _sessionController.add(session);
  }

  Future<void> close() => _sessionController.close();
}
