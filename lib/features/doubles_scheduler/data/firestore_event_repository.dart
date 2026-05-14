import 'package:cloud_firestore/cloud_firestore.dart';

import 'firestore_saved_event_json_store.dart';
import 'json_event_repository.dart';

class FirestoreEventRepository extends JsonEventRepository {
  FirestoreEventRepository({
    FirebaseFirestore? firestore,
    String collectionPath = 'events',
    super.publicIdGenerator,
  }) : super(
          store: FirestoreSavedEventJsonStore(
            firestore: firestore,
            collectionPath: collectionPath,
          ),
        );
}
