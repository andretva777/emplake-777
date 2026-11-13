import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'settings_controller.dart';

/// Monta o tema a partir das configurações do usuário.
ThemeData buildTheme(AppSettings settings, Brightness brightness) {
  final scheme = ColorScheme.fromSeed(
    seedColor: settings.seedColor,
    brightness: brightness,
  );
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  TextTheme textTheme;
  try {
    textTheme = GoogleFonts.getTextTheme(settings.fontFamily, base.textTheme);
  } catch (_) {
    textTheme = base.textTheme;
  }
  return base.copyWith(
    textTheme: textTheme,
    primaryTextTheme:
        _tryFont(settings.fontFamily, base.primaryTextTheme),
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      centerTitle: false,
      scrolledUnderElevation: 2,
      titleTextStyle: textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
    ),
  );
}

TextTheme _tryFont(String family, TextTheme base) {
  try {
    return GoogleFonts.getTextTheme(family, base);
  } catch (_) {
    return base;
  }
}

/// Fonte monoespaçada usada nas peças da equação.
TextStyle mathStyle(BuildContext context, {double? size, Color? color}) =>
    GoogleFonts.getFont(
      'JetBrains Mono',
      fontSize: size,
      fontWeight: FontWeight.w700,
      color: color,
      height: 1.0,
    );
