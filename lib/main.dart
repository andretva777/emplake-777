import 'package:firebase_auth/firebase_auth.dart' hide EmailAuthProvider;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:firebase_ui_oauth_google/firebase_ui_oauth_google.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/constants.dart';
import 'core/providers.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Login por e-mail/senha e pelo Google, gerenciados pelo Firebase.
  FirebaseUIAuth.configureProviders([
    EmailAuthProvider(),
    GoogleProvider(clientId: googleWebClientId),
  ]);

  // Espera o Firebase restaurar a sessão salva para que o aplicativo abra
  // direto na última página, sem piscar a tela de login.
  final auth = FirebaseAuth.instance;
  try {
    await auth.authStateChanges().first.timeout(const Duration(seconds: 5));
  } catch (_) {
    // Sem resposta: segue como deslogado e o roteador mostra o login.
  }

  runApp(
    ProviderScope(
      overrides: [
        sharedPrefsProvider.overrideWithValue(prefs),
        authSessionProvider.overrideWithValue(AuthSession.firebase(auth)),
      ],
      child: const EmplakeApp(),
    ),
  );
}
