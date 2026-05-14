import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import 'saved_event_json_store.dart';

class FirestoreSavedEventJsonStore implements SavedEventJsonStore {
  FirestoreSavedEventJsonStore({
    FirebaseFirestore? firestore,
    String collectionPath = 'events',
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _collectionPath = collectionPath;

  final FirebaseFirestore _firestore;
  final String _collectionPath;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection(_collectionPath);
  }

  @override
  Future<void> saveByPublicId({
    required String publicId,
    required Map<String, dynamic> data,
  }) async {
    await _collection.doc(publicId).set(_copy(data));
  }

  @override
  Future<Map<String, dynamic>?> findByPublicId(String publicId) async {
    final snapshot = await _collection.doc(publicId).get();
    final data = snapshot.data();

    if (!snapshot.exists || data == null) {
      return null;
    }

    return _copy(data);
  }

  @override
  Future<Map<String, dynamic>?> findByEventId(String eventId) async {
    final snapshot =
        await _collection.where('event.id', isEqualTo: eventId).limit(1).get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    return _copy(snapshot.docs.first.data());
  }

  Map<String, dynamic> _copy(Map<String, dynamic> data) {
    return jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
  }
}
