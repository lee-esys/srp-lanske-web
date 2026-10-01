class PlayerExternalIdentity {
  const PlayerExternalIdentity({
    required this.sourceType,
    required this.sourceUserId,
    this.profileUrl,
  });

  final String sourceType;
  final String sourceUserId;
  final String? profileUrl;

  Map<String, dynamic> toJson() {
    return {
      'sourceType': sourceType,
      'sourceUserId': sourceUserId,
      'profileUrl': profileUrl,
    };
  }

  factory PlayerExternalIdentity.fromJson(Map<String, dynamic> json) {
    return PlayerExternalIdentity(
      sourceType: json['sourceType']?.toString() ?? '',
      sourceUserId: json['sourceUserId']?.toString() ?? '',
      profileUrl: json['profileUrl']?.toString(),
    );
  }
}

class PlayerSourceProfileSnapshot {
  const PlayerSourceProfileSnapshot({
    required this.sourceDisplayName,
    required this.observedAt,
    this.imageUrl,
    this.levelId,
    this.levelName,
    this.gender,
    this.ageGroup,
    this.pickleballLevelId,
    this.pickleballLevelName,
    this.sourceStatus,
    this.isGuest,
  });

  final String sourceDisplayName;
  final DateTime observedAt;
  final String? imageUrl;
  final int? levelId;
  final String? levelName;
  final String? gender;
  final String? ageGroup;
  final int? pickleballLevelId;
  final String? pickleballLevelName;
  final String? sourceStatus;
  final bool? isGuest;

  Map<String, dynamic> toJson() {
    return {
      'sourceDisplayName': sourceDisplayName,
      'imageUrl': imageUrl,
      'levelId': levelId,
      'levelName': levelName,
      'gender': gender,
      'ageGroup': ageGroup,
      'pickleballLevelId': pickleballLevelId,
      'pickleballLevelName': pickleballLevelName,
      'sourceStatus': sourceStatus,
      'isGuest': isGuest,
      'observedAt': observedAt.toIso8601String(),
    };
  }

  factory PlayerSourceProfileSnapshot.fromJson(Map<String, dynamic> json) {
    return PlayerSourceProfileSnapshot(
      sourceDisplayName: json['sourceDisplayName']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      levelId: _nullableInt(json['levelId']),
      levelName: json['levelName']?.toString(),
      gender: json['gender']?.toString(),
      ageGroup: json['ageGroup']?.toString(),
      pickleballLevelId: _nullableInt(json['pickleballLevelId']),
      pickleballLevelName: json['pickleballLevelName']?.toString(),
      sourceStatus: json['sourceStatus']?.toString(),
      isGuest: json['isGuest'] is bool ? json['isGuest'] as bool : null,
      observedAt: DateTime.parse(json['observedAt'].toString()),
    );
  }
}

int? _nullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}
