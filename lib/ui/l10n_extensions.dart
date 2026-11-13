import '../game/expression.dart';
import '../game/tokens.dart';
import '../l10n/app_localizations.dart';
import '../settings/settings_controller.dart';

/// Traduções de valores do domínio (níveis, erros, operadores, temas).
extension DomainL10n on AppLocalizations {
  String levelName(Level level) => switch (level) {
        Level.easy => levelEasy,
        Level.intermediate => levelIntermediate,
        Level.advanced => levelAdvanced,
        Level.hard => levelHard,
      };

  String exprError(ExprError error) => switch (error.kind) {
        ExprErrorKind.emptySide => errEmptySide,
        ExprErrorKind.missingOperator => errMissingOperator,
        ExprErrorKind.missingOperand => errMissingOperand,
        ExprErrorKind.unbalanced => errUnbalanced(error.detail ?? ''),
        ExprErrorKind.unexpected => errUnexpected,
        ExprErrorKind.divisionByZero => errDivisionByZero,
        ExprErrorKind.nonIntegerDivision => errNonIntegerDivision,
        ExprErrorKind.negativeRoot => errNegativeRoot,
        ExprErrorKind.invalidFactorial => errInvalidFactorial,
        ExprErrorKind.invalidPower => errInvalidPower,
        ExprErrorKind.overflow => errOverflow,
        ExprErrorKind.notAllowed => errNotAllowed(error.detail ?? ''),
      };

  /// Nome por extenso dos operadores menos óbvios (dica e leitor de tela).
  String? operatorName(Tok tok) => switch (tok) {
        Tok.sqrt => opSqrt,
        Tok.cbrt => opCbrt,
        Tok.fact => opFact,
        Tok.pow => opPow,
        Tok.abs => opAbs,
        Tok.floorL || Tok.floorR => opFloor,
        Tok.ceilL || Tok.ceilR => opCeil,
        _ => null,
      };

  String presetName(ThemePreset preset) => switch (preset) {
        ThemePreset.ocean => presetOcean,
        ThemePreset.forest => presetForest,
        ThemePreset.sunset => presetSunset,
        ThemePreset.lavender => presetLavender,
        ThemePreset.graphite => presetGraphite,
      };
}
