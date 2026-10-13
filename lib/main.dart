import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/config/app_config.dart';
import 'features/auth/application/account_service.dart';
import 'features/auth/application/anonymous_event_ownership_transfer_service.dart';
import 'features/auth/infrastructure/firebase_admin_role_reader.dart';
import 'features/auth/infrastructure/firebase_auth_repository.dart';
import 'features/auth/infrastructure/firestore_event_ownership_transfer_repository.dart';
import 'features/auth/infrastructure/firestore_lanske_user_repository.dart';
import 'features/auth/infrastructure/browser_event_ownership_transfer_handoff_store.dart';
import 'features/auth/presentation/account_scope.dart';
import 'features/auth/presentation/admin_role_scope.dart';
import 'features/auth/presentation/auth_scope.dart';
import 'features/external_identity/application/external_identity_link_service.dart';
import 'features/external_identity/application/tennisbear_admin_profile_link_review_service.dart';
import 'features/external_identity/application/tennisbear_profile_link_service.dart';
import 'features/external_identity/infrastructure/firestore_external_identity_link_repository.dart';
import 'features/external_identity/infrastructure/firestore_external_identity_user_reader.dart';
import 'features/external_identity/presentation/external_identity_admin_review_scope.dart';
import 'features/external_identity/presentation/external_identity_link_scope.dart';
import 'features/participation_history/application/participation_history_service.dart';
import 'features/participation_history/infrastructure/firestore_participation_history_repository.dart';
import 'features/participation_history/presentation/participation_history_scope.dart';
import 'firebase_options.dart';
import 'shared/repositories/app_repositories.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Preserve the existing production configuration unless dev is explicit.
  validateFirebaseProject(AppConfig.firebaseProject);
  final FirebaseOptions firebaseOptions;
  if (AppConfig.firebaseProject == 'dev') {
    if (!kIsWeb) {
      throw StateError('LANSKE_FIREBASE_PROJECT=dev is supported for Web only');
    }
    if (AppConfig.firebaseDevApiKey.isEmpty ||
        AppConfig.firebaseDevAppId.isEmpty ||
        AppConfig.firebaseDevMessagingSenderId.isEmpty) {
      throw StateError(
        'Missing dev Web Firebase SDK configuration. '
        'Set LANSKE_FIREBASE_DEV_API_KEY, LANSKE_FIREBASE_DEV_APP_ID '
        'and LANSKE_FIREBASE_DEV_MESSAGING_SENDER_ID.',
      );
    }
    firebaseOptions = FirebaseOptions(
      apiKey: AppConfig.firebaseDevApiKey,
      appId: AppConfig.firebaseDevAppId,
      messagingSenderId: AppConfig.firebaseDevMessagingSenderId,
      projectId: 'srp-lanske-web-dev',
      authDomain: 'srp-lanske-web-dev.firebaseapp.com',
      storageBucket: 'srp-lanske-web-dev.firebasestorage.app',
    );
  } else {
    final defaults = DefaultFirebaseOptions.currentPlatform;
    firebaseOptions =
        kIsWeb ? defaults.copyWith(authDomain: 'lanske.jp') : defaults;
  }
  await Firebase.initializeApp(options: firebaseOptions);

  final firestore = FirebaseFirestore.instance;
  final firebaseAuth = FirebaseAuth.instance;
  final authRepository = FirebaseAuthRepository(firebaseAuth);
  final adminRoleReader = FirebaseAdminRoleReader(firebaseAuth);
  final lanskeUserRepository = FirestoreLanskeUserRepository(firestore);
  final accountService = AccountService(
    authRepository: authRepository,
    userRepository: lanskeUserRepository,
  );
  final ownershipTransferService = AnonymousEventOwnershipTransferService(
    authRepository: authRepository,
    eventRepository: appEventRepository,
    transferRepository: FirestoreEventOwnershipTransferRepository(firestore),
    handoffStore: BrowserEventOwnershipTransferHandoffStore(),
  );
  final externalIdentityLinkService = ExternalIdentityLinkService(
    repository: FirestoreExternalIdentityLinkRepository(firestore),
  );
  final identityUserReader = FirestoreExternalIdentityUserReader(firestore);
  final tennisBearProfileLinkService = TennisBearProfileLinkService(
    linkService: externalIdentityLinkService,
    userReader: identityUserReader,
  );
  final participationHistoryService = ParticipationHistoryService(
    identityReader: identityUserReader,
    historyRepository: FirestoreParticipationHistoryRepository(firestore),
  );
  final tennisBearAdminProfileLinkReviewService =
      TennisBearAdminProfileLinkReviewService(
    authRepository: authRepository,
    adminRoleReader: adminRoleReader,
    linkService: externalIdentityLinkService,
  );

  runApp(
    AuthScope(
      repository: authRepository,
      child: AdminRoleScope(
        reader: adminRoleReader,
        child: AccountScope(
          service: accountService,
          ownershipTransferService: ownershipTransferService,
          child: ExternalIdentityLinkScope(
            service: tennisBearProfileLinkService,
            child: ParticipationHistoryScope(
              service: participationHistoryService,
              child: ExternalIdentityAdminReviewScope(
                service: tennisBearAdminProfileLinkReviewService,
                child: const App(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
