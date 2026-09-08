enum ExternalIdentitySourceType {
  tennisbear('tennisbear');

  const ExternalIdentitySourceType(this.value);

  final String value;

  static ExternalIdentitySourceType fromValue(String value) {
    return ExternalIdentitySourceType.values.firstWhere(
      (sourceType) => sourceType.value == value,
      orElse: () => throw FormatException(
        'Unsupported external identity source type: $value',
      ),
    );
  }
}

class ExternalIdentity {
  const ExternalIdentity({
    required this.sourceType,
    required this.sourceUserId,
    required this.profileUrl,
  });

  final ExternalIdentitySourceType sourceType;
  final String sourceUserId;
  final String profileUrl;

  String get mappingId => '${sourceType.value}_$sourceUserId';

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ExternalIdentity &&
            other.sourceType == sourceType &&
            other.sourceUserId == sourceUserId &&
            other.profileUrl == profileUrl;
  }

  @override
  int get hashCode => Object.hash(sourceType, sourceUserId, profileUrl);
}

class ExternalIdentityMapping {
  const ExternalIdentityMapping({
    required this.id,
    required this.identity,
    required this.lanskeUserId,
    required this.requestId,
    required this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  static const int currentSchemaVersion = 1;

  final String id;
  final ExternalIdentity identity;
  final String lanskeUserId;
  final String requestId;
  final DateTime approvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;
}
