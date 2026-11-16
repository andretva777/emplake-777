import 'dart:math' as math;

import 'tokens.dart';

/// Tipos de erro que uma expressão pode gerar. A tradução fica na interface.
enum ExprErrorKind {
  emptySide,
  missingOperator,
  missingOperand,
  unbalanced,
  unexpected,
  divisionByZero,
  nonIntegerDivision,
  negativeRoot,
  invalidFactorial,
  invalidPower,
  overflow,
  notAllowed,
}

class ExprError implements Exception {
  const ExprError(this.kind, [this.detail]);
  final ExprErrorKind kind;

  /// Símbolo relacionado ao erro, quando houver.
  final String? detail;

  @override
  String toString() => 'ExprError($kind, $detail)';
}

const double _eps = 1e-9;
const double _maxMagnitude = 1e15;

bool isIntegerValue(double v) => (v - v.roundToDouble()).abs() < _eps;

/// Compara dois valores com tolerância relativa.
bool nearlyEqual(double a, double b) {
  final scale = math.max(1.0, math.max(a.abs(), b.abs()));
  return (a - b).abs() <= 1e-9 * scale;
}

double _snap(double v) {
  final r = v.roundToDouble();
  return (v - r).abs() < _eps ? r : v;
}

double _checked(double v) {
  if (v.isNaN || v.isInfinite || v.abs() > _maxMagnitude) {
    throw const ExprError(ExprErrorKind.overflow);
  }
  return v;
}

/// Formata um valor para exibição (inteiros sem casas, demais com até 4).
String formatValue(double v) {
  if (isIntegerValue(v)) return v.round().toString();
  var s = v.toStringAsFixed(4);
  s = s.replaceFirst(RegExp(r'0+$'), '');
  return s.endsWith('.') ? s.substring(0, s.length - 1) : s;
}

// ---------------------------------------------------------------------------
// Árvore sintática
// ---------------------------------------------------------------------------

sealed class Node {
  const Node();

  double eval({required bool allowFractions});

  String latex();

  /// Quantidade de operadores, usada para escolher a solução mais simples.
  int get cost;
}

/// LaTeX de [n] sem os parênteses externos (quando o próprio comando LaTeX
/// já delimita o conteúdo, como em `\sqrt{...}` ou `\frac{...}{...}`).
String _bare(Node n) => n is Paren ? n.inner.latex() : n.latex();

class Num extends Node {
  const Num(this.value);
  final int value;

  @override
  double eval({required bool allowFractions}) => value.toDouble();

  @override
  String latex() => '$value';

  @override
  int get cost => 0;
}

class Paren extends Node {
  const Paren(this.inner);
  final Node inner;

  @override
  double eval({required bool allowFractions}) =>
      inner.eval(allowFractions: allowFractions);

  @override
  String latex() => '\\left(${inner.latex()}\\right)';

  @override
  int get cost => inner.cost + 1;
}

class Neg extends Node {
  const Neg(this.inner);
  final Node inner;

  @override
  double eval({required bool allowFractions}) =>
      -inner.eval(allowFractions: allowFractions);

  @override
  String latex() => '-${inner.latex()}';

  @override
  int get cost => inner.cost + 1;
}

class Bin extends Node {
  const Bin(this.op, this.left, this.right);
  final Tok op;
  final Node left;
  final Node right;

  @override
  double eval({required bool allowFractions}) {
    final a = left.eval(allowFractions: allowFractions);
    final b = right.eval(allowFractions: allowFractions);
    switch (op) {
      case Tok.plus:
        return _checked(a + b);
      case Tok.minus:
        return _checked(a - b);
      case Tok.times:
        return _checked(a * b);
      case Tok.divide:
        if (b.abs() < _eps) throw const ExprError(ExprErrorKind.divisionByZero);
        final q = _snap(a / b);
        if (!allowFractions && !isIntegerValue(q)) {
          throw const ExprError(ExprErrorKind.nonIntegerDivision);
        }
        return _checked(q);
      case Tok.pow:
        if (a.abs() < _eps && b < 0) {
          throw const ExprError(ExprErrorKind.divisionByZero);
        }
        final p = math.pow(a, b).toDouble();
        if (p.isNaN) throw const ExprError(ExprErrorKind.invalidPower);
        return _checked(_snap(p));
      default:
        throw ExprError(ExprErrorKind.unexpected, op.symbol);
    }
  }

  @override
  String latex() => switch (op) {
        Tok.plus => '${left.latex()} + ${right.latex()}',
        Tok.minus => '${left.latex()} - ${right.latex()}',
        Tok.times => '${left.latex()} \\times ${right.latex()}',
        Tok.divide => '\\frac{${_bare(left)}}{${_bare(right)}}',
        Tok.pow => '{${left.latex()}}^{${_bare(right)}}',
        _ => '',
      };

  @override
  int get cost => left.cost + right.cost + 1;
}

enum UnaryKind { sqrt, cbrt, fact, abs, floor, ceil }

class Unary extends Node {
  const Unary(this.kind, this.inner);
  final UnaryKind kind;
  final Node inner;

