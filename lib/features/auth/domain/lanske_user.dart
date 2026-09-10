class LanskeUser {
  const LanskeUser({
    required this.uid,
    required this.schemaVersion,
    required this.createdAt,
    this.externalIdentityIds = const <String, String>{},
  });

  static const int currentSchemaVersion = 1;

  final String uid;
  final int schemaVersion;
  final DateTime createdAt;
  final Map<String, String> externalIdentityIds;

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is LanskeUser &&
            other.uid == uid &&
            other.schemaVersion == schemaVersion &&
            other.createdAt == createdAt &&
            _mapsEqual(other.externalIdentityIds, externalIdentityIds);
  }

  @override
  int get hashCode {
    final entries = externalIdentityIds.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return Object.hash(
      uid,
      schemaVersion,
      createdAt,
      Object.hashAll(
        entries.map((entry) => Object.hash(entry.key, entry.value)),
      ),
    );
  }

  static bool _mapsEqual(Map<String, String> left, Map<String, String> right) {
    if (identical(left, right)) {
      return true;
    }
    if (left.length != right.length) {
      return false;
    }
    for (final entry in left.entries) {
      if (right[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }
}
