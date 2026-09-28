import 'package:flutter_test/flutter_test.dart';
import 'package:srp_lanske/features/auth/application/account_auth_repository.dart';
import 'package:srp_lanske/features/auth/application/anonymous_event_ownership_transfer_service.dart';
import 'package:srp_lanske/features/auth/application/event_ownership_transfer_handoff_store.dart';
import 'package:srp_lanske/features/auth/application/event_ownership_transfer_repository.dart';
import 'package:srp_lanske/features/auth/domain/account_transition.dart';
import 'package:srp_lanske/features/auth/domain/auth_session.dart';
import 'package:srp_lanske/features/auth/domain/event_ownership_transfer.dart';
import 'package:srp_lanske/features/doubles_scheduler/data/in_memory_event_repository.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/player_draft.dart';
import 'package:srp_lanske/features/doubles_scheduler/domain/saved_event_models.dart';
import 'package:srp_lanske/features/doubles_scheduler/presentation/models/event_draft.dart';

void main() {
  const sourceUid = 'source-anon';
  const targetUid = 'target-account';
  final now = DateTime.utc(2026, 9, 28, 1);

  test('prepares transfer only from the active anonymous source', () async {
    final auth = _FakeAccountAuthRepository(
      const AuthSession.anonymous(sourceUid),
    );
    final transfers = _FakeTransferRepository();
    final handoffs = _FakeHandoffStore();
    final service = AnonymousEventOwnershipTransferService(
      authRepository: auth,
      eventRepository: InMemoryEventRepository(),
      transferRepository: transfers,
      handoffStore: handoffs,
      clock: () => now,
      handoffSecretGenerator: () => 'handoff-secret',
    );

    final handoff = await service.prepare(
      const AccountTransitionResult.existingAccountCollision(
        sourceUid: sourceUid,
        provider: AccountTransitionProvider.google,
      ),
    );

    expect(handoff.sourceUid, sourceUid);
    expect(handoff.handoffSecret, 'handoff-secret');
    expect(
      handoff.expiresAt,
      now.add(
        AnonymousEventOwnershipTransferService.pendingAuthorizationLifetime,
      ),
    );
    expect(transfers.prepareCalls, 1);
    expect(handoffs.value, handoff);
  });

  test('rejects prepare after the anonymous source session changed', () async {
    final service = AnonymousEventOwnershipTransferService(
      authRepository: _FakeAccountAuthRepository(
        const AuthSession.account(targetUid),
      ),
      eventRepository: InMemoryEventRepository(),
      transferRepository: _FakeTransferRepository(),
      handoffStore: _FakeHandoffStore(),
      clock: () => now,
    );

    await expectLater(
      service.prepare(
        const AccountTransitionResult.existingAccountCollision(
          sourceUid: sourceUid,
          provider: AccountTransitionProvider.emailPassword,
        ),
      ),
      throwsA(isA<EventOwnershipTransferRequiredException>()),
    );
  });

  test('moves all source-owned events to the current target account', () async {
    final auth = _FakeAccountAuthRepository(
      const AuthSession.anonymous(sourceUid),
    );
    final events = InMemoryEventRepository();
    final first = await events.createFromDraft(
      _draft('first'),
      ownerUid: sourceUid,
    );
    final second = await events.createFromDraft(
      _draft('second'),
      ownerUid: sourceUid,
    );
    await events.createFromDraft(
      _draft('already target'),
      ownerUid: targetUid,
    );

    final transfers = _FakeTransferRepository();
    final handoffs = _FakeHandoffStore();
    final service = AnonymousEventOwnershipTransferService(
      authRepository: auth,
      eventRepository: events,
      transferRepository: transfers,
      handoffStore: handoffs,
      clock: () => now,
      handoffSecretGenerator: () => 'handoff-secret',
    );

    await service.prepare(
      const AccountTransitionResult.existingAccountCollision(
        sourceUid: sourceUid,
        provider: AccountTransitionProvider.google,
      ),
    );
    auth.session = const AuthSession.account(targetUid);

    final result = await service.resumeForCurrentAccount();

    expect(result.sourceUid, sourceUid);
    expect(result.targetUid, targetUid);
    expect(result.transferredEventCount, 2);
    expect(
      (await events.findByPublicId(first.event.publicId))!.event.ownerUid,
      targetUid,
    );
    expect(
      (await events.findByPublicId(second.event.publicId))!.event.ownerUid,
      targetUid,
    );
    expect(await events.listByOwnerUid(sourceUid), isEmpty);
    expect(await events.listByOwnerUid(targetUid), hasLength(3));
    expect(transfers.acceptCalls, 1);
    expect(transfers.completeCalls, 1);
    expect(handoffs.value, isNull);
  });

  test('partial failure retries only events still owned by the source', () async {
    final auth = _FakeAccountAuthRepository(
      const AuthSession.anonymous(sourceUid),
    );
    final events = _FailingInMemoryEventRepository(failOnTransferCall: 2);
    final created = <SavedEventAggregate>[
      await events.createFromDraft(_draft('first'), ownerUid: sourceUid),
      await events.createFromDraft(_draft('second'), ownerUid: sourceUid),
      await events.createFromDraft(_draft('third'), ownerUid: sourceUid),
    ];
    final transfers = _FakeTransferRepository();
    final handoffs = _FakeHandoffStore();
    final service = AnonymousEventOwnershipTransferService(
      authRepository: auth,
      eventRepository: events,
      transferRepository: transfers,
      handoffStore: handoffs,
      clock: () => now,
      handoffSecretGenerator: () => 'handoff-secret',
    );

    await service.prepare(
      const AccountTransitionResult.existingAccountCollision(
        sourceUid: sourceUid,
        provider: AccountTransitionProvider.google,
      ),
    );
    auth.session = const AuthSession.account(targetUid);

    await expectLater(
      service.resumeForCurrentAccount(),
      throwsA(isA<StateError>()),
    );

    expect(
      (await events.findByPublicId(created[0].event.publicId))!.event.ownerUid,
      targetUid,
    );
    expect(await events.listByOwnerUid(sourceUid), hasLength(2));
    expect(transfers.completeCalls, 0);
    expect(handoffs.value, isNotNull);

    final retry = await service.resumeForCurrentAccount();

    expect(retry.transferredEventCount, 2);
    expect(await events.listByOwnerUid(sourceUid), isEmpty);
    expect(await events.listByOwnerUid(targetUid), hasLength(3));
    expect(transfers.acceptCalls, 2);
    expect(transfers.completeCalls, 1);
    expect(handoffs.value, isNull);
  });

  test('zero source-owned events still completes safely', () async {
    final auth = _FakeAccountAuthRepository(
      const AuthSession.anonymous(sourceUid),
    );
    final transfers = _FakeTransferRepository();
    final handoffs = _FakeHandoffStore();
    final service = AnonymousEventOwnershipTransferService(
      authRepository: auth,
      eventRepository: InMemoryEventRepository(),
      transferRepository: transfers,
      handoffStore: handoffs,
      clock: () => now,
      handoffSecretGenerator: () => 'handoff-secret',
    );

    await service.prepare(
      const AccountTransitionResult.existingAccountCollision(
        sourceUid: sourceUid,
        provider: AccountTransitionProvider.google,
      ),
    );
    auth.session = const AuthSession.account(targetUid);

    final result = await service.resumeForCurrentAccount();

    expect(result.transferredEventCount, 0);
    expect(transfers.completeCalls, 1);
    expect(handoffs.value, isNull);
  });

  test('expired local handoff is cleared before resume', () async {
    final handoffs = _FakeHandoffStore()
      ..value = EventOwnershipTransferHandoff(
        sourceUid: sourceUid,
        handoffSecret: 'handoff-secret',
        expiresAt: now.subtract(const Duration(seconds: 1)),
      );
    final service = AnonymousEventOwnershipTransferService(
      authRepository: _FakeAccountAuthRepository(
        const AuthSession.account(targetUid),
      ),
      eventRepository: InMemoryEventRepository(),
      transferRepository: _FakeTransferRepository(),
      handoffStore: handoffs,
      clock: () => now,
    );

    expect(service.loadPendingHandoff(), isNull);
    expect(handoffs.value, isNull);
    await expectLater(
      service.resumeForCurrentAccount(),
      throwsA(isA<EventOwnershipTransferRequiredException>()),
    );
  });
}

