// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Emplake';

  @override
  String get loginTagline =>
      'Use os quatro dígitos da placa para montar uma igualdade.';

  @override
  String get groupMembersTitle => 'Integrantes do grupo';

  @override
  String get languageLabel => 'Idioma';

  @override
  String get languageSystem => 'Idioma do dispositivo';

  @override
  String get navGame => 'Jogo';

  @override
  String get navProgress => 'Progresso';

  @override
  String get navHelp => 'Ajuda';

  @override
  String get navSettings => 'Configurações';

  @override
  String get levelLabel => 'Nível';

  @override
  String get levelEasy => 'Fácil';

  @override
  String get levelIntermediate => 'Intermediário';

  @override
  String get levelAdvanced => 'Avançado';

  @override
  String get levelHard => 'Difícil';

  @override
  String levelPoints(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points pontos por placa',
      one: '1 ponto por placa',
    );
    return '$_temp0';
  }

  @override
  String get plateCountry => 'BRASIL';

  @override
  String get leftSide => 'Lado esquerdo';

  @override
  String get rightSide => 'Lado direito';

  @override
  String get formulaLabel => 'Fórmula';

  @override
  String get operatorsLabel => 'Operadores';

  @override
  String get editHint =>
      'Toque na linha para mover o cursor e escolha um operador.';

  @override
  String get verify => 'Verificar';

  @override
  String get skip => 'Pular';

  @override
  String get nextPlate => 'Próxima placa';

  @override
  String get clear => 'Limpar';

  @override
  String get backspace => 'Apagar';

  @override
  String get moveLeft => 'Cursor para a esquerda';

  @override
  String get moveRight => 'Cursor para a direita';

  @override
  String get moveEquals => 'Mover o sinal de igual para o cursor';

  @override
  String get soundOn => 'Som ligado';

  @override
  String get soundOff => 'Som desligado';

  @override
  String correctMessage(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Correto! +$points pontos',
      one: 'Correto! +1 ponto',
    );
    return '$_temp0';
  }

  @override
  String notEqualMessage(String left, String right) {
    return 'Os lados são diferentes: $left ≠ $right';
  }

  @override
  String get saveError =>
      'Não foi possível salvar na nuvem. Verifique a conexão.';

  @override
  String get errEmptySide =>
      'Cada lado do sinal de igual precisa de pelo menos um dígito.';

  @override
  String get errMissingOperator =>
      'Falta um operador entre dois valores (os dígitos não podem ser unidos).';

  @override
  String get errMissingOperand => 'Há um operador sem valor para operar.';

  @override
  String errUnbalanced(String symbol) {
    return 'O símbolo $symbol está sem o seu par.';
  }

  @override
  String get errUnexpected => 'A expressão está incompleta.';

  @override
  String get errDivisionByZero => 'Divisão por zero.';

  @override
  String get errNonIntegerDivision =>
      'Neste nível a divisão precisa ter resultado inteiro.';

  @override
  String get errNegativeRoot =>
      'Não existe raiz quadrada real de número negativo.';

  @override
  String get errInvalidFactorial =>
      'O fatorial só vale para inteiros de 0 a 18.';

  @override
  String get errInvalidPower => 'Essa potência não tem resultado real.';

  @override
  String get errOverflow => 'O resultado é grande demais.';

  @override
  String errNotAllowed(String symbol) {
    return 'O operador $symbol não é permitido neste nível.';
  }

  @override
  String get skipDialogTitle => 'Placa pulada';

  @override
  String get skipSolutionIntro => 'Uma solução possível era:';

  @override
  String get continueLabel => 'Continuar';

  @override
  String get close => 'Fechar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get loadingPlate => 'Sorteando uma placa…';

  @override
  String get loadingData => 'Carregando…';

  @override
  String get loadError => 'Não foi possível carregar os dados da nuvem.';

  @override
  String get retry => 'Tentar novamente';

  @override
  String get allSolved => 'Você resolveu todas as placas deste nível!';

  @override
  String get scoreLabel => 'Pontos';

  @override
  String get solvedLabel => 'Resolvidas';

  @override
  String get skippedLabel => 'Puladas';

  @override
  String get progressTitle => 'Progresso';

  @override
  String get solvedPlatesTitle => 'Placas resolvidas';

  @override
  String get noSolvedYet => 'Nenhuma placa resolvida ainda. Vá jogar!';

  @override
  String get rankingTitle => 'Ranking';

  @override
  String get rankingEmpty => 'Ainda não há pontuações.';

  @override
  String get rankingYou => 'você';

  @override
  String get anonymousPlayer => 'Jogador';

  @override
  String get refresh => 'Atualizar';

  @override
  String get settingsTitle => 'Configurações';

  @override
  String get appearanceSection => 'Aparência';

  @override
  String get themeMode => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get fontSize => 'Tamanho da fonte';

  @override
  String get fontFamily => 'Tipo da fonte';

  @override
  String get fontPreview => 'Prévia: (5 − 2)! = 6 × 1';

  @override
  String get seedColor => 'Cor do tema';

  @override
  String get customColor => 'Cor personalizada';

  @override
  String get presetThemes => 'Temas prontos';

  @override
  String get presetOcean => 'Oceano';

  @override
  String get presetForest => 'Floresta';

  @override
  String get presetSunset => 'Pôr do sol';

  @override
  String get presetLavender => 'Lavanda';

  @override
  String get presetGraphite => 'Grafite';

  @override
  String get soundSection => 'Som';

  @override
  String get soundEffects => 'Efeitos sonoros';

  @override
  String get soundEffectsSubtitle => 'Desligado por padrão';

  @override
  String get languageSection => 'Idioma';

  @override
  String get accountSection => 'Conta';

  @override
  String signedInAs(String email) {
    return 'Conectado como $email';
  }

  @override
  String get signOut => 'Sair';

  @override
  String get resetSettings => 'Restaurar padrões';

  @override
  String get helpTitle => 'Como jogar';

  @override
  String get helpGoalTitle => 'Objetivo';

  @override
  String get helpGoal =>
      'Cada placa tem 4 dígitos. Sem mudar a ordem deles, insira operadores e posicione o sinal de = para formar uma igualdade verdadeira. Exemplo: com 8131, √(8 + 1) = 3 ** 1.';

  @override
  String get helpHowTitle => 'Como montar';

  @override
  String get helpHow =>
      'Toque em qualquer ponto da linha para posicionar o cursor e depois toque em um operador para inseri-lo ali. Use ⌫ para apagar o operador antes do cursor e o botão = para trazer o sinal de igual até o cursor.';

  @override
  String get helpScaleTitle => 'A balança';

  @override
  String get helpScale =>
      'A balança mostra o valor de cada lado. Quando ela fica equilibrada, a igualdade está certa: toque em Verificar para pontuar.';

  @override
  String get helpRulesTitle => 'Regras';

  @override
  String get helpRules =>
      'Os dígitos não podem ser unidos (1 e 2 não formam 12) e todos precisam ser usados. Só o nível Fácil aceita divisão com resultado não inteiro.';

  @override
  String get helpSkipTitle => 'Pular';

  @override
  String get helpSkip =>
      'Achou a placa difícil? Toque em Pular para ver uma solução possível e receber outra placa. Placas já resolvidas não aparecem de novo.';

  @override
  String get helpLevelsTitle => 'Níveis';

  @override
  String get helpKeyboardTitle => 'Teclado';

  @override
  String get helpKeyboard =>
      'No computador você também pode usar o teclado: + - * / ( ) ! ^ | =, as setas, Backspace e Enter.';

  @override
  String get opSqrt => 'raiz quadrada';

  @override
  String get opCbrt => 'raiz cúbica';

  @override
  String get opFact => 'fatorial';

  @override
  String get opPow => 'potência';

  @override
  String get opAbs => 'módulo';

  @override
  String get opFloor => 'base (piso)';

  @override
  String get opCeil => 'teto';
}
