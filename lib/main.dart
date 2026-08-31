import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/app.dart';
import 'features/auth/infrastructure/firebase_auth_repository.dart';
import 'features/auth/presentation/auth_scope.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(
    AuthScope(
      repository: FirebaseAuthRepository(FirebaseAuth.instance),
      child: const App(),
    ),
  );
}