EventDraft _draft(String name) {
  return EventDraft(
    url: '',
    courts: 1,
    eventName: name,
    players: List<PlayerDraft>.generate(
      4,
      (index) => PlayerDraft.create(
        displayName: 'Player ${index + 1}',
      ),
    ),
  );
}

class _FakeAccountAuthRepository implements AccountAuthRepository {
  _FakeAccountAuthRepository(this.session);

  AuthSession session;

  @override
  AuthSession get currentSession => session;

  @override
  Future<AuthSession> createAccountWithEmailPassword({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuthSession> linkAnonymousWithEmailPassword({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuthSession> linkAnonymousWithGoogle() => throw UnimplementedError();

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      throw UnimplementedError();

  @override
  Future<AuthSession> signInWithEmailPassword({
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<AuthSession> signInWithGoogle() => throw UnimplementedError();
}

class _FakeTransferRepository implements EventOwnershipTransferRepository {
  int prepareCalls = 0;
  int acceptCalls = 0;
  int completeCalls = 0;

  @override
  Future<void> prepare({
    required String sourceUid,
    required String handoffSecret,
    required DateTime expiresAt,
  }) async {
    prepareCalls += 1;
  }

  @override
  Future<void> accept({
    required String sourceUid,
    required String handoffSecret,
    required String targetUid,
    required DateTime acceptedExpiresAt,
  }) async {
    acceptCalls += 1;
  }

  @override
  Future<void> complete({
    required String sourceUid,
    required String targetUid,
  }) async {
    completeCalls += 1;
  }
}

class _FakeHandoffStore implements EventOwnershipTransferHandoffStore {
  EventOwnershipTransferHandoff? value;

  @override
  EventOwnershipTransferHandoff? load() => value;

  @override
  void save(EventOwnershipTransferHandoff handoff) {
    value = handoff;
  }

  @override
  void clear() {
    value = null;
  }
}

class _FailingInMemoryEventRepository extends InMemoryEventRepository {
  _FailingInMemoryEventRepository({required this.failOnTransferCall});

  final int failOnTransferCall;
  int transferCalls = 0;

  @override
  Future<SavedEventAggregate> transferOwner({
    required String publicId,
    required String expectedSourceUid,
    required String targetUid,
  }) {
    transferCalls += 1;
    if (transferCalls == failOnTransferCall) {
      throw StateError('simulated transfer failure');
    }
    return super.transferOwner(
      publicId: publicId,
      expectedSourceUid: expectedSourceUid,
      targetUid: targetUid,
    );
  }
}
