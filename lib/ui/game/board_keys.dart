import 'package:flutter/widgets.dart';

import '../../game/tokens.dart';

/// Chaves globais das teclas e das peças de um tabuleiro, usadas para achar
/// a posição delas na tela (animação dos operadores voltando ao teclado).
///
/// Cada tabuleiro tem as suas: durante a troca de modo, dois tabuleiros ficam
/// na tela ao mesmo tempo, e chaves derivadas só do operador ou da peça
/// seriam duplicadas.
class BoardKeys {
  final Map<Tok, GlobalKey> _operators = {};
  final Map<int, GlobalKey> _pieces = {};

  /// Tecla do operador no teclado.
  GlobalKey operator(Tok tok) =>
      _operators.putIfAbsent(tok, () => GlobalKey(debugLabel: 'op $tok'));

  /// Peça na linha da equação (pelo identificador da peça).
  GlobalKey piece(Piece piece) =>
      _pieces.putIfAbsent(piece.id, () => GlobalKey(debugLabel: 'piece'));
}
