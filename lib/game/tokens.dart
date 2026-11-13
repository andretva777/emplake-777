/// Operadores que o jogador pode inserir entre os dígitos da placa.
enum Tok {
  plus('+', '+'),
  minus('−', '-'),
  times('×', '*'),
  divide('÷', '/'),
  lparen('(', '('),
  rparen(')', ')'),
  sqrt('√', 'r'),
  cbrt('∛', 'c'),
  fact('!', '!'),
  pow('**', '^'),
  abs('|', '|'),
  floorL('⌊', '['),
  floorR('⌋', ']'),
  ceilL('⌈', '{'),
  ceilR('⌉', '}');

  const Tok(this.symbol, this.code);

  /// Símbolo mostrado ao jogador.
  final String symbol;

  /// Código de um caractere usado para persistir a expressão.
  final String code;

  static Tok? fromCode(String code) {
    for (final t in values) {
      if (t.code == code) return t;
    }
    return null;
  }
}

/// Níveis de jogo. Quanto menos operadores disponíveis, mais difícil.
/// Quais operadores valem numa partida e se a divisão pode dar resultado
/// não inteiro. Os níveis seguem regras fixas; a aventura libera operadores
/// aos poucos.
abstract interface class OperatorRules {
  bool allows(Tok t);
  bool get allowsFractions;
}

enum Level implements OperatorRules {
  easy(1, [
    Tok.plus, Tok.minus, Tok.times, Tok.divide, Tok.lparen, Tok.rparen, //
    Tok.sqrt, Tok.cbrt, Tok.fact, Tok.pow, Tok.abs,
    Tok.floorL, Tok.floorR, Tok.ceilL, Tok.ceilR,
  ]),
  intermediate(2, [
    Tok.plus, Tok.minus, Tok.times, Tok.divide, Tok.lparen, Tok.rparen, //
    Tok.sqrt, Tok.cbrt, Tok.fact, Tok.pow, Tok.abs,
  ]),
  advanced(3, [
    Tok.plus, Tok.minus, Tok.times, Tok.divide, Tok.lparen, Tok.rparen, //
    Tok.sqrt, Tok.fact, Tok.abs,
  ]),
  hard(5, [
    Tok.plus, Tok.minus, Tok.times, Tok.divide, Tok.lparen, Tok.rparen, //
    Tok.abs,
  ]);

  const Level(this.points, this.operators);

  /// Pontos ganhos ao resolver uma placa neste nível.
  final int points;

  /// Operadores liberados neste nível.
  final List<Tok> operators;

  /// Apenas o nível fácil aceita divisão com resultado não inteiro.
  @override
  bool get allowsFractions => this == Level.easy;

  @override
  bool allows(Tok t) => operators.contains(t);

  static Level fromName(String? name) =>
      values.firstWhere((l) => l.name == name, orElse: () => Level.easy);
}

/// Uma peça da linha de montagem da equação.
sealed class Piece {
  const Piece(this.id);

  /// Identificador estável (usado em chaves de widgets e animações).
  final int id;
}

class DigitPiece extends Piece {
  const DigitPiece(super.id, this.value);
  final int value;
}

class EqualsPiece extends Piece {
  const EqualsPiece(super.id);
}

class OpPiece extends Piece {
  const OpPiece(super.id, this.tok);
  final Tok tok;
}
