import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';

/// Modos de jogo.
enum GameMode {
  /// Placas sorteadas entre as que o jogador ainda não resolveu.
  random,

  /// O jogador digita os quatro dígitos da placa.
  specific,

  /// Sobrevivência com dinheiro: operadores avançados são comprados.
  adventure;

  static GameMode fromName(String? name) =>
      values.firstWhere((m) => m.name == name, orElse: () => GameMode.random);
}

/// Modo escolhido, salvo para reabrir o aplicativo no mesmo modo.
class GameModeController extends Notifier<GameMode> {
  static const prefsKey = 'game.mode';

  @override
  GameMode build() => GameMode.fromName(
        ref.read(sharedPrefsProvider).getString(prefsKey),
      );

  void select(GameMode mode) {
    if (mode == state) return;
    state = mode;
    ref.read(sharedPrefsProvider).setString(prefsKey, mode.name);
  }
}

final gameModeProvider = NotifierProvider<GameModeController, GameMode>(
  GameModeController.new,
);
