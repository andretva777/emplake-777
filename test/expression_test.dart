import 'package:emplake/game/expression.dart';
import 'package:emplake/game/solver.dart';
import 'package:emplake/game/tokens.dart';
import 'package:flutter_test/flutter_test.dart';

/// Monta peças a partir de uma string com os códigos de [Tok], dígitos e '='.
List<Piece> pieces(String s) {
  var id = 0;
  return [
    for (final ch in s.split(''))
      if (ch == '=')
        EqualsPiece(id++)
      else if (int.tryParse(ch) != null)
        DigitPiece(id++, int.parse(ch))
      else
        OpPiece(id++, Tok.fromCode(ch)!),
  ];
}

EquationResult eval(String s, [Level level = Level.easy]) =>
    evaluateEquation(pieces(s), level);

/// O que o jogador digitaria para obter [n] (códigos de [Tok] e dígitos).
String typeOf(Node n) => switch (n) {
      Num(:final value) => '$value',
      Paren(:final inner) => '(${typeOf(inner)})',
      Neg(:final inner) => '-${typeOf(inner)}',
      Bin(:final op, :final left, :final right) =>
        '${typeOf(left)}${op.code}${typeOf(right)}',
      Unary(:final kind, :final inner) => switch (kind) {
          UnaryKind.sqrt => 'r${typeOf(inner)}',
          UnaryKind.cbrt => 'c${typeOf(inner)}',
          UnaryKind.fact => '${typeOf(inner)}!',
          UnaryKind.abs => '|${typeOf(inner)}|',
          UnaryKind.floor => '[${typeOf(inner)}]',
          UnaryKind.ceil => '{${typeOf(inner)}}',
        },
    };

