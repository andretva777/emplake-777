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
    apiKey: 'AIzaSyCeRohGWiD4XWh-d_lLgxGm0xdxiaHZmck',
    appId: '1:337632614086:web:5c94cdf5c1fd623ca529c7',
    messagingSenderId: '337632614086',
    projectId: 'emplake-777',
    authDomain: 'emplake-777.firebaseapp.com',
    storageBucket: 'emplake-777.firebasestorage.app',
  );
}
