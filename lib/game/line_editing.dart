import 'tokens.dart';

/// Operações sobre a linha da equação, compartilhadas pelos modos de jogo.
/// Todas devolvem uma nova lista (ou `null` quando nada muda).

/// Quem edita uma linha de equação (os controladores de cada modo).
abstract interface class LineEditor {
  /// Solta um operador novo na posição [gap] (0 a `pieces.length`).
  void insertAt(int gap, Tok tok);

  /// Move um operador ou o `=` para a posição [gap].
  void movePiece(int id, int gap);

  /// Tira um operador da linha.
  void removePiece(int id);
}

/// Linha inicial: os quatro dígitos com o `=` já no meio.
List<Piece> initialLine(String plate, int Function() nextId) => [
      DigitPiece(nextId(), int.parse(plate[0])),
      DigitPiece(nextId(), int.parse(plate[1])),
      EqualsPiece(nextId()),
      DigitPiece(nextId(), int.parse(plate[2])),
      DigitPiece(nextId(), int.parse(plate[3])),
    ];

/// Insere [piece] na posição [gap] (0 a `line.length`).
List<Piece> insertInLine(List<Piece> line, int gap, Piece piece) =>
    [...line]..insert(gap.clamp(0, line.length), piece);

/// Move um operador ou o `=` para a posição [gap], contada antes da remoção.
/// Dígitos nunca se movem.
List<Piece>? moveInLine(List<Piece> line, int id, int gap) {
  final from = line.indexWhere((p) => p.id == id);
  if (from < 0 || line[from] is DigitPiece) return null;
  var target = gap.clamp(0, line.length);
  if (target > from) target--;
  if (target == from) return null;
  final out = [...line];
  out.insert(target, out.removeAt(from));
  return out;
}

/// Tira um operador da linha. Dígitos e o `=` ficam.
List<Piece>? removeFromLine(List<Piece> line, int id) {
  final index = line.indexWhere((p) => p.id == id);
  if (index < 0 || line[index] is! OpPiece) return null;
  return [...line]..removeAt(index);
}

/// Linha em texto compacto ("r(8+1)=3^1"), para salvar o jogo.
String encodeLine(List<Piece> line) => line
    .map((p) => switch (p) {
          DigitPiece(:final value) => '$value',
          EqualsPiece() => '=',
          OpPiece(:final tok) => tok.code,
        })
    .join();

/// Lê uma linha salva; operadores fora de [rules] são descartados.
List<Piece> decodeLine(
  String s,
  OperatorRules rules,
  int Function() nextId,
) {
  final out = <Piece>[];
  for (final ch in s.split('')) {
    final digit = int.tryParse(ch);
    if (digit != null) {
      out.add(DigitPiece(nextId(), digit));
    } else if (ch == '=') {
      out.add(EqualsPiece(nextId()));
    } else {
      final tok = Tok.fromCode(ch);
      if (tok != null && rules.allows(tok)) out.add(OpPiece(nextId(), tok));
    }
  }
  return out;
}

/// A linha salva corresponde à placa e tem exatamente um `=`.
bool lineMatchesPlate(List<Piece> line, String plate) =>
    line.whereType<DigitPiece>().map((d) => d.value).join() == plate &&
    line.whereType<EqualsPiece>().length == 1;

List<int> digitsOf(String plate) => plate.split('').map(int.parse).toList();

final _platePattern = RegExp(r'^\d{4}$');
bool isPlate(String? s) => s != null && _platePattern.hasMatch(s);