  @override
  double eval({required bool allowFractions}) {
    final v = inner.eval(allowFractions: allowFractions);
    switch (kind) {
      case UnaryKind.sqrt:
        if (v < 0) throw const ExprError(ExprErrorKind.negativeRoot);
        return _snap(math.sqrt(v));
      case UnaryKind.cbrt:
        final r = math.pow(v.abs(), 1 / 3).toDouble();
        return _snap(v < 0 ? -r : r);
      case UnaryKind.fact:
        if (!isIntegerValue(v) || v < 0 || v > 18) {
          throw const ExprError(ExprErrorKind.invalidFactorial);
        }
        var f = 1.0;
        for (var i = 2; i <= v.round(); i++) {
          f *= i;
        }
        return _checked(f);
      case UnaryKind.abs:
        return v.abs();
      case UnaryKind.floor:
        return isIntegerValue(v) ? v.roundToDouble() : v.floorToDouble();
      case UnaryKind.ceil:
        return isIntegerValue(v) ? v.roundToDouble() : v.ceilToDouble();
    }
  }

  @override
  String latex() => switch (kind) {
        UnaryKind.sqrt => '\\sqrt{${_bare(inner)}}',
        UnaryKind.cbrt => '\\sqrt[3]{${_bare(inner)}}',
        UnaryKind.fact => '${inner.latex()}!',
        UnaryKind.abs => '\\left|${inner.latex()}\\right|',
        UnaryKind.floor => '\\left\\lfloor ${inner.latex()}\\right\\rfloor',
        UnaryKind.ceil => '\\left\\lceil ${inner.latex()}\\right\\rceil',
      };

  @override
  int get cost => inner.cost + 1;
}

// ---------------------------------------------------------------------------
// Analisador sintático (descida recursiva)
//
//   expr     := term (('+' | '-') term)*
//   term     := unary (('*' | '/') unary)*
//   unary    := '-' unary | power
//   power    := postfix ('**' unary)?            (associativo à direita)
//   postfix  := prefixed '!'*
//   prefixed := ('√' | '∛') prefixed | primary
//   primary  := dígito | '(' expr ')' | '|' expr '|'
//             | '⌊' expr '⌋' | '⌈' expr '⌉'
// ---------------------------------------------------------------------------

class _Parser {
  _Parser(this.items);

  /// Cada item é um `int` (dígito) ou um [Tok].
  final List<Object> items;
  int pos = 0;

  Object? get peek => pos < items.length ? items[pos] : null;

  bool accept(Tok t) {
    if (peek == t) {
      pos++;
      return true;
    }
    return false;
  }

  Node parseAll() {
    if (items.isEmpty) throw const ExprError(ExprErrorKind.emptySide);
    final node = expr();
    final rest = peek;
    if (rest != null) {
      if (rest is int) throw const ExprError(ExprErrorKind.missingOperator);
      final t = rest as Tok;
      if (t == Tok.rparen || t == Tok.floorR || t == Tok.ceilR) {
        throw ExprError(ExprErrorKind.unbalanced, t.symbol);
      }
      // Um operando logo após outro: "2(3)", "2√4", "2|3|"...
      throw const ExprError(ExprErrorKind.missingOperator);
    }
    return node;
  }

  Node expr() {
    var left = term();
    while (true) {
      if (accept(Tok.plus)) {
        left = Bin(Tok.plus, left, term());
      } else if (accept(Tok.minus)) {
        left = Bin(Tok.minus, left, term());
      } else {
        return left;
      }
    }
  }

  Node term() {
    var left = unary();
    while (true) {
      if (accept(Tok.times)) {
        left = Bin(Tok.times, left, unary());
      } else if (accept(Tok.divide)) {
        left = Bin(Tok.divide, left, unary());
      } else {
        return left;
      }
    }
  }

  Node unary() {
    if (accept(Tok.minus)) return Neg(unary());
    return power();
  }

  Node power() {
    final base = postfix();
    if (accept(Tok.pow)) return Bin(Tok.pow, base, unary());
    return base;
  }

  Node postfix() {
    var node = prefixed();
    while (accept(Tok.fact)) {
      node = Unary(UnaryKind.fact, node);
    }
    return node;
  }

  Node prefixed() {
    if (accept(Tok.sqrt)) return Unary(UnaryKind.sqrt, prefixed());
    if (accept(Tok.cbrt)) return Unary(UnaryKind.cbrt, prefixed());
    return primary();
  }

