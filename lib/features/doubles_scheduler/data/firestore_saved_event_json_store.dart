import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:srp_lanske/shared/infrastructure/firestore_provenance.dart';

import '../application/event_repository.dart';
import '../domain/saved_event_models.dart';
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
  Future<List<Map<String, dynamic>>> listByOwnerUid(String ownerUid) async {
    final snapshot =
        await _collection.where('event.ownerUid', isEqualTo: ownerUid).get();

    return snapshot.docs
        .map((document) => _copy(document.data()))
        .toList(growable: false);
  }

  @override
  Future<Map<String, dynamic>?> updateByPublicId({
    required String publicId,
    required SavedEventJsonUpdater update,
  }) async {
    final reference = _collection.doc(publicId);

    final transactionResult =
        await _firestore.runTransaction<Map<String, dynamic>?>(
      (transaction) async {
        final snapshot = await transaction.get(reference);
        final data = snapshot.data();
        if (!snapshot.exists || data == null) {
          return null;
        }

        try {
          final result = update(_copy(data));
          if (result.isNoOp) {
            return <String, dynamic>{
              'kind': 'data',
              'data': _copy(result.data),
            };
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

          return <String, dynamic>{
            'kind': 'data',
            'data': _copy(updatedData),
          };
        } on EventRevisionConflictException catch (error) {
          return <String, dynamic>{
            'kind': 'revisionConflict',
            'eventId': error.eventId,
            'expectedRevision': error.expectedRevision,
            'actualRevision': error.actualRevision,
          };
        } on ScheduleStateConflictException catch (error) {
          return <String, dynamic>{
            'kind': 'scheduleStateConflict',
            'eventId': error.eventId,
            'expectedCurrentGeneratedScheduleId':
                error.expectedCurrentGeneratedScheduleId,
            'actualCurrentGeneratedScheduleId':
                error.actualCurrentGeneratedScheduleId,
            'actualAdoptedGeneratedScheduleId':
                error.actualAdoptedGeneratedScheduleId,
            'actualStatus': error.actualStatus.name,
          };
        }
      },
    );

    if (transactionResult == null) {
      return null;
    }

    if (transactionResult['kind'] == 'revisionConflict') {
      throw EventRevisionConflictException(
        eventId: transactionResult['eventId']?.toString() ?? '',
        expectedRevision:
            _requireTransactionInt(transactionResult['expectedRevision']),
        actualRevision:
            _requireTransactionInt(transactionResult['actualRevision']),
      );
    }

    if (transactionResult['kind'] == 'scheduleStateConflict') {
      throw ScheduleStateConflictException(
        eventId: transactionResult['eventId']?.toString() ?? '',
        expectedCurrentGeneratedScheduleId:
            transactionResult['expectedCurrentGeneratedScheduleId']?.toString(),
        actualCurrentGeneratedScheduleId:
            transactionResult['actualCurrentGeneratedScheduleId']?.toString(),
        actualAdoptedGeneratedScheduleId:
            transactionResult['actualAdoptedGeneratedScheduleId']?.toString(),
        actualStatus: _requireSavedEventStatus(transactionResult['actualStatus']),
      );
    }

    final rawData = transactionResult['data'];
    if (rawData is! Map) {
      throw StateError('invalid Firestore transaction result');
    }

    return _copy(
      rawData.map(
        (key, value) => MapEntry(key.toString(), value),
      ),
    );
  }

  int _requireTransactionInt(Object? value) {
    if (value is int) {
      return value;
    }
    if (value is num) {
      return value.toInt();
    }

    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed == null) {
      throw StateError('invalid Firestore transaction revision: $value');
    }
    return parsed;
  }

  SavedEventStatus _requireSavedEventStatus(Object? value) {
    final name = value?.toString();
    for (final status in SavedEventStatus.values) {
      if (status.name == name) {
        return status;
      }
    }

    throw StateError('invalid Firestore transaction status: $value');
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
