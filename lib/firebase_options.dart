// ATENÇÃO: este arquivo contém valores de exemplo.
//
// Gere o arquivo real com o FlutterFire CLI, que sobrescreve este:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure --platforms=web
//
// ignore_for_file: type=lint
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    throw UnsupportedError(
      'Este projeto foi configurado apenas para a web. '
      'Rode "flutterfire configure" para adicionar outras plataformas.',
    );
  }

  /// Verdadeiro enquanto os valores de exemplo não forem substituídos.
  static bool get isPlaceholder => web.apiKey.startsWith('SUBSTITUA');

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'SUBSTITUA_PELA_API_KEY',
    appId: 'SUBSTITUA_PELO_APP_ID',
    messagingSenderId: 'SUBSTITUA_PELO_SENDER_ID',
    projectId: 'SUBSTITUA_PELO_PROJECT_ID',
    authDomain: 'SUBSTITUA_PELO_PROJECT_ID.firebaseapp.com',
    storageBucket: 'SUBSTITUA_PELO_PROJECT_ID.firebasestorage.app',
  );
}
