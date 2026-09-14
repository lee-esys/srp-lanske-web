import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'features/auth/application/account_service.dart';
import 'features/auth/infrastructure/firebase_admin_role_reader.dart';
import 'features/auth/infrastructure/firebase_auth_repository.dart';
import 'features/auth/infrastructure/firestore_lanske_user_repository.dart';
import 'features/auth/presentation/account_scope.dart';
import 'features/auth/presentation/admin_role_scope.dart';
import 'features/auth/presentation/auth_scope.dart';
import 'features/external_identity/application/external_identity_link_service.dart';
import 'features/external_identity/application/tennisbear_profile_link_service.dart';
import 'features/external_identity/infrastructure/firestore_external_identity_link_repository.dart';
import 'features/external_identity/infrastructure/firestore_external_identity_user_reader.dart';
import 'features/external_identity/presentation/external_identity_link_scope.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseOptions = DefaultFirebaseOptions.currentPlatform;
  await Firebase.initializeApp(
    options: kIsWeb
        ? firebaseOptions.copyWith(authDomain: 'lanske.jp')
        : firebaseOptions,
  );

  final firestore = FirebaseFirestore.instance;
  final firebaseAuth = FirebaseAuth.instance;
  final authRepository = FirebaseAuthRepository(firebaseAuth);
  final adminRoleReader = FirebaseAdminRoleReader(firebaseAuth);
  final accountService = AccountService(
    authRepository: authRepository,
    userRepository: FirestoreLanskeUserRepository(firestore),
  );
  final externalIdentityLinkService = ExternalIdentityLinkService(
    repository: FirestoreExternalIdentityLinkRepository(firestore),
  );
  final tennisBearProfileLinkService = TennisBearProfileLinkService(
    linkService: externalIdentityLinkService,
    userReader: FirestoreExternalIdentityUserReader(firestore),
  );

  runApp(
    AuthScope(
      repository: authRepository,
      child: AdminRoleScope(
        reader: adminRoleReader,
        child: AccountScope(
          service: accountService,
          child: ExternalIdentityLinkScope(
            service: tennisBearProfileLinkService,
            child: const App(),
          ),
        ),
      ),
    ),
  );
}
