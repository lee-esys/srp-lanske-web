import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:srp_lanske/shared/infrastructure/firestore_provenance.dart';

import 'saved_event_json_store.dart';

class FirestoreSavedEventJsonStore implements SavedEventJsonStore {
  FirestoreSavedEventJsonStore({
    FirebaseFirestore? firestore,
    String collectionPath = 'events',
    FirestoreWriteOrigin Function()? writeOriginProvider,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _collectionPath = collectionPath,
        _writeOriginProvider = writeOriginProvider;

  final FirebaseFirestore _firestore;
  final String _collectionPath;
  final FirestoreWriteOrigin Function()? _writeOriginProvider;

  CollectionReference<Map<String, dynamic>> get _collection {
    return _firestore.collection(_collectionPath);
  }

  @override
  Future<void> saveByPublicId({
    required String publicId,
    required Map<String, dynamic> data,
  }) async {
    final stored = withCreatedFirestoreProvenance(
      data: _copy(data),
      origin: _currentWriteOrigin(),
    );
    await _collection.doc(publicId).set(_copy(stored));
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

  @override
  Future<Map<String, dynamic>?> updateByPublicId({
    required String publicId,
    required SavedEventJsonUpdater update,
  }) {
    final reference = _collection.doc(publicId);

    return _firestore.runTransaction<Map<String, dynamic>?>(
      (transaction) async {
        final snapshot = await transaction.get(reference);
        final data = snapshot.data();
        if (!snapshot.exists || data == null) {
          return null;
        }

        final result = update(_copy(data));
        if (result.isNoOp) {
          return _copy(result.data);
        }

        final updatedData = withUpdatedFirestoreProvenance(
          data: _copy(result.data),
          currentProvenance: data['provenance'],
          origin: _currentWriteOrigin(),
        );
        final provenance = updatedData['provenance'];

        transaction.update(
          reference,
          _copy(<String, dynamic>{
            ...result.fields,
            'provenance': provenance,
          }),
        );

        return _copy(updatedData);
      },
    );
  }

  FirestoreWriteOrigin _currentWriteOrigin() {
    return _writeOriginProvider?.call() ??
        FirestoreWriteOrigin.current(
          firebaseProjectId: _firestore.app.options.projectId,
        );
  }

  Map<String, dynamic> _copy(Map<String, dynamic> data) {
    return jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
  }
}
