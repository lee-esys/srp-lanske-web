import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'features/auth/application/account_service.dart';
import 'features/auth/infrastructure/firebase_auth_repository.dart';
import 'features/auth/infrastructure/firestore_lanske_user_repository.dart';
import 'features/auth/presentation/account_scope.dart';
import 'features/auth/presentation/auth_scope.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final firebaseOptions = DefaultFirebaseOptions.currentPlatform;
  await Firebase.initializeApp(
    options: kIsWeb
        ? firebaseOptions.copyWith(authDomain: 'lanske.jp')
        : firebaseOptions,
  );

  final authRepository = FirebaseAuthRepository(FirebaseAuth.instance);
  final accountService = AccountService(
    authRepository: authRepository,
    userRepository: FirestoreLanskeUserRepository(FirebaseFirestore.instance),
  );

  runApp(
    AuthScope(
      repository: authRepository,
      child: AccountScope(
        service: accountService,
        child: const App(),
      ),
    ),
  );
}
