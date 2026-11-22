// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Emplake';

  @override
  String get loginTagline =>
      'Use the four digits on the plate to build an equality.';

  @override
  String get groupMembersTitle => 'Group members';

  @override
  String get languageLabel => 'Language';

  @override
  String get navGame => 'Game';

  @override
  String get navProgress => 'Progress';

  @override
  String get navHelp => 'Help';

  @override
  String get navSettings => 'Settings';

  @override
  String get levelLabel => 'Level';

  @override
  String get levelEasy => 'Easy';

  @override
  String get levelIntermediate => 'Intermediate';

  @override
  String get levelAdvanced => 'Advanced';

  @override
  String get levelHard => 'Hard';

  @override
  String levelPoints(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: '$points points per plate',
      one: '1 point per plate',
    );
    return '$_temp0';
  }

  @override
  String get plateCountry => 'BRAZIL';

  @override
  String get leftSide => 'Left side';

  @override
  String get rightSide => 'Right side';

  @override
  String get formulaLabel => 'Formula';

  @override
  String get operatorsLabel => 'Operators';

  @override
  String get editHint =>
      'Tap between the pieces to place the cursor, then tap an operator to insert it there (or drag the operator onto the row).';

  @override
  String get verify => 'Check';

  @override
  String get skip => 'Skip';

  @override
  String get nextPlate => 'Next plate';

  @override
  String get clear => 'Clear';

  @override
  String get deleteOperator => 'Delete';

  @override
  String get moveLeft => 'Move left';

  @override
  String get moveRight => 'Move right';

  @override
  String get removeOperator => 'Return to the keypad';

  @override
  String get soundOn => 'Sound on';

  @override
  String get soundOff => 'Sound off';

  @override
  String correctMessage(int points) {
    String _temp0 = intl.Intl.pluralLogic(
      points,
      locale: localeName,
      other: 'Correct! +$points points',
      one: 'Correct! +1 point',
    );
    return '$_temp0';
  }

  @override
  String notEqualMessage(String left, String right) {
    return 'The sides are different: $left ≠ $right';
  }

  @override
  String get saveError => 'Could not save to the cloud. Check your connection.';

  @override
  String get errEmptySide =>
      'Each side of the equals sign needs at least one digit.';

  @override
  String get errMissingOperator =>
      'An operator is missing between two values (digits cannot be joined).';

  @override
  String get errMissingOperand =>
      'There is an operator with nothing to operate on.';

  @override
  String errUnbalanced(String symbol) {
    return 'The symbol $symbol is missing its pair.';
  }

  @override
  String get errUnexpected => 'The expression is incomplete.';

  @override
  String get errDivisionByZero => 'Division by zero.';

  @override
  String get errNonIntegerDivision =>
      'At this level, divisions must have an integer result.';

  @override
  String get errNegativeRoot =>
      'There is no real square root of a negative number.';

  @override
  String get errInvalidFactorial =>
      'Factorial only works for integers from 0 to 17.';

  @override
  String get errInvalidPower => 'That power has no real result.';

  @override
  String get errOverflow => 'The result is too large.';

  @override
  String errNotAllowed(String symbol) {
    return 'The operator $symbol is not allowed at this level.';
  }

  @override
  String get skipDialogTitle => 'Plate skipped';

  @override
  String get skipSolutionIntro => 'One possible solution was:';

  @override
  String get continueLabel => 'Continue';

  @override
  String get close => 'Close';

  @override
  String get cancel => 'Cancel';

  @override
  String get loadingPlate => 'Drawing a plate…';

  @override
  String get loadingData => 'Loading…';

  @override
  String get loadError => 'Could not load your data from the cloud.';

  @override
  String get retry => 'Try again';

  @override
  String get allSolved => 'You solved every plate at this level!';

  @override
  String get scoreLabel => 'Points';

  @override
  String get solvedLabel => 'Solved';

  @override
  String get skippedLabel => 'Skipped';

  @override
  String get progressTitle => 'Progress';

  @override
  String get solvedPlatesTitle => 'Solved plates';

  @override
  String get noSolvedYet => 'No plates solved yet. Go play!';

  @override
  String get rankingTitle => 'Ranking';

  @override
  String get rankingEmpty => 'No scores yet.';

  @override
  String get rankingYou => 'you';

  @override
  String get anonymousPlayer => 'Player';

  @override
  String get refresh => 'Refresh';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get appearanceSection => 'Appearance';

  @override
  String get themeMode => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get fontSize => 'Font size';

  @override
  String get fontFamily => 'Font family';

  @override
  String get fontPreview => 'Preview: (5 − 2)! = 6 × 1';

  @override
  String get seedColor => 'Theme color';

  @override
  String get customColor => 'Custom color';

  @override
  String get presetThemes => 'Ready-made themes';

  @override
  String get presetOcean => 'Ocean';

  @override
  String get presetForest => 'Forest';

  @override
  String get presetSunset => 'Sunset';

  @override
  String get presetLavender => 'Lavender';

  @override
  String get presetGraphite => 'Graphite';

  @override
  String get soundSection => 'Sound';

  @override
  String get soundEffects => 'Sound effects';

  @override
  String get soundEffectsSubtitle => 'Off by default';

  @override
  String get languageSection => 'Language';

  @override
  String get accountSection => 'Account';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get signOut => 'Sign out';

  @override
  String get resetSettings => 'Restore defaults';

  @override
  String get helpTitle => 'How to play';

  @override
  String get helpGoalTitle => 'Goal';

  @override
  String get helpGoal =>
      'Each plate has 4 digits. Without changing their order, insert operators and place the = sign to build a true equality. Example: with 8131, √(8 + 1) = 3 ** 1.';

  @override
  String get helpHowTitle => 'Building';

  @override
  String get helpHow =>
      'Tap a piece of the row to put the cursor (the coloured bar) on the side you tapped, then tap an operator on the keypad to insert it there; the cursor moves on, so you can insert several in a row. ⌫ Delete removes the operator to the left of the cursor and Clear removes them all. You can also drag: drop an operator between two pieces, drag the = sign to move it, or drag an operator off the row to take it out.';

  @override
  String get helpScaleTitle => 'The scale';

  @override
  String get helpScale =>
      'The scale shows the value of each side. When it is balanced the equality is right: tap Check to score.';

  @override
  String get helpRulesTitle => 'Rules';

  @override
  String get helpRules =>
      'Digits cannot be joined (1 and 2 do not make 12) and all of them must be used. Only the Easy level accepts divisions with a non-integer result.';

  @override
  String get helpSkipTitle => 'Skipping';

  @override
  String get helpSkip =>
      'Plate too hard? Tap Skip to see a possible solution and get another plate. Plates you already solved never come back.';

  @override
  String get helpLevelsTitle => 'Levels';

  @override
  String get helpKeyboardTitle => 'Keyboard';

  @override
  String get helpKeyboard =>
      'On a computer, type the operators: + - * (or x) / ( ) ! ^ (power) | (absolute value), r (√), c (∛), [ ] (floor) and braces (ceiling). Backspace deletes, the arrow keys move the cursor and Enter checks the equation (and moves on to the next plate after a correct answer).';

  @override
  String get opSqrt => 'square root';

  @override
  String get opCbrt => 'cube root';

  @override
  String get opFact => 'factorial';

  @override
  String get opPow => 'power';

  @override
  String get opAbs => 'absolute value';

  @override
  String get opFloor => 'floor';

  @override
  String get opCeil => 'ceiling';

  @override
  String get modeLabel => 'Game mode';

  @override
  String get modeRandom => 'Random';

  @override
  String get modeSpecific => 'Specific';

  @override
  String get modeAdventure => 'Adventure';

  @override
  String get correctRepeated =>
      'Correct! You had already solved this plate, so it is worth no points.';

  @override
  String get specificTitle => 'Choose a plate';

  @override
  String get specificPrompt =>
      'Type the 4 digits of the plate you want to solve.';

  @override
  String get specificField => 'Plate digits';

  @override
  String get specificPlay => 'Play';

  @override
  String get specificInvalid => 'Type exactly 4 digits.';

  @override
  String specificUnsolvable(String level) {
    return 'This plate has no solution at the $level level. Try another level or another plate.';
  }

  @override
  String get specificAlreadySolved =>
      'You have already solved this plate: you can play it again, but it is worth no points.';

  @override
  String get changePlate => 'Change plate';

  @override
  String get moneyLabel => 'Coins';

  @override
  String get adventureSolvedLabel => 'Plates';

  @override
  String get adventurePotLabel => 'Prize';

  @override
  String get adventureIntroTitle => 'Adventure mode';

  @override
  String adventureIntro(int money, int penalty, int skip) {
    return 'You start with $money coins and only + − × ÷ and parentheses. Every correct answer earns coins, and the faster you are, the bigger the prize. A wrong check costs $penalty and skipping costs $skip. Buy advanced operators to make it easier. If you run out of coins, the adventure is over.';
  }

  @override
  String get adventureStart => 'Start adventure';

  @override
  String adventureBest(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Best: $count plates',
      one: 'Best: 1 plate',
      zero: 'Best: no plates',
    );
    return '$_temp0';
  }

  @override
  String adventureLocked(String name, int price) {
    return '$name: locked, costs $price coins';
  }

  @override
  String adventureBuyTitle(String symbol) {
    return 'Buy $symbol?';
  }

  @override
  String adventureBuyBody(int price, int money) {
    return 'It costs $price coins and stays unlocked until the end of this adventure. You have $money.';
  }

  @override
  String get adventureBuy => 'Buy';

  @override
  String adventureCantAfford(int missing) {
    return 'Not enough coins: $missing short.';
  }

  @override
  String rewardMessage(int coins) {
    return 'Correct! +$coins coins';
  }

  @override
  String penaltyNote(int coins) {
    return '−$coins coins';
  }

  @override
  String adventureSkip(int cost) {
    return 'Skip (−$cost)';
  }

  @override
  String get adventureGiveUp => 'Give up';

  @override
  String get adventureGiveUpTitle => 'Give up the adventure?';

  @override
  String get adventureGiveUpBody =>
      'The adventure ends now; the plates you solved count toward your best.';

  @override
  String get adventureOverTitle => 'Adventure over';

  @override
  String adventureOverBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You solved $count plates.',
      one: 'You solved 1 plate.',
      zero: 'No plates solved.',
    );
    return '$_temp0';
  }

  @override
  String get adventureNewRecord => 'New best!';

  @override
  String get adventureRestart => 'New adventure';

  @override
  String get statAdventureBest => 'Adventure best';

  @override
  String get helpModesTitle => 'Modes';

  @override
  String get helpModes =>
      'Random: plates drawn among the ones you have not solved yet. Specific: you type the plate you want to solve. Adventure: start with coins and the basic operators, earn coins by solving, lose them by making mistakes or skipping, and buy advanced operators; if you run out of coins, it is game over.';
}
