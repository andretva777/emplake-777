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
      'Arraste um operador até a linha de dígitos para montar a equação.';

  @override
  String get verify => 'Verificar';

  @override
  String get skip => 'Pular';

  @override
  String get nextPlate => 'Próxima placa';

  @override
  String get clear => 'Limpar';

  @override
  String get addToEnd => 'Adicionar ao fim da equação';

  @override
  String get moveLeft => 'Mover para a esquerda';

  @override
  String get moveRight => 'Mover para a direita';

  @override
  String get removeOperator => 'Devolver ao teclado';

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
      'O fatorial só vale para inteiros de 0 a 17.';

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
      'Arraste um operador do teclado até a linha de dígitos e solte-o entre duas peças. Arraste o sinal de = para mudá-lo de lugar. Para tirar um operador, arraste-o para fora da linha ou toque nele: ele volta voando para o teclado.';

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
      'No computador, a tecla Enter verifica a equação (e avança para a próxima placa depois de acertar).';

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

  @override
  String get modeLabel => 'Modo de jogo';

  @override
  String get modeRandom => 'Aleatório';

  @override
  String get modeSpecific => 'Específico';

  @override
  String get modeAdventure => 'Aventura';

  @override
  String get correctRepeated =>
      'Correto! Você já tinha resolvido esta placa, então ela não vale pontos.';

  @override
  String get specificTitle => 'Escolha a placa';

  @override
  String get specificPrompt =>
      'Digite os 4 dígitos da placa que você quer resolver.';

  @override
  String get specificField => 'Dígitos da placa';

  @override
  String get specificPlay => 'Jogar';

  @override
  String get specificInvalid => 'Digite exatamente 4 dígitos.';

  @override
  String specificUnsolvable(String level) {
    return 'Esta placa não tem solução no nível $level. Tente outro nível ou outra placa.';
  }

  @override
  String get specificAlreadySolved =>
      'Você já resolveu esta placa: pode jogar de novo, mas não ganha pontos.';

  @override
  String get changePlate => 'Trocar placa';

  @override
  String get moneyLabel => 'Moedas';

  @override
  String coinsAmount(int coins) {
    return '$coins moedas';
  }

  @override
  String get adventureSolvedLabel => 'Placas';

  @override
  String get adventurePotLabel => 'Prêmio';

  @override
  String get adventureIntroTitle => 'Modo aventura';

  @override
  String adventureIntro(int money, int penalty, int skip) {
    return 'Você começa com $money moedas e só com + − × ÷ e parênteses. Cada acerto rende moedas, e quanto mais rápido, maior o prêmio. Verificar errado custa $penalty e pular custa $skip. Compre operadores avançados para facilitar. Se as moedas acabarem, a aventura termina.';
  }

  @override
  String get adventureStart => 'Começar aventura';

  @override
  String adventureBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Recorde: $count placas',
      one: 'Recorde: 1 placa',
      zero: 'Recorde: nenhuma placa',
    );
    return '$_temp0';
  }

  @override
  String adventureLocked(String name, int price) {
    return '$name: bloqueado, custa $price moedas';
  }

  @override
  String adventureBuyTitle(String symbol) {
    return 'Comprar $symbol?';
  }

  @override
  String adventureBuyBody(int price, int money) {
    return 'Custa $price moedas e fica liberado até o fim desta aventura. Você tem $money.';
  }

  @override
  String get adventureBuy => 'Comprar';

  @override
  String adventureCantAfford(int missing) {
    return 'Moedas insuficientes: faltam $missing.';
  }

  @override
  String rewardMessage(int coins) {
    return 'Correto! +$coins moedas';
  }

  @override
  String penaltyNote(int coins) {
    return '−$coins moedas';
  }

  @override
  String adventureSkip(int cost) {
    return 'Pular (−$cost)';
  }

  @override
  String get adventureGiveUp => 'Desistir';

  @override
  String get adventureGiveUpTitle => 'Desistir da aventura?';

  @override
  String get adventureGiveUpBody =>
      'A aventura termina agora; as placas já resolvidas contam para o recorde.';

  @override
  String get adventureOverTitle => 'Fim da aventura';

  @override
  String adventureOverBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Você resolveu $count placas.',
      one: 'Você resolveu 1 placa.',
      zero: 'Nenhuma placa resolvida.',
    );
    return '$_temp0';
  }

  @override
  String get adventureNewRecord => 'Novo recorde!';

  @override
  String get adventureRestart => 'Nova aventura';

  @override
  String get statAdventureBest => 'Recorde na aventura';

  @override
  String get helpModesTitle => 'Modos';

  @override
  String get helpModes =>
      'Aleatório: placas sorteadas entre as que você ainda não resolveu. Específico: você digita a placa que quer resolver. Aventura: comece com moedas e os operadores básicos, ganhe moedas acertando, perca errando ou pulando e compre operadores avançados; se as moedas acabarem, fim de jogo.';
}
