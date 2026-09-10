import '../domain/confirmation_code.dart';
import '../domain/external_identity.dart';
import '../domain/external_identity_link_request.dart';
import '../domain/tennisbear_profile_url_parser.dart';
import 'external_identity_link_exception.dart';
import 'external_identity_link_repository.dart';

class IssuedExternalIdentityLinkRequest {
  const IssuedExternalIdentityLinkRequest({
    required this.request,
    required this.confirmationCode,
  });

  final ExternalIdentityLinkRequest request;
  final String confirmationCode;
}

class ExternalIdentityLinkService {
  ExternalIdentityLinkService({
    required ExternalIdentityLinkRepository repository,
    ConfirmationCodeIssuer? confirmationCodeIssuer,
    TennisBearProfileUrlParser? tennisBearProfileUrlParser,
    DateTime Function()? now,
  })  : _repository = repository,
        _confirmationCodeIssuer =
            confirmationCodeIssuer ?? ConfirmationCodeIssuer(),
        _tennisBearProfileUrlParser =
            tennisBearProfileUrlParser ?? const TennisBearProfileUrlParser(),
        _now = now ?? DateTime.now;

  static const confirmationCodeValidity = Duration(days: 7);

  final ExternalIdentityLinkRepository _repository;
  final ConfirmationCodeIssuer _confirmationCodeIssuer;
  final TennisBearProfileUrlParser _tennisBearProfileUrlParser;
  final DateTime Function() _now;

  Future<IssuedExternalIdentityLinkRequest> createTennisBearRequest({
    required String lanskeUserId,
    required String profileUrl,
  }) async {
    final identity = _tennisBearProfileUrlParser.parse(profileUrl);
    final issuedCode = _confirmationCodeIssuer.issue();
    final now = _now().toUtc();
    final request = await _repository.createRequest(
      lanskeUserId: lanskeUserId,
      identity: identity,
      confirmationCodeHash: issuedCode.hash,
      confirmationCodeExpiresAt: now.add(confirmationCodeValidity),
    );

    return IssuedExternalIdentityLinkRequest(
      request: request,
      confirmationCode: issuedCode.displayCode,
    );
  }

  Future<IssuedExternalIdentityLinkRequest> reissue({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
  }) async {
    final issuedCode = _confirmationCodeIssuer.issue();
    final now = _now().toUtc();
    final request = await _repository.reissueRequest(
      lanskeUserId: lanskeUserId,
      sourceType: sourceType,
      confirmationCodeHash: issuedCode.hash,
      confirmationCodeExpiresAt: now.add(confirmationCodeValidity),
    );

    return IssuedExternalIdentityLinkRequest(
      request: request,
      confirmationCode: issuedCode.displayCode,
    );
  }

  Future<ExternalIdentityLinkRequest?> getActiveRequest({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
  }) {
    return _repository.getActiveRequest(
      lanskeUserId: lanskeUserId,
      sourceType: sourceType,
    );
  }

  Future<void> cancelRequest({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
  }) {
    return _repository.cancelRequest(
      lanskeUserId: lanskeUserId,
      sourceType: sourceType,
    );
  }

  Future<ExternalIdentityLinkRequest?> findByConfirmationCode(
    String confirmationCode,
  ) {
    return _repository.findRequestByConfirmationCodeHash(
      _confirmationCodeIssuer.hash(confirmationCode),
    );
  }

  Future<ExternalIdentityMapping> approveByConfirmationCode({
    required String confirmationCode,
    required String approvedBy,
  }) async {
    final codeHash = _confirmationCodeIssuer.hash(confirmationCode);
    final request =
        await _repository.findRequestByConfirmationCodeHash(codeHash);
    if (request == null) {
      throw const ExternalIdentityLinkException(
        ExternalIdentityLinkFailureCode.confirmationCodeNotFound,
      );
    }

    final now = _now().toUtc();
    if (request.isConfirmationCodeExpired(now)) {
      throw const ExternalIdentityLinkException(
        ExternalIdentityLinkFailureCode.confirmationCodeExpired,
      );
    }

    return _repository.approveRequest(
      requestId: request.id,
      expectedConfirmationCodeHash: codeHash,
      approvedBy: approvedBy,
      now: now,
    );
  }

  Future<void> rejectByConfirmationCode({
    required String confirmationCode,
    required String rejectedBy,
  }) async {
    final codeHash = _confirmationCodeIssuer.hash(confirmationCode);
    final request =
        await _repository.findRequestByConfirmationCodeHash(codeHash);
    if (request == null) {
      throw const ExternalIdentityLinkException(
        ExternalIdentityLinkFailureCode.confirmationCodeNotFound,
      );
    }

    return _repository.rejectRequest(
      requestId: request.id,
      expectedConfirmationCodeHash: codeHash,
      rejectedBy: rejectedBy,
      now: _now().toUtc(),
    );
  }

  Future<void> unlink({
    required String lanskeUserId,
    required ExternalIdentitySourceType sourceType,
  }) {
    return _repository.unlink(
      lanskeUserId: lanskeUserId,
      sourceType: sourceType,
    );
  }
}
