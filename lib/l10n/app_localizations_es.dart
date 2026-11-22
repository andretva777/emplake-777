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
      'Toca entre las piezas para poner el cursor y toca un operador para insertarlo allí (o arrastra el operador hasta la fila).';

  @override
  String get verify => 'Comprobar';

  @override
  String get skip => 'Saltar';

  @override
  String get nextPlate => 'Siguiente matrícula';

  @override
  String get clear => 'Limpiar';

  @override
  String get deleteOperator => 'Borrar';

  @override
  String get moveLeft => 'Mover a la izquierda';

  @override
  String get moveRight => 'Mover a la derecha';

  @override
  String get removeOperator => 'Devolver al teclado';

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
      'El factorial solo vale para enteros de 0 a 17.';

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
      'Toca una pieza de la fila para poner el cursor (la barra de color) del lado que tocaste y toca un operador del teclado para insertarlo allí; el cursor avanza, así que puedes insertar varios seguidos. ⌫ Borrar quita el operador a la izquierda del cursor y Limpiar los quita todos. También puedes arrastrar: suelta un operador entre dos piezas, arrastra el signo = para cambiarlo de sitio o arrastra un operador fuera de la fila para quitarlo.';

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
  String get helpOrderTitle => 'Orden de las operaciones';

  @override
  String get helpOrder =>
      '* y / se hacen antes que + y −. √, ∛ y el − delante de un número valen solo para el número (o paréntesis) que les sigue: −3**2 = (−3)**2 = 9 y √9! = (√9)! = 6. El ! vale solo para el número (o paréntesis) justo antes: 2*3! = 2*(3!) = 12. Usa paréntesis para cambiar el orden: −(3**2) = −9.';

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
      'En el ordenador, escribe los operadores: + - * (o x) / ( ) ! ^ (potencia) | (valor absoluto), r (√), c (∛), [ ] (piso) y llaves (techo). Retroceso borra, las flechas mueven el cursor e Intro comprueba la ecuación (y pasa a la siguiente placa tras acertar).';

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

  @override
  String get modeLabel => 'Modo de juego';

  @override
  String get modeRandom => 'Aleatorio';

  @override
  String get modeSpecific => 'Específico';

  @override
  String get modeAdventure => 'Aventura';

  @override
  String get correctRepeated =>
      '¡Correcto! Ya habías resuelto esta placa, así que no suma puntos.';

  @override
  String get specificTitle => 'Elige la placa';

  @override
  String get specificPrompt =>
      'Escribe los 4 dígitos de la placa que quieres resolver.';

  @override
  String get specificField => 'Dígitos de la placa';

  @override
  String get specificPlay => 'Jugar';

  @override
  String get specificInvalid => 'Escribe exactamente 4 dígitos.';

  @override
  String specificUnsolvable(String level) {
    return 'Esta placa no tiene solución en el nivel $level. Prueba otro nivel u otra placa.';
  }

  @override
  String get specificAlreadySolved =>
      'Ya resolviste esta placa: puedes jugarla de nuevo, pero no suma puntos.';

  @override
  String get changePlate => 'Cambiar placa';

  @override
  String get moneyLabel => 'Monedas';

  @override
  String get adventureSolvedLabel => 'Placas';

  @override
  String get adventurePotLabel => 'Premio';

  @override
  String get adventureIntroTitle => 'Modo aventura';

  @override
  String adventureIntro(int money, int penalty, int skip) {
    return 'Empiezas con $money monedas y solo con + − × ÷ y paréntesis. Cada acierto da monedas, y cuanto más rápido, mayor el premio. Comprobar mal cuesta $penalty y saltar cuesta $skip. Compra operadores avanzados para facilitarte. Si te quedas sin monedas, la aventura termina.';
  }

  @override
  String get adventureStart => 'Empezar aventura';

  @override
  String adventureBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Récord: $count placas',
      one: 'Récord: 1 placa',
      zero: 'Récord: ninguna placa',
    );
    return '$_temp0';
  }

  @override
  String adventureLocked(String name, int price) {
    return '$name: bloqueado, cuesta $price monedas';
  }

  @override
  String adventureBuyTitle(String symbol) {
    return '¿Comprar $symbol?';
  }

  @override
  String adventureBuyBody(int price, int money) {
    return 'Cuesta $price monedas y queda desbloqueado hasta el final de esta aventura. Tienes $money.';
  }

  @override
  String get adventureBuy => 'Comprar';

  @override
  String adventureCantAfford(int missing) {
    return 'Monedas insuficientes: faltan $missing.';
  }

  @override
  String rewardMessage(int coins) {
    return '¡Correcto! +$coins monedas';
  }

  @override
  String penaltyNote(int coins) {
    return '−$coins monedas';
  }

  @override
  String adventureSkip(int cost) {
    return 'Saltar (−$cost)';
  }

  @override
  String get adventureGiveUp => 'Rendirse';

  @override
  String get adventureGiveUpTitle => '¿Abandonar la aventura?';

  @override
  String get adventureGiveUpBody =>
      'La aventura termina ahora; las placas resueltas cuentan para el récord.';

  @override
  String get adventureOverTitle => 'Fin de la aventura';

  @override
  String adventureOverBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Resolviste $count placas.',
      one: 'Resolviste 1 placa.',
      zero: 'Ninguna placa resuelta.',
    );
    return '$_temp0';
  }

  @override
  String get adventureNewRecord => '¡Nuevo récord!';

  @override
  String get adventureRestart => 'Nueva aventura';

  @override
  String get statAdventureBest => 'Récord en aventura';

  @override
  String get helpModesTitle => 'Modos';

  @override
  String get helpModes =>
      'Aleatorio: placas sorteadas entre las que aún no resolviste. Específico: escribes la placa que quieres resolver. Aventura: empieza con monedas y los operadores básicos, gana monedas acertando, piérdelas al fallar o saltar y compra operadores avanzados; si te quedas sin monedas, fin del juego.';
}
