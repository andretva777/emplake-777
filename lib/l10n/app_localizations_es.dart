// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Emplake';

  @override
  String get loginTagline =>
      'Usa los cuatro dígitos de la matrícula para formar una igualdad.';

  @override
  String get groupMembersTitle => 'Integrantes del grupo';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get languageSystem => 'Idioma del dispositivo';

  @override
  String get navGame => 'Juego';

  @override
  String get navProgress => 'Progreso';

  @override
  String get navHelp => 'Ayuda';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get levelLabel => 'Nivel';

  @override
  String get levelEasy => 'Fácil';

  @override
  String get levelIntermediate => 'Intermedio';

  @override
  String get levelAdvanced => 'Avanzado';

  @override
  String get levelHard => 'Difícil';

  @override
  String levelPoints(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points puntos por matrícula',
      one: '1 punto por matrícula',
    );
    return '$_temp0';
  }

  @override
  String get plateCountry => 'BRASIL';

  @override
  String get leftSide => 'Lado izquierdo';

  @override
  String get rightSide => 'Lado derecho';

  @override
  String get formulaLabel => 'Fórmula';

  @override
  String get operatorsLabel => 'Operadores';

  @override
  String get editHint =>
      'Toca la línea para mover el cursor y elige un operador.';

  @override
  String get verify => 'Comprobar';

  @override
  String get skip => 'Saltar';

  @override
  String get nextPlate => 'Siguiente matrícula';

  @override
  String get clear => 'Limpiar';

  @override
  String get backspace => 'Borrar';

  @override
  String get moveLeft => 'Cursor a la izquierda';

  @override
  String get moveRight => 'Cursor a la derecha';

  @override
  String get moveEquals => 'Mover el signo igual al cursor';

  @override
  String get soundOn => 'Sonido activado';

  @override
  String get soundOff => 'Sonido desactivado';

  @override
  String correctMessage(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '¡Correcto! +$points puntos',
      one: '¡Correcto! +1 punto',
    );
    return '$_temp0';
  }

  @override
  String notEqualMessage(String left, String right) {
    return 'Los lados son diferentes: $left ≠ $right';
  }

  @override
  String get saveError => 'No se pudo guardar en la nube. Revisa la conexión.';

  @override
  String get errEmptySide =>
      'Cada lado del signo igual necesita al menos un dígito.';

  @override
  String get errMissingOperator =>
      'Falta un operador entre dos valores (los dígitos no se pueden unir).';

  @override
  String get errMissingOperand =>
      'Hay un operador sin valor sobre el que operar.';

  @override
  String errUnbalanced(String symbol) {
    return 'Al símbolo $symbol le falta su pareja.';
  }

  @override
  String get errUnexpected => 'La expresión está incompleta.';

  @override
  String get errDivisionByZero => 'División por cero.';

  @override
  String get errNonIntegerDivision =>
      'En este nivel la división debe dar un resultado entero.';

  @override
  String get errNegativeRoot =>
      'No existe raíz cuadrada real de un número negativo.';

  @override
  String get errInvalidFactorial =>
      'El factorial solo vale para enteros de 0 a 18.';

  @override
  String get errInvalidPower => 'Esa potencia no tiene resultado real.';

  @override
  String get errOverflow => 'El resultado es demasiado grande.';

  @override
  String errNotAllowed(String symbol) {
    return 'El operador $symbol no está permitido en este nivel.';
  }

  @override
  String get skipDialogTitle => 'Matrícula saltada';

  @override
  String get skipSolutionIntro => 'Una solución posible era:';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get close => 'Cerrar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get loadingPlate => 'Sorteando una matrícula…';

  @override
  String get loadingData => 'Cargando…';

  @override
  String get loadError => 'No se pudieron cargar los datos de la nube.';

  @override
  String get retry => 'Reintentar';

  @override
  String get allSolved => '¡Resolviste todas las matrículas de este nivel!';

  @override
  String get scoreLabel => 'Puntos';

  @override
  String get solvedLabel => 'Resueltas';

  @override
  String get skippedLabel => 'Saltadas';

  @override
  String get progressTitle => 'Progreso';

  @override
  String get solvedPlatesTitle => 'Matrículas resueltas';

  @override
  String get noSolvedYet => 'Aún no hay matrículas resueltas. ¡A jugar!';

  @override
  String get rankingTitle => 'Clasificación';

  @override
  String get rankingEmpty => 'Todavía no hay puntuaciones.';

  @override
  String get rankingYou => 'tú';

  @override
  String get anonymousPlayer => 'Jugador';

  @override
  String get refresh => 'Actualizar';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get appearanceSection => 'Apariencia';

  @override
  String get themeMode => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Oscuro';

  @override
  String get fontSize => 'Tamaño de la fuente';

  @override
  String get fontFamily => 'Tipo de fuente';

  @override
  String get fontPreview => 'Vista previa: (5 − 2)! = 6 × 1';

  @override
  String get seedColor => 'Color del tema';

  @override
  String get customColor => 'Color personalizado';

  @override
  String get presetThemes => 'Temas listos';

  @override
  String get presetOcean => 'Océano';

  @override
  String get presetForest => 'Bosque';

  @override
  String get presetSunset => 'Atardecer';

  @override
  String get presetLavender => 'Lavanda';

  @override
  String get presetGraphite => 'Grafito';

  @override
  String get soundSection => 'Sonido';

  @override
  String get soundEffects => 'Efectos de sonido';

  @override
  String get soundEffectsSubtitle => 'Desactivado por defecto';

  @override
  String get languageSection => 'Idioma';

  @override
  String get accountSection => 'Cuenta';

  @override
  String signedInAs(String email) {
    return 'Conectado como $email';
  }

  @override
  String get signOut => 'Cerrar sesión';

  @override
  String get resetSettings => 'Restaurar valores';

  @override
  String get helpTitle => 'Cómo jugar';

  @override
  String get helpGoalTitle => 'Objetivo';

  @override
  String get helpGoal =>
      'Cada matrícula tiene 4 dígitos. Sin cambiar su orden, inserta operadores y coloca el signo = para formar una igualdad verdadera. Ejemplo: con 8131, √(8 + 1) = 3 ** 1.';

  @override
  String get helpHowTitle => 'Cómo se arma';

  @override
  String get helpHow =>
      'Toca cualquier punto de la línea para colocar el cursor y luego toca un operador para insertarlo allí. Usa ⌫ para borrar el operador anterior al cursor y el botón = para traer el signo igual hasta el cursor.';

  @override
  String get helpScaleTitle => 'La balanza';

  @override
  String get helpScale =>
      'La balanza muestra el valor de cada lado. Cuando queda equilibrada, la igualdad es correcta: toca Comprobar para puntuar.';

  @override
  String get helpRulesTitle => 'Reglas';

  @override
  String get helpRules =>
      'Los dígitos no se pueden unir (1 y 2 no forman 12) y hay que usarlos todos. Solo el nivel Fácil acepta divisiones con resultado no entero.';

  @override
  String get helpSkipTitle => 'Saltar';

  @override
  String get helpSkip =>
      '¿Matrícula difícil? Toca Saltar para ver una solución posible y recibir otra. Las matrículas ya resueltas no vuelven a aparecer.';

  @override
  String get helpLevelsTitle => 'Niveles';

  @override
  String get helpKeyboardTitle => 'Teclado';

  @override
  String get helpKeyboard =>
      'En el ordenador también puedes usar el teclado: + - * / ( ) ! ^ | =, las flechas, Retroceso e Intro.';

  @override
  String get opSqrt => 'raíz cuadrada';

  @override
  String get opCbrt => 'raíz cúbica';

  @override
  String get opFact => 'factorial';

  @override
  String get opPow => 'potencia';

  @override
  String get opAbs => 'valor absoluto';

  @override
  String get opFloor => 'piso';

  @override
  String get opCeil => 'techo';
}
