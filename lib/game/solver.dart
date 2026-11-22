import 'dart:math' as math;

import 'expression.dart';
import 'tokens.dart';

/// Uma solução encontrada: `left = right`.
class Solution {
  const Solution(this.left, this.right);
  final Node left;
  final Node right;

  int get cost => left.cost + right.cost;

  String latex() => '${left.latex()} = ${right.latex()}';
}

/// Busca exaustiva (limitada) de uma equação verdadeira para uma placa.
///
/// É usada para sortear apenas placas que têm solução no nível escolhido e
/// para mostrar uma resposta possível quando o jogador pula a placa.
class Solver {
  Solver(this.level);

  final OperatorRules level;

  static const double _limit = 1e6;

  /// Retorna a solução mais simples, ou `null` se não encontrar nenhuma.
  Solution? solve(List<int> digits) {
    Solution? best;
    for (var k = 1; k < digits.length; k++) {
      final left = _reach(digits.sublist(0, k));
      final right = _reach(digits.sublist(k));
      final (small, large) =
          left.length <= right.length ? (left, right) : (right, left);
      for (final entry in small.entries) {
        final other = large[entry.key];
        if (other == null) continue;
        final sol = identical(small, left)
            ? Solution(entry.value, other)
            : Solution(other, entry.value);
        // A chave arredonda o valor; confirma que os lados são mesmo iguais.
        if (!_holds(sol)) continue;
        if (best == null || sol.cost < best.cost) best = sol;
      }
    }
    return best;
  }

  bool isSolvable(List<int> digits) => solve(digits) != null;

  static int _key(double v) => (v * 1e6).round();

  bool _holds(Solution s) => nearlyEqual(
        s.left.eval(allowFractions: level.allowsFractions),
        s.right.eval(allowFractions: level.allowsFractions),
      );

  void _put(Map<int, Node> into, Node node) {
    final double v;
    try {
      v = node.eval(allowFractions: level.allowsFractions);
    } on ExprError {
      return;
    }
    if (v.abs() > _limit) return;
    // Valores ínfimos (como 7**-9) teriam a mesma chave que o zero.
    if (v != 0 && v.abs() < 1e-6) return;
    final key = _key(v);
    final current = into[key];
    if (current == null || node.cost < current.cost) into[key] = node;
  }

  /// Envolve em parênteses o que não é atômico, para que a árvore gerada
  /// corresponda exatamente ao que o jogador digitaria.
  static Node _wrap(Node n) =>
      (n is Num || n is Paren || (n is Unary && n.kind != UnaryKind.fact))
          ? n
          : Paren(n);

  /// Todos os valores alcançáveis usando [digits] nesta ordem.
  Map<int, Node> _reach(List<int> digits) {
    final base = <int, Node>{};
    if (digits.length == 1) {
      _put(base, Num(digits.first));
    } else {
      for (var k = 1; k < digits.length; k++) {
        final ls = _reach(digits.sublist(0, k));
        final rs = _reach(digits.sublist(k));
        for (final l in ls.values) {
          for (final r in rs.values) {
            final a = _wrap(l);
            final b = _wrap(r);
            _put(base, Bin(Tok.plus, a, b));
            _put(base, Bin(Tok.minus, a, b));
            _put(base, Bin(Tok.times, a, b));
            _put(base, Bin(Tok.divide, a, b));
            if (level.allows(Tok.pow)) {
              final e = r.eval(allowFractions: level.allowsFractions);
              if (isIntegerValue(e) && e.abs() <= 12) {
                _put(base, Bin(Tok.pow, a, b));
              }
            }
          }
        }
      }
    }
    return _withUnary(base);
  }

  /// Aplica uma rodada de operadores unários a cada valor.
  Map<int, Node> _withUnary(Map<int, Node> base) {
    final out = Map<int, Node>.of(base);
    for (final node in base.values) {
      final v = node.eval(allowFractions: level.allowsFractions);
      final w = _wrap(node);
      _put(out, Neg(w));
      if (level.allows(Tok.fact) && isIntegerValue(v) && v >= 0 && v <= 8) {
        // 1! e 2! não mudam o valor; 0! vira 1.
        if (v.round() != 1 && v.round() != 2) {
          _put(out, Unary(UnaryKind.fact, w));
        }
      }
      if (level.allows(Tok.sqrt) && v > 1) {
        final r = math.sqrt(v);
        if (isIntegerValue(r)) {
          _put(out, Unary(UnaryKind.sqrt, w));
        } else if (level.allows(Tok.floorL)) {
          final root = Unary(UnaryKind.sqrt, w);
          _put(out, Unary(UnaryKind.floor, root));
          _put(out, Unary(UnaryKind.ceil, root));
        }
      }
      if (level.allows(Tok.cbrt) && v.abs() > 1) {
        final r = math.pow(v.abs(), 1 / 3).toDouble();
        if (isIntegerValue(r)) _put(out, Unary(UnaryKind.cbrt, w));
      }
      if (level.allows(Tok.floorL) && !isIntegerValue(v)) {
        _put(out, Unary(UnaryKind.floor, node));
        _put(out, Unary(UnaryKind.ceil, node));
      }
    }
    return out;
  }
}
