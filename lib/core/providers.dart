import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Preferências locais. O valor real é injetado em `main()`.
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider não foi inicializado'),
);

/// Dados mínimos do usuário autenticado.
@immutable
class AppUser {
  const AppUser({required this.uid, this.email, this.displayName});
  final String uid;
  final String? email;
  final String? displayName;

  @override
  bool operator ==(Object other) =>
      other is AppUser &&
      other.uid == uid &&
      other.email == email &&
      other.displayName == displayName;

  @override
  int get hashCode => Object.hash(uid, email, displayName);
}

/// Sessão atual. É um [ChangeNotifier] para poder ser usada como
/// `refreshListenable` do go_router.
class AuthSession extends ChangeNotifier {
  AuthSession([this._user]);

  /// Acompanha o Firebase Auth. Deve ser criada depois de o Firebase já ter
  /// restaurado a sessão (ver `main()`).
  factory AuthSession.firebase(FirebaseAuth auth) {
    final session = AuthSession(_fromFirebase(auth.currentUser));
    session._sub = auth.userChanges().listen(
          (u) => session.user = _fromFirebase(u),
        );
    return session;
  }

  static AppUser? _fromFirebase(User? u) => u == null
      ? null
      : AppUser(uid: u.uid, email: u.email, displayName: u.displayName);

  StreamSubscription<User?>? _sub;
  AppUser? _user;

  AppUser? get user => _user;

  set user(AppUser? value) {
    if (value == _user) return;
    _user = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

/// Sessão de autenticação. O valor real é injetado em `main()`.
final authSessionProvider = Provider<AuthSession>(
  (ref) => throw UnimplementedError('authSessionProvider não foi inicializado'),
);

class CurrentUserNotifier extends Notifier<AppUser?> {
  @override
  AppUser? build() {
    final session = ref.watch(authSessionProvider);
    void listener() => state = session.user;
    session.addListener(listener);
    ref.onDispose(() => session.removeListener(listener));
    return session.user;
  }
}

/// Usuário autenticado (ou `null`), atualizado a cada login/logout.
final currentUserProvider = NotifierProvider<CurrentUserNotifier, AppUser?>(
  CurrentUserNotifier.new,
);
