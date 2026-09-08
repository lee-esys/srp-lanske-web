import 'external_identity.dart';

enum ExternalIdentityLinkRequestState {
  pending('pending'),
  approved('approved'),
  rejected('rejected'),
  canceled('canceled'),
  expired('expired'),
  superseded('superseded');

  const ExternalIdentityLinkRequestState(this.value);

  final String value;

  static ExternalIdentityLinkRequestState fromValue(String value) {
    return ExternalIdentityLinkRequestState.values.firstWhere(
      (state) => state.value == value,
      orElse: () => throw FormatException(
        'Unsupported external identity link request state: $value',
      ),
    );
  }
}

class ExternalIdentityLinkRequest {
  const ExternalIdentityLinkRequest({
    required this.id,
    required this.lanskeUserId,
    required this.identity,
    required this.state,
    required this.confirmationCodeHash,
    required this.confirmationCodeExpiresAt,
    required this.createdAt,
    required this.updatedAt,
    this.approvedAt,
    this.rejectedAt,
    this.canceledAt,
    this.unlinkedAt,
    this.supersededByRequestId,
  });

  static const int currentSchemaVersion = 1;

  final String id;
  final String lanskeUserId;
  final ExternalIdentity identity;
  final ExternalIdentityLinkRequestState state;
  final String confirmationCodeHash;
  final DateTime confirmationCodeExpiresAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? approvedAt;
  final DateTime? rejectedAt;
  final DateTime? canceledAt;
  final DateTime? unlinkedAt;
  final String? supersededByRequestId;

  bool isConfirmationCodeExpired(DateTime now) {
    return !confirmationCodeExpiresAt.isAfter(now.toUtc());
  }
}