void main() {
  group('avaliação', () {
    test('exemplo do enunciado: √(8+1) = 3**1', () {
      final r = eval('r(8+1)=3^1');
      expect(r.isCorrect, isTrue);
      expect(equationToLatex(pieces('r(8+1)=3^1')), r'\sqrt{8 + 1} = {3}^{1}');
    });

    test('exemplo do enunciado: (5-2)! = 6*1', () {
      expect(eval('(5-2)!=6*1', Level.advanced).isCorrect, isTrue);
    });

    test('precedência e menos unário', () {
      expect(eval('2+3*4=7*2').isCorrect, isTrue); // 14 = 14
      expect(eval('-(2-5)=3').isCorrect, isTrue);
      expect(eval('2^-1=1/2').isCorrect, isTrue);
    });

    test('precedência do aplicativo original (exemplos do professor)', () {
      expect(eval('1+2*3=7').isCorrect, isTrue);
      expect(eval('2*3!=8+4').isCorrect, isTrue);
      expect(eval('-2+2=0+0').isCorrect, isTrue);
      expect(eval('--2+0!=3+0').isCorrect, isTrue);
      expect(eval('-(-2+5)=4-7').isCorrect, isTrue);
      // √ vale só para o número da frente: √8! = (√8)! (fatorial de não
      // inteiro, a raiz não é truncada).
      expect(eval('r8!+0=1+1').error?.kind, ExprErrorKind.invalidFactorial);
      expect(eval('r9!=6').isCorrect, isTrue); // (√9)! = 3! = 6
    });

    test('o menos unário vale só para o operando seguinte', () {
      expect(eval('-3^2=9').isCorrect, isTrue); // (-3)**2
      expect(eval('-(3^2)=0-9').isCorrect, isTrue);
      expect(eval('-2^3=0-8').isCorrect, isTrue); // (-2)**3
      expect(eval('2^-1=1/2').isCorrect, isTrue);
      expect(eval('2*-3=0-6').isCorrect, isTrue);
      expect(eval('2--2=4').isCorrect, isTrue);
      expect(eval('-r4=0-2').isCorrect, isTrue); // -(√4)
      expect(eval('-|0-2|=0-2').isCorrect, isTrue);
      // (-2)! não existe; -(2!) precisa de parênteses.
      expect(eval('-2!=0-2').error?.kind, ExprErrorKind.invalidFactorial);
      expect(eval('-(2!)=0-2').isCorrect, isTrue);
    });

    test('raiz seguida de menos unário', () {
      expect(eval('c-8=0-2').isCorrect, isTrue); // ∛(-8)
      expect(eval('r-(2-6)=2').isCorrect, isTrue); // √(-(2-6)) = √4
      expect(eval('r-4=2').error?.kind, ExprErrorKind.negativeRoot);
      expect(eval('r--4=2').isCorrect, isTrue);
    });

    test('expressões compostas do enunciado são aceitas pela sintaxe', () {
      // Os exemplos não são igualdades verdadeiras; o que importa é que a
      // estrutura é analisada (o erro, se houver, é de valor, não de sintaxe).
      const syntax = {
        ExprErrorKind.missingOperand,
        ExprErrorKind.missingOperator,
        ExprErrorKind.unbalanced,
        ExprErrorKind.unexpected,
      };
      for (final s in ['--(c(-(3!-r(8))))+7!!=c(r(8!))', 'r(r(-(2-6)!!)!)=(r8)*1!']) {
        final kind = eval(s).error?.kind;
        expect(syntax.contains(kind), isFalse, reason: '$s -> $kind');
      }
    });

    test('módulo, base e teto', () {
      expect(eval('|2-5|=3').isCorrect, isTrue);
      expect(eval('[5/2]=2').isCorrect, isTrue);
      expect(eval('{5/2}=3').isCorrect, isTrue);
      expect(eval('|2-5|+|1-2|=4').isCorrect, isTrue);
    });

    test('módulo dentro de módulo', () {
      expect(eval('|2-|3-5||=0').isCorrect, isTrue);
      expect(eval('||2-5|-1|=2').isCorrect, isTrue);
      expect(eval('|2*|3|-8|=2').isCorrect, isTrue);
      expect(eval('|2+|=1').error?.kind, ExprErrorKind.missingOperand);
      expect(eval('|2|3|=1').error?.kind, ExprErrorKind.missingOperator);
      expect(eval('|2-5=3').error?.kind, ExprErrorKind.unbalanced);
    });

    test('raízes e fatorial', () {
      expect(eval('c8=2').isCorrect, isTrue);
      expect(eval('r9!=6').isCorrect, isTrue);
      expect(eval('3!!=720').error?.kind, ExprErrorKind.missingOperator);
      expect(eval('0!=1').isCorrect, isTrue);
    });

    test('divisão não inteira só no nível fácil', () {
      expect(eval('5/2=5/2', Level.easy).isCorrect, isTrue);
      expect(
        eval('5/2=5/2', Level.hard).error?.kind,
        ExprErrorKind.nonIntegerDivision,
      );
      expect(eval('6/2=3', Level.hard).isCorrect, isTrue);
    });

    test('erros', () {
      expect(eval('1/0=1').error?.kind, ExprErrorKind.divisionByZero);
      expect(eval('12=3').error?.kind, ExprErrorKind.missingOperator);
      expect(eval('(1+2=3').error?.kind, ExprErrorKind.unbalanced);
      expect(eval('1+2)=3').error?.kind, ExprErrorKind.unbalanced);
      expect(eval('1+=3').error?.kind, ExprErrorKind.missingOperand);
      expect(eval('=1+2').error?.kind, ExprErrorKind.emptySide);
      expect(eval('r(1-5)=2').error?.kind, ExprErrorKind.negativeRoot);
      expect(eval('(1/2)!=1').error?.kind, ExprErrorKind.invalidFactorial);
      expect(eval('(9+9)!=1').error?.kind, ExprErrorKind.invalidFactorial);
      expect(eval('(9+8)!=1').error, isNull);
      expect(eval('r4=2', Level.hard).error?.kind, ExprErrorKind.notAllowed);
      expect(eval('1+2=4').isCorrect, isFalse);
      expect(eval('1+2=4').error, isNull);
    });

    test('LaTeX', () {
      expect(equationToLatex(pieces('(1+2)/3=1')), r'\frac{1 + 2}{3} = 1');
      expect(equationToLatex(pieces('c8=2')), r'\sqrt[3]{8} = 2');
      expect(
        equationToLatex(pieces('|2-5|=3')),
        r'\left|2 - 5\right| = 3',
      );
      // Base negativa de potência e de fatorial ganha parênteses.
      expect(equationToLatex(pieces('-3^2=9')), r'{\left(-3\right)}^{2} = 9');
      expect(equationToLatex(pieces('-(3^2)=9')), r'-\left({3}^{2}\right) = 9');
      expect(equationToLatex(pieces('-3!=6')), r'\left(-3\right)! = 6');
      expect(equationToLatex(pieces('c-8=2')), r'\sqrt[3]{-8} = 2');
      // Expressão incompleta não lança exceção.
      expect(equationToLatex(pieces('(1+=3')), isNotEmpty);
    });

    test('formatValue', () {
      expect(formatValue(3), '3');
      expect(formatValue(2.5), '2.5');
      expect(formatValue(1 / 3), '0.3333');
      expect(formatValue(-4), '-4');
    });
  });

  group('solver', () {
    test('encontra soluções válidas em todos os níveis', () {
      for (final level in Level.values) {
        final solver = Solver(level);
        for (final digits in [
          [6, 2, 3, 1],
          [5, 2, 6, 1],
          [1, 2, 3, 4],
          [9, 9, 9, 9],
          [0, 0, 0, 0],
          [7, 3, 5, 2],
        ]) {
          final s = solver.solve(digits);
          expect(s, isNotNull, reason: '$digits em $level');
          final l = s!.left.eval(allowFractions: level.allowsFractions);
          final r = s.right.eval(allowFractions: level.allowsFractions);
          expect(nearlyEqual(l, r), isTrue, reason: s.latex());
        }
      }
    });

    test('a solução mostrada ao pular pode ser digitada como está', () {
      // A árvore do solver, digitada peça a peça, tem o mesmo valor ao ser
      // lida pelo analisador: as precedências dos dois concordam.
      for (final level in Level.values) {
        final solver = Solver(level);
        for (var n = 0; n < 10000; n += 97) {
          final digits = n.toString().padLeft(4, '0');
          final s = solver.solve(digits.split('').map(int.parse).toList());
          if (s == null) continue;
          final typed = '${typeOf(s.left)}=${typeOf(s.right)}';
          final r = eval(typed, level);
          expect(r.isCorrect, isTrue, reason: '$digits $level: $typed ${r.error}');
        }
      }
    });

    test('a maioria das placas tem solução no nível difícil', () {
      final solver = Solver(Level.hard);
      var solvable = 0;
      for (var n = 0; n < 10000; n += 37) {
        final d = n.toString().padLeft(4, '0').split('').map(int.parse);
        if (solver.isSolvable(d.toList())) solvable++;
      }
      expect(solvable, greaterThan(100));
    });

    test('desempenho no nível fácil', () {
      final solver = Solver(Level.easy);
      final sw = Stopwatch()..start();
      for (final n in ['7919', '5873', '9876', '6789']) {
        solver.solve(n.split('').map(int.parse).toList());
      }
      // ignore: avoid_print
      print('easy: ${sw.elapsedMilliseconds} ms para 4 placas');
    });
  });
}
