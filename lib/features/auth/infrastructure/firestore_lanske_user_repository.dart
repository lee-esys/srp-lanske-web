import 'package:cloud_firestore/cloud_firestore.dart';

import '../application/lanske_user_repository.dart';
import '../domain/lanske_user.dart';

class FirestoreLanskeUserRepository implements LanskeUserRepository {
  FirestoreLanskeUserRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<LanskeUser> ensureUser(String uid) async {
    final ref = _firestore.collection('users').doc(uid);

    final existing = await _firestore.runTransaction<LanskeUser?>((transaction) async {
      final snapshot = await transaction.get(ref);
      if (snapshot.exists) {
        return _fromSnapshot(snapshot);
      }

      transaction.set(ref, <String, Object?>{
        'schemaVersion': LanskeUser.currentSchemaVersion,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return null;
    });

    if (existing != null) {
      return existing;
    }

    final created = await ref.get(const GetOptions(source: Source.server));
    if (!created.exists) {
      throw StateError('Lanske user document was not created.');
    }
    return _fromSnapshot(created);
  }

  LanskeUser _fromSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data();
    final schemaVersion = data?['schemaVersion'];
    final createdAt = data?['createdAt'];

    if (schemaVersion is! int || createdAt is! Timestamp) {
      throw StateError('Invalid Lanske user document: ${snapshot.id}');
    }

    return LanskeUser(
      uid: snapshot.id,
      schemaVersion: schemaVersion,
      createdAt: createdAt.toDate().toUtc(),
    );
  }
}
