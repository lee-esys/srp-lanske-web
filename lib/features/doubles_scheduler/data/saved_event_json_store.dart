typedef SavedEventJsonUpdater = SavedEventJsonUpdate Function(
  Map<String, dynamic> current,
);

class SavedEventJsonUpdate {
  const SavedEventJsonUpdate({
    required this.data,
    required this.fields,
  });

  factory SavedEventJsonUpdate.noOp(Map<String, dynamic> data) {
    return SavedEventJsonUpdate(
      data: data,
      fields: const <String, dynamic>{},
    );
  }

  final Map<String, dynamic> data;
  final Map<String, dynamic> fields;

  bool get isNoOp => fields.isEmpty;
}

abstract class SavedEventJsonStore {
  Future<void> saveByPublicId({
    required String publicId,
    required Map<String, dynamic> data,
  });

  Future<Map<String, dynamic>?> findByPublicId(String publicId);

  Future<Map<String, dynamic>?> findByEventId(String eventId);

  Future<Map<String, dynamic>?> updateByPublicId({
    required String publicId,
    required SavedEventJsonUpdater update,
  }) {
    throw UnimplementedError('updateByPublicId is not implemented');
  }
}