  Node primary() {
    final p = peek;
    if (p == null) throw const ExprError(ExprErrorKind.missingOperand);
    if (p is int) {
      pos++;
      return Num(p);
    }
    final t = p as Tok;
    switch (t) {
      case Tok.lparen:
        pos++;
        final inner = expr();
        if (!accept(Tok.rparen)) {
          throw const ExprError(ExprErrorKind.unbalanced, '(');
        }
        return Paren(inner);
      case Tok.abs:
        // Onde se espera um valor, `|` só pode abrir um módulo (o que fecha
        // vem sempre depois de um valor), então módulos podem ser aninhados.
        pos++;
        final inner = expr();
        if (!accept(Tok.abs)) {
          throw const ExprError(ExprErrorKind.unbalanced, '|');
        }
        return Unary(UnaryKind.abs, inner);
      case Tok.floorL:
        pos++;
        final inner = expr();
        if (!accept(Tok.floorR)) {
          throw const ExprError(ExprErrorKind.unbalanced, '⌊');
        }
        return Unary(UnaryKind.floor, inner);
      case Tok.ceilL:
        pos++;
        final inner = expr();
        if (!accept(Tok.ceilR)) {
          throw const ExprError(ExprErrorKind.unbalanced, '⌈');
        }
        return Unary(UnaryKind.ceil, inner);
      case Tok.rparen:
      case Tok.floorR:
      case Tok.ceilR:
        throw ExprError(ExprErrorKind.unbalanced, t.symbol);
      default:
        throw const ExprError(ExprErrorKind.missingOperand);
    }
  }
}

/// Analisa um lado da equação. Cada item é um `int` (dígito) ou um [Tok].
Node parseSide(List<Object> items) => _Parser(items).parseAll();

// ---------------------------------------------------------------------------
// Equação completa
// ---------------------------------------------------------------------------

/// Resultado da análise de um lado da equação.
class SideResult {
  const SideResult({this.node, this.value, this.error});
  final Node? node;
  final double? value;
  final ExprError? error;

  bool get ok => value != null;
}

class EquationResult {
  const EquationResult(this.left, this.right);
  final SideResult left;
  final SideResult right;

  ExprError? get error => left.error ?? right.error;

  /// Verdadeiro quando os dois lados são válidos e iguais.
  bool get isCorrect =>
      left.ok && right.ok && nearlyEqual(left.value!, right.value!);
}

List<Object> _sideItems(Iterable<Piece> pieces) => [
      for (final p in pieces)
        if (p is DigitPiece) p.value else if (p is OpPiece) p.tok,
    ];

SideResult _evaluateSide(List<Piece> pieces, OperatorRules level) {
  for (final p in pieces) {
    if (p is OpPiece && !level.allows(p.tok)) {
      return SideResult(
        error: ExprError(ExprErrorKind.notAllowed, p.tok.symbol),
      );
    }
  }
  if (!pieces.any((p) => p is DigitPiece)) {
    return const SideResult(error: ExprError(ExprErrorKind.emptySide));
  }
  Node? node;
  try {
    node = parseSide(_sideItems(pieces));
    final value = node.eval(allowFractions: level.allowsFractions);
    return SideResult(node: node, value: value);
  } on ExprError catch (e) {
    return SideResult(node: node, error: e);
  }
}

/// Avalia a linha de peças (que deve conter exatamente um [EqualsPiece]).
EquationResult evaluateEquation(List<Piece> pieces, OperatorRules level) {
  final eq = pieces.indexWhere((p) => p is EqualsPiece);
  final left = eq < 0 ? pieces : pieces.sublist(0, eq);
  final right = eq < 0 ? const <Piece>[] : pieces.sublist(eq + 1);
  return EquationResult(
    _evaluateSide(left, level),
    _evaluateSide(right, level),
  );
}

// ---------------------------------------------------------------------------
// LaTeX
// ---------------------------------------------------------------------------

/// LaTeX "linear" usado enquanto a expressão ainda está incompleta.
String _lenientLatex(List<Piece> pieces) {
  final sb = StringBuffer();
  for (final p in pieces) {
    switch (p) {
      case DigitPiece(:final value):
        sb.write('$value');
      case EqualsPiece():
        sb.write(' = ');
      case OpPiece(:final tok):
        sb.write(switch (tok) {
          Tok.plus => ' + ',
          Tok.minus => ' - ',
          Tok.times => ' \\times ',
          Tok.divide => ' \\div ',
          Tok.lparen => '(',
          Tok.rparen => ')',
          Tok.sqrt => '\\surd ',
          Tok.cbrt => '\\sqrt[3]{\\,}',
          Tok.fact => '!',
          Tok.pow => '\\,\\hat{}\\,',
          Tok.abs => '|',
          Tok.floorL => '\\lfloor ',
          Tok.floorR => '\\rfloor ',
          Tok.ceilL => '\\lceil ',
          Tok.ceilR => '\\rceil ',
        });
    }
  }
  return sb.toString();
}

/// Converte a linha de peças em LaTeX. Lados bem formados usam a árvore
/// sintática (`\sqrt{8+1}`, `3^{1}`, `\frac{a}{b}`); lados incompletos são
/// mostrados símbolo a símbolo.
String equationToLatex(List<Piece> pieces) {
  final eq = pieces.indexWhere((p) => p is EqualsPiece);
  final sides = eq < 0
      ? [pieces]
      : [pieces.sublist(0, eq), pieces.sublist(eq + 1)];
  final parts = <String>[];
  for (final side in sides) {
    if (side.isEmpty) {
      parts.add('\\square');
      continue;
    }
    try {
      parts.add(parseSide(_sideItems(side)).latex());
    } on ExprError {
      parts.add(_lenientLatex(side));
    }
  }
  return parts.join(' = ');
}
