import 'dart:convert';
import 'dart:math';

import '../../doubles_scheduler/application/event_repository.dart';
import '../domain/account_transition.dart';
import '../domain/event_ownership_transfer.dart';
import 'account_auth_repository.dart';
import 'event_ownership_transfer_handoff_store.dart';
import 'event_ownership_transfer_repository.dart';

class AnonymousEventOwnershipTransferService {
  AnonymousEventOwnershipTransferService({
    required AccountAuthRepository authRepository,
    required EventRepository eventRepository,
    required EventOwnershipTransferRepository transferRepository,
    required EventOwnershipTransferHandoffStore handoffStore,
    DateTime Function()? clock,
    String Function()? handoffSecretGenerator,
  })  : _authRepository = authRepository,
        _eventRepository = eventRepository,
        _transferRepository = transferRepository,
        _handoffStore = handoffStore,
        _clock = clock ?? DateTime.now,
        _handoffSecretGenerator =
            handoffSecretGenerator ?? _generateSecureHandoffSecret;

  static const Duration pendingAuthorizationLifetime = Duration(hours: 1);
  static const Duration acceptedAuthorizationLifetime = Duration(hours: 1);

  final AccountAuthRepository _authRepository;
  final EventRepository _eventRepository;
  final EventOwnershipTransferRepository _transferRepository;
  final EventOwnershipTransferHandoffStore _handoffStore;
  final DateTime Function() _clock;
  final String Function() _handoffSecretGenerator;

  EventOwnershipTransferHandoff? loadPendingHandoff() {
    final handoff = _handoffStore.load();
    if (handoff == null) {
      return null;
    }
    if (handoff.isExpired(_clock().toUtc())) {
      _handoffStore.clear();
      return null;
    }
    if (handoff.sourceUid.isEmpty || handoff.handoffSecret.isEmpty) {
      _handoffStore.clear();
      return null;
    }
    return handoff;
  }

  Future<EventOwnershipTransferHandoff> prepare(
    AccountTransitionResult collision,
  ) async {
    if (!collision.requiresOwnershipMigration) {
      throw const EventOwnershipTransferRequiredException(
        'An existing-account collision is required.',
      );
    }

    final session = _authRepository.currentSession;
    if (!session.isAnonymous || session.uid != collision.sourceUid) {
      throw const EventOwnershipTransferRequiredException(
        'The source anonymous session is no longer active.',
      );
    }

    final now = _clock().toUtc();
    final handoff = EventOwnershipTransferHandoff(
      sourceUid: collision.sourceUid,
      handoffSecret: _handoffSecretGenerator(),
      expiresAt: now.add(pendingAuthorizationLifetime),
    );

    await _transferRepository.prepare(
      sourceUid: handoff.sourceUid,
      handoffSecret: handoff.handoffSecret,
      expiresAt: handoff.expiresAt,
    );
    _handoffStore.save(handoff);
    return handoff;
  }

  Future<EventOwnershipTransferResult> resumeForCurrentAccount() async {
    final handoff = loadPendingHandoff();
    if (handoff == null) {
      throw const EventOwnershipTransferRequiredException(
        'No active ownership handoff was found.',
      );
    }

    final session = _authRepository.currentSession;
    final targetUid = session.uid;
    if (!session.isAccount || targetUid == null) {
      throw const EventOwnershipTransferRequiredException(
        'A registered target account session is required.',
      );
    }
    if (targetUid == handoff.sourceUid) {
      throw const EventOwnershipTransferRequiredException(
        'The target account must differ from the anonymous source.',
      );
    }

    final acceptedExpiresAt =
        _clock().toUtc().add(acceptedAuthorizationLifetime);
    await _transferRepository.accept(
      sourceUid: handoff.sourceUid,
      handoffSecret: handoff.handoffSecret,
      targetUid: targetUid,
      acceptedExpiresAt: acceptedExpiresAt,
    );

    final sourceEvents =
        await _eventRepository.listByOwnerUid(handoff.sourceUid);
    var transferredCount = 0;
    for (final aggregate in sourceEvents) {
      await _eventRepository.transferOwner(
        publicId: aggregate.event.publicId,
        expectedSourceUid: handoff.sourceUid,
        targetUid: targetUid,
      );
      transferredCount += 1;
    }

    await _transferRepository.complete(
      sourceUid: handoff.sourceUid,
      targetUid: targetUid,
    );
    _handoffStore.clear();

    return EventOwnershipTransferResult(
      sourceUid: handoff.sourceUid,
      targetUid: targetUid,
      transferredEventCount: transferredCount,
    );
  }

  void abandonPreparedHandoff() {
    final handoff = loadPendingHandoff();
    if (handoff == null) {
      return;
    }

    final session = _authRepository.currentSession;
    if (!session.isAnonymous || session.uid != handoff.sourceUid) {
      throw const EventOwnershipTransferRequiredException(
        'Only the active anonymous source can abandon this handoff locally.',
      );
    }
    _handoffStore.clear();
  }

  static String _generateSecureHandoffSecret() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
