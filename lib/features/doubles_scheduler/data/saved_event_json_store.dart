abstract class SavedEventJsonStore {
  Future<void> saveByPublicId({
    required String publicId,
    required Map<String, dynamic> data,
  });

  Future<Map<String, dynamic>?> findByPublicId(String publicId);

  Future<Map<String, dynamic>?> findByEventId(String eventId);
}
