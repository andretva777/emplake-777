import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('pt'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In pt, this message translates to:
  /// **'Emplake'**
  String get appTitle;

  /// No description provided for @loginTagline.
  ///
  /// In pt, this message translates to:
  /// **'Use os quatro dígitos da placa para montar uma igualdade.'**
  String get loginTagline;

  /// No description provided for @groupMembersTitle.
  ///
  /// In pt, this message translates to:
  /// **'Integrantes do grupo'**
  String get groupMembersTitle;

  /// No description provided for @languageLabel.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get languageLabel;

  /// No description provided for @languageSystem.
  ///
  /// In pt, this message translates to:
  /// **'Idioma do dispositivo'**
  String get languageSystem;

  /// No description provided for @navGame.
  ///
  /// In pt, this message translates to:
  /// **'Jogo'**
  String get navGame;

  /// No description provided for @navProgress.
  ///
  /// In pt, this message translates to:
  /// **'Progresso'**
  String get navProgress;

  /// No description provided for @navHelp.
  ///
  /// In pt, this message translates to:
  /// **'Ajuda'**
  String get navHelp;

  /// No description provided for @navSettings.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get navSettings;

  /// No description provided for @levelLabel.
  ///
  /// In pt, this message translates to:
  /// **'Nível'**
  String get levelLabel;

  /// No description provided for @levelEasy.
  ///
  /// In pt, this message translates to:
  /// **'Fácil'**
  String get levelEasy;

  /// No description provided for @levelIntermediate.
  ///
  /// In pt, this message translates to:
  /// **'Intermediário'**
  String get levelIntermediate;

  /// No description provided for @levelAdvanced.
  ///
  /// In pt, this message translates to:
  /// **'Avançado'**
  String get levelAdvanced;

  /// No description provided for @levelHard.
  ///
  /// In pt, this message translates to:
  /// **'Difícil'**
  String get levelHard;

  /// No description provided for @levelPoints.
  ///
  /// In pt, this message translates to:
  /// **'{points, plural, =1{1 ponto por placa} other{{points} pontos por placa}}'**
  String levelPoints(int points);

  /// No description provided for @plateCountry.
  ///
  /// In pt, this message translates to:
  /// **'BRASIL'**
  String get plateCountry;

  /// No description provided for @leftSide.
  ///
  /// In pt, this message translates to:
  /// **'Lado esquerdo'**
  String get leftSide;

  /// No description provided for @rightSide.
  ///
  /// In pt, this message translates to:
  /// **'Lado direito'**
  String get rightSide;

  /// No description provided for @formulaLabel.
  ///
  /// In pt, this message translates to:
  /// **'Fórmula'**
  String get formulaLabel;

  /// No description provided for @operatorsLabel.
  ///
  /// In pt, this message translates to:
  /// **'Operadores'**
  String get operatorsLabel;

  /// No description provided for @editHint.
  ///
  /// In pt, this message translates to:
  /// **'Arraste um operador até a linha de dígitos para montar a equação.'**
  String get editHint;

  /// No description provided for @verify.
  ///
  /// In pt, this message translates to:
  /// **'Verificar'**
  String get verify;

  /// No description provided for @skip.
  ///
  /// In pt, this message translates to:
  /// **'Pular'**
  String get skip;

  /// No description provided for @nextPlate.
  ///
  /// In pt, this message translates to:
  /// **'Próxima placa'**
  String get nextPlate;

  /// No description provided for @clear.
  ///
  /// In pt, this message translates to:
  /// **'Limpar'**
  String get clear;

  /// No description provided for @addToEnd.
  ///
  /// In pt, this message translates to:
  /// **'Adicionar ao fim da equação'**
  String get addToEnd;

  /// No description provided for @moveLeft.
  ///
  /// In pt, this message translates to:
  /// **'Mover para a esquerda'**
  String get moveLeft;

  /// No description provided for @moveRight.
  ///
  /// In pt, this message translates to:
  /// **'Mover para a direita'**
  String get moveRight;

  /// No description provided for @removeOperator.
  ///
  /// In pt, this message translates to:
  /// **'Devolver ao teclado'**
  String get removeOperator;

  /// No description provided for @soundOn.
  ///
  /// In pt, this message translates to:
  /// **'Som ligado'**
  String get soundOn;

  /// No description provided for @soundOff.
  ///
  /// In pt, this message translates to:
  /// **'Som desligado'**
  String get soundOff;

  /// No description provided for @correctMessage.
  ///
  /// In pt, this message translates to:
  /// **'{points, plural, =1{Correto! +1 ponto} other{Correto! +{points} pontos}}'**
  String correctMessage(int points);

  /// No description provided for @notEqualMessage.
  ///
  /// In pt, this message translates to:
  /// **'Os lados são diferentes: {left} ≠ {right}'**
  String notEqualMessage(String left, String right);

  /// No description provided for @saveError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível salvar na nuvem. Verifique a conexão.'**
  String get saveError;

  /// No description provided for @errEmptySide.
  ///
  /// In pt, this message translates to:
  /// **'Cada lado do sinal de igual precisa de pelo menos um dígito.'**
  String get errEmptySide;

  /// No description provided for @errMissingOperator.
  ///
  /// In pt, this message translates to:
  /// **'Falta um operador entre dois valores (os dígitos não podem ser unidos).'**
  String get errMissingOperator;

  /// No description provided for @errMissingOperand.
  ///
  /// In pt, this message translates to:
  /// **'Há um operador sem valor para operar.'**
  String get errMissingOperand;

  /// No description provided for @errUnbalanced.
  ///
  /// In pt, this message translates to:
  /// **'O símbolo {symbol} está sem o seu par.'**
  String errUnbalanced(String symbol);

  /// No description provided for @errUnexpected.
  ///
  /// In pt, this message translates to:
  /// **'A expressão está incompleta.'**
  String get errUnexpected;

  /// No description provided for @errDivisionByZero.
  ///
  /// In pt, this message translates to:
  /// **'Divisão por zero.'**
  String get errDivisionByZero;

  /// No description provided for @errNonIntegerDivision.
  ///
  /// In pt, this message translates to:
  /// **'Neste nível a divisão precisa ter resultado inteiro.'**
  String get errNonIntegerDivision;

  /// No description provided for @errNegativeRoot.
  ///
  /// In pt, this message translates to:
  /// **'Não existe raiz quadrada real de número negativo.'**
  String get errNegativeRoot;

  /// No description provided for @errInvalidFactorial.
  ///
  /// In pt, this message translates to:
  /// **'O fatorial só vale para inteiros de 0 a 18.'**
  String get errInvalidFactorial;

  /// No description provided for @errInvalidPower.
  ///
  /// In pt, this message translates to:
  /// **'Essa potência não tem resultado real.'**
  String get errInvalidPower;

  /// No description provided for @errOverflow.
  ///
  /// In pt, this message translates to:
  /// **'O resultado é grande demais.'**
  String get errOverflow;

  /// No description provided for @errNotAllowed.
  ///
  /// In pt, this message translates to:
  /// **'O operador {symbol} não é permitido neste nível.'**
  String errNotAllowed(String symbol);

  /// No description provided for @skipDialogTitle.
  ///
  /// In pt, this message translates to:
  /// **'Placa pulada'**
  String get skipDialogTitle;

  /// No description provided for @skipSolutionIntro.
  ///
  /// In pt, this message translates to:
  /// **'Uma solução possível era:'**
  String get skipSolutionIntro;

  /// No description provided for @continueLabel.
  ///
  /// In pt, this message translates to:
  /// **'Continuar'**
  String get continueLabel;

  /// No description provided for @close.
  ///
  /// In pt, this message translates to:
  /// **'Fechar'**
  String get close;

  /// No description provided for @cancel.
  ///
  /// In pt, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @loadingPlate.
  ///
  /// In pt, this message translates to:
  /// **'Sorteando uma placa…'**
  String get loadingPlate;

  /// No description provided for @loadingData.
  ///
  /// In pt, this message translates to:
  /// **'Carregando…'**
  String get loadingData;

  /// No description provided for @loadError.
  ///
  /// In pt, this message translates to:
  /// **'Não foi possível carregar os dados da nuvem.'**
  String get loadError;

  /// No description provided for @retry.
  ///
  /// In pt, this message translates to:
  /// **'Tentar novamente'**
  String get retry;

  /// No description provided for @allSolved.
  ///
  /// In pt, this message translates to:
  /// **'Você resolveu todas as placas deste nível!'**
  String get allSolved;

  /// No description provided for @scoreLabel.
  ///
  /// In pt, this message translates to:
  /// **'Pontos'**
  String get scoreLabel;

  /// No description provided for @solvedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Resolvidas'**
  String get solvedLabel;

  /// No description provided for @skippedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Puladas'**
  String get skippedLabel;

  /// No description provided for @progressTitle.
  ///
  /// In pt, this message translates to:
  /// **'Progresso'**
  String get progressTitle;

  /// No description provided for @solvedPlatesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Placas resolvidas'**
  String get solvedPlatesTitle;

  /// No description provided for @noSolvedYet.
  ///
  /// In pt, this message translates to:
  /// **'Nenhuma placa resolvida ainda. Vá jogar!'**
  String get noSolvedYet;

  /// No description provided for @rankingTitle.
  ///
  /// In pt, this message translates to:
  /// **'Ranking'**
  String get rankingTitle;

  /// No description provided for @rankingEmpty.
  ///
  /// In pt, this message translates to:
  /// **'Ainda não há pontuações.'**
  String get rankingEmpty;

  /// No description provided for @rankingYou.
  ///
  /// In pt, this message translates to:
  /// **'você'**
  String get rankingYou;

  /// No description provided for @anonymousPlayer.
  ///
  /// In pt, this message translates to:
  /// **'Jogador'**
  String get anonymousPlayer;

  /// No description provided for @refresh.
  ///
  /// In pt, this message translates to:
  /// **'Atualizar'**
  String get refresh;

  /// No description provided for @settingsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Configurações'**
  String get settingsTitle;

  /// No description provided for @appearanceSection.
  ///
  /// In pt, this message translates to:
  /// **'Aparência'**
  String get appearanceSection;

  /// No description provided for @themeMode.
  ///
  /// In pt, this message translates to:
  /// **'Tema'**
  String get themeMode;

  /// No description provided for @themeSystem.
  ///
  /// In pt, this message translates to:
  /// **'Sistema'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In pt, this message translates to:
  /// **'Claro'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In pt, this message translates to:
  /// **'Escuro'**
  String get themeDark;

  /// No description provided for @fontSize.
  ///
  /// In pt, this message translates to:
  /// **'Tamanho da fonte'**
  String get fontSize;

  /// No description provided for @fontFamily.
  ///
  /// In pt, this message translates to:
  /// **'Tipo da fonte'**
  String get fontFamily;

  /// No description provided for @fontPreview.
  ///
  /// In pt, this message translates to:
  /// **'Prévia: (5 − 2)! = 6 × 1'**
  String get fontPreview;

  /// No description provided for @seedColor.
  ///
  /// In pt, this message translates to:
  /// **'Cor do tema'**
  String get seedColor;

  /// No description provided for @customColor.
  ///
  /// In pt, this message translates to:
  /// **'Cor personalizada'**
  String get customColor;

  /// No description provided for @presetThemes.
  ///
  /// In pt, this message translates to:
  /// **'Temas prontos'**
  String get presetThemes;

  /// No description provided for @presetOcean.
  ///
  /// In pt, this message translates to:
  /// **'Oceano'**
  String get presetOcean;

  /// No description provided for @presetForest.
  ///
  /// In pt, this message translates to:
  /// **'Floresta'**
  String get presetForest;

  /// No description provided for @presetSunset.
  ///
  /// In pt, this message translates to:
  /// **'Pôr do sol'**
  String get presetSunset;

  /// No description provided for @presetLavender.
  ///
  /// In pt, this message translates to:
  /// **'Lavanda'**
  String get presetLavender;

  /// No description provided for @presetGraphite.
  ///
  /// In pt, this message translates to:
  /// **'Grafite'**
  String get presetGraphite;

  /// No description provided for @soundSection.
  ///
  /// In pt, this message translates to:
  /// **'Som'**
  String get soundSection;

  /// No description provided for @soundEffects.
  ///
  /// In pt, this message translates to:
  /// **'Efeitos sonoros'**
  String get soundEffects;

  /// No description provided for @soundEffectsSubtitle.
  ///
  /// In pt, this message translates to:
  /// **'Desligado por padrão'**
  String get soundEffectsSubtitle;

  /// No description provided for @languageSection.
  ///
  /// In pt, this message translates to:
  /// **'Idioma'**
  String get languageSection;

  /// No description provided for @accountSection.
  ///
  /// In pt, this message translates to:
  /// **'Conta'**
  String get accountSection;

  /// No description provided for @signedInAs.
  ///
  /// In pt, this message translates to:
  /// **'Conectado como {email}'**
  String signedInAs(String email);

  /// No description provided for @signOut.
  ///
  /// In pt, this message translates to:
  /// **'Sair'**
  String get signOut;

  /// No description provided for @resetSettings.
  ///
  /// In pt, this message translates to:
  /// **'Restaurar padrões'**
  String get resetSettings;

  /// No description provided for @helpTitle.
  ///
  /// In pt, this message translates to:
  /// **'Como jogar'**
  String get helpTitle;

  /// No description provided for @helpGoalTitle.
  ///
  /// In pt, this message translates to:
  /// **'Objetivo'**
  String get helpGoalTitle;

  /// No description provided for @helpGoal.
  ///
  /// In pt, this message translates to:
  /// **'Cada placa tem 4 dígitos. Sem mudar a ordem deles, insira operadores e posicione o sinal de = para formar uma igualdade verdadeira. Exemplo: com 8131, √(8 + 1) = 3 ** 1.'**
  String get helpGoal;

  /// No description provided for @helpHowTitle.
  ///
  /// In pt, this message translates to:
  /// **'Como montar'**
  String get helpHowTitle;

  /// No description provided for @helpHow.
  ///
  /// In pt, this message translates to:
  /// **'Arraste um operador do teclado até a linha de dígitos e solte-o entre duas peças. Arraste o sinal de = para mudá-lo de lugar. Para tirar um operador, arraste-o para fora da linha ou toque nele: ele volta voando para o teclado.'**
  String get helpHow;

  /// No description provided for @helpScaleTitle.
  ///
  /// In pt, this message translates to:
  /// **'A balança'**
  String get helpScaleTitle;

  /// No description provided for @helpScale.
  ///
  /// In pt, this message translates to:
  /// **'A balança mostra o valor de cada lado. Quando ela fica equilibrada, a igualdade está certa: toque em Verificar para pontuar.'**
  String get helpScale;

  /// No description provided for @helpRulesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Regras'**
  String get helpRulesTitle;

  /// No description provided for @helpRules.
  ///
  /// In pt, this message translates to:
  /// **'Os dígitos não podem ser unidos (1 e 2 não formam 12) e todos precisam ser usados. Só o nível Fácil aceita divisão com resultado não inteiro.'**
  String get helpRules;

  /// No description provided for @helpSkipTitle.
  ///
  /// In pt, this message translates to:
  /// **'Pular'**
  String get helpSkipTitle;

  /// No description provided for @helpSkip.
  ///
  /// In pt, this message translates to:
  /// **'Achou a placa difícil? Toque em Pular para ver uma solução possível e receber outra placa. Placas já resolvidas não aparecem de novo.'**
  String get helpSkip;

  /// No description provided for @helpLevelsTitle.
  ///
  /// In pt, this message translates to:
  /// **'Níveis'**
  String get helpLevelsTitle;

  /// No description provided for @helpKeyboardTitle.
  ///
  /// In pt, this message translates to:
  /// **'Teclado'**
  String get helpKeyboardTitle;

  /// No description provided for @helpKeyboard.
  ///
  /// In pt, this message translates to:
  /// **'No computador, a tecla Enter verifica a equação (e avança para a próxima placa depois de acertar).'**
  String get helpKeyboard;

  /// No description provided for @opSqrt.
  ///
  /// In pt, this message translates to:
  /// **'raiz quadrada'**
  String get opSqrt;

  /// No description provided for @opCbrt.
  ///
  /// In pt, this message translates to:
  /// **'raiz cúbica'**
  String get opCbrt;

  /// No description provided for @opFact.
  ///
  /// In pt, this message translates to:
  /// **'fatorial'**
  String get opFact;

  /// No description provided for @opPow.
  ///
  /// In pt, this message translates to:
  /// **'potência'**
  String get opPow;

  /// No description provided for @opAbs.
  ///
  /// In pt, this message translates to:
  /// **'módulo'**
  String get opAbs;

  /// No description provided for @opFloor.
  ///
  /// In pt, this message translates to:
  /// **'base (piso)'**
  String get opFloor;

  /// No description provided for @opCeil.
  ///
  /// In pt, this message translates to:
  /// **'teto'**
  String get opCeil;

  /// No description provided for @modeLabel.
  ///
  /// In pt, this message translates to:
  /// **'Modo de jogo'**
  String get modeLabel;

  /// No description provided for @modeRandom.
  ///
  /// In pt, this message translates to:
  /// **'Aleatório'**
  String get modeRandom;

  /// No description provided for @modeSpecific.
  ///
  /// In pt, this message translates to:
  /// **'Específico'**
  String get modeSpecific;

  /// No description provided for @modeAdventure.
  ///
  /// In pt, this message translates to:
  /// **'Aventura'**
  String get modeAdventure;

  /// No description provided for @correctRepeated.
  ///
  /// In pt, this message translates to:
  /// **'Correto! Você já tinha resolvido esta placa, então ela não vale pontos.'**
  String get correctRepeated;

  /// No description provided for @specificTitle.
  ///
  /// In pt, this message translates to:
  /// **'Escolha a placa'**
  String get specificTitle;

  /// No description provided for @specificPrompt.
  ///
  /// In pt, this message translates to:
  /// **'Digite os 4 dígitos da placa que você quer resolver.'**
  String get specificPrompt;

  /// No description provided for @specificField.
  ///
  /// In pt, this message translates to:
  /// **'Dígitos da placa'**
  String get specificField;

  /// No description provided for @specificPlay.
  ///
  /// In pt, this message translates to:
  /// **'Jogar'**
  String get specificPlay;

  /// No description provided for @specificInvalid.
  ///
  /// In pt, this message translates to:
  /// **'Digite exatamente 4 dígitos.'**
  String get specificInvalid;

  /// No description provided for @specificUnsolvable.
  ///
  /// In pt, this message translates to:
  /// **'Esta placa não tem solução no nível {level}. Tente outro nível ou outra placa.'**
  String specificUnsolvable(String level);

  /// No description provided for @specificAlreadySolved.
  ///
  /// In pt, this message translates to:
  /// **'Você já resolveu esta placa: pode jogar de novo, mas não ganha pontos.'**
  String get specificAlreadySolved;

  /// No description provided for @changePlate.
  ///
  /// In pt, this message translates to:
  /// **'Trocar placa'**
  String get changePlate;

  /// No description provided for @moneyLabel.
  ///
  /// In pt, this message translates to:
  /// **'Moedas'**
  String get moneyLabel;

  /// No description provided for @coinsAmount.
  ///
  /// In pt, this message translates to:
  /// **'{coins} moedas'**
  String coinsAmount(int coins);

  /// No description provided for @adventureSolvedLabel.
  ///
  /// In pt, this message translates to:
  /// **'Placas'**
  String get adventureSolvedLabel;

  /// No description provided for @adventurePotLabel.
  ///
  /// In pt, this message translates to:
  /// **'Prêmio'**
  String get adventurePotLabel;

  /// No description provided for @adventureIntroTitle.
  ///
  /// In pt, this message translates to:
  /// **'Modo aventura'**
  String get adventureIntroTitle;

  /// No description provided for @adventureIntro.
  ///
  /// In pt, this message translates to:
  /// **'Você começa com {money} moedas e só com + − × ÷ e parênteses. Cada acerto rende moedas, e quanto mais rápido, maior o prêmio. Verificar errado custa {penalty} e pular custa {skip}. Compre operadores avançados para facilitar. Se as moedas acabarem, a aventura termina.'**
  String adventureIntro(int money, int penalty, int skip);

  /// No description provided for @adventureStart.
  ///
  /// In pt, this message translates to:
  /// **'Começar aventura'**
  String get adventureStart;

  /// No description provided for @adventureBest.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Recorde: nenhuma placa} =1{Recorde: 1 placa} other{Recorde: {count} placas}}'**
  String adventureBest(int count);

  /// No description provided for @adventureLocked.
  ///
  /// In pt, this message translates to:
  /// **'{name}: bloqueado, custa {price} moedas'**
  String adventureLocked(String name, int price);

  /// No description provided for @adventureBuyTitle.
  ///
  /// In pt, this message translates to:
  /// **'Comprar {symbol}?'**
  String adventureBuyTitle(String symbol);

  /// No description provided for @adventureBuyBody.
  ///
  /// In pt, this message translates to:
  /// **'Custa {price} moedas e fica liberado até o fim desta aventura. Você tem {money}.'**
  String adventureBuyBody(int price, int money);

  /// No description provided for @adventureBuy.
  ///
  /// In pt, this message translates to:
  /// **'Comprar'**
  String get adventureBuy;

  /// No description provided for @adventureCantAfford.
  ///
  /// In pt, this message translates to:
  /// **'Moedas insuficientes: faltam {missing}.'**
  String adventureCantAfford(int missing);

  /// No description provided for @rewardMessage.
  ///
  /// In pt, this message translates to:
  /// **'Correto! +{coins} moedas'**
  String rewardMessage(int coins);

  /// No description provided for @penaltyNote.
  ///
  /// In pt, this message translates to:
  /// **'−{coins} moedas'**
  String penaltyNote(int coins);

  /// No description provided for @adventureSkip.
  ///
  /// In pt, this message translates to:
  /// **'Pular (−{cost})'**
  String adventureSkip(int cost);

  /// No description provided for @adventureGiveUp.
  ///
  /// In pt, this message translates to:
  /// **'Desistir'**
  String get adventureGiveUp;

  /// No description provided for @adventureGiveUpTitle.
  ///
  /// In pt, this message translates to:
  /// **'Desistir da aventura?'**
  String get adventureGiveUpTitle;

  /// No description provided for @adventureGiveUpBody.
  ///
  /// In pt, this message translates to:
  /// **'A aventura termina agora; as placas já resolvidas contam para o recorde.'**
  String get adventureGiveUpBody;

  /// No description provided for @adventureOverTitle.
  ///
  /// In pt, this message translates to:
  /// **'Fim da aventura'**
  String get adventureOverTitle;

  /// No description provided for @adventureOverBody.
  ///
  /// In pt, this message translates to:
  /// **'{count, plural, =0{Nenhuma placa resolvida.} =1{Você resolveu 1 placa.} other{Você resolveu {count} placas.}}'**
  String adventureOverBody(int count);

  /// No description provided for @adventureNewRecord.
  ///
  /// In pt, this message translates to:
  /// **'Novo recorde!'**
  String get adventureNewRecord;

  /// No description provided for @adventureRestart.
  ///
  /// In pt, this message translates to:
  /// **'Nova aventura'**
  String get adventureRestart;

  /// No description provided for @statAdventureBest.
  ///
  /// In pt, this message translates to:
  /// **'Recorde na aventura'**
  String get statAdventureBest;

  /// No description provided for @helpModesTitle.
  ///
  /// In pt, this message translates to:
  /// **'Modos'**
  String get helpModesTitle;

  /// No description provided for @helpModes.
  ///
  /// In pt, this message translates to:
  /// **'Aleatório: placas sorteadas entre as que você ainda não resolveu. Específico: você digita a placa que quer resolver. Aventura: comece com moedas e os operadores básicos, ganhe moedas acertando, perca errando ou pulando e compre operadores avançados; se as moedas acabarem, fim de jogo.'**
  String get helpModes;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
