class LanskeUser {
  const LanskeUser({
    required this.uid,
    required this.schemaVersion,
    required this.createdAt,
  });

  static const int currentSchemaVersion = 1;

  final String uid;
  final int schemaVersion;
  final DateTime createdAt;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LanskeUser &&
            other.uid == uid &&
            other.schemaVersion == schemaVersion &&
            other.createdAt == createdAt;
  }

  @override
  int get hashCode => Object.hash(uid, schemaVersion, createdAt);
}
