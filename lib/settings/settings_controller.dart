import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers.dart';

/// Idiomas suportados, com o país usado para a bandeira.
enum AppLanguage {
  portuguese(Locale('pt'), 'BR', 'Português'),
  english(Locale('en'), 'US', 'English'),
  spanish(Locale('es'), 'ES', 'Español');

  const AppLanguage(this.locale, this.countryCode, this.nativeName);
  final Locale locale;
  final String countryCode;

  /// Nome do idioma no próprio idioma (não é traduzido de propósito).
  final String nativeName;

  static AppLanguage? fromCode(String? code) {
    for (final l in values) {
      if (l.locale.languageCode == code) return l;
    }
    return null;
  }
}

/// Famílias de fonte oferecidas (todas do Google Fonts).
const List<String> fontFamilies = [
  'Roboto',
  'EB Garamond',
  'Arimo',
  'Lato',
  'Merriweather',
  'Nunito',
  'Space Grotesk',
];

/// Cores semente sugeridas.
const List<Color> seedColors = [
  Color(0xFF3F51B5),
  Color(0xFF1565C0),
  Color(0xFF00838F),
  Color(0xFF2E7D32),
  Color(0xFF9E9D24),
  Color(0xFFF9A825),
  Color(0xFFEF6C00),
  Color(0xFFC62828),
  Color(0xFFAD1457),
  Color(0xFF6A1B9A),
  Color(0xFF5D4037),
  Color(0xFF546E7A),
];

/// Tema pronto: combina cor semente e fonte.
enum ThemePreset {
  ocean(Color(0xFF0277BD), 'Nunito'),
  forest(Color(0xFF2E7D32), 'Merriweather'),
  sunset(Color(0xFFE65100), 'Lato'),
  lavender(Color(0xFF7E57C2), 'EB Garamond'),
  graphite(Color(0xFF455A64), 'Space Grotesk');

  const ThemePreset(this.seed, this.fontFamily);
  final Color seed;
  final String fontFamily;
}

@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.fontScale = 1.0,
    this.fontFamily = 'Roboto',
    this.seedColor = const Color(0xFF3F51B5),
    this.language,
    this.soundEnabled = false,
  });

  static const double minFontScale = 0.85;
  static const double maxFontScale = 1.5;

  final ThemeMode themeMode;
  final double fontScale;
  final String fontFamily;
  final Color seedColor;

  /// `null` usa o idioma do dispositivo.
  final AppLanguage? language;

  /// O som começa desligado.
  final bool soundEnabled;

  AppSettings copyWith({
    ThemeMode? themeMode,
    double? fontScale,
    String? fontFamily,
    Color? seedColor,
    AppLanguage? Function()? language,
    bool? soundEnabled,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        fontScale: fontScale ?? this.fontScale,
        fontFamily: fontFamily ?? this.fontFamily,
        seedColor: seedColor ?? this.seedColor,
        language: language != null ? language() : this.language,
        soundEnabled: soundEnabled ?? this.soundEnabled,
      );

  ThemePreset? get activePreset {
    for (final p in ThemePreset.values) {
      if (p.seed.toARGB32() == seedColor.toARGB32() &&
          p.fontFamily == fontFamily) {
        return p;
      }
    }
    return null;
  }
}

/// Estado das configurações, persistido em SharedPreferences.
class SettingsController extends Notifier<AppSettings> {
  static const _kTheme = 'settings.themeMode';
  static const _kScale = 'settings.fontScale';
  static const _kFont = 'settings.fontFamily';
  static const _kSeed = 'settings.seedColor';
  static const _kLang = 'settings.language';
  static const _kSound = 'settings.sound';

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPrefsProvider);
    const defaults = AppSettings();
    final font = prefs.getString(_kFont);
    final seed = prefs.getInt(_kSeed);
    return AppSettings(
      themeMode: ThemeMode.values.asNameMap()[prefs.getString(_kTheme)] ??
          defaults.themeMode,
      fontScale: (prefs.getDouble(_kScale) ?? defaults.fontScale)
          .clamp(AppSettings.minFontScale, AppSettings.maxFontScale),
      fontFamily: fontFamilies.contains(font) ? font! : defaults.fontFamily,
      seedColor: seed != null ? Color(seed) : defaults.seedColor,
      language: AppLanguage.fromCode(prefs.getString(_kLang)),
      soundEnabled: prefs.getBool(_kSound) ?? defaults.soundEnabled,
    );
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
    ref.read(sharedPrefsProvider).setString(_kTheme, mode.name);
  }

  void setFontScale(double scale) {
    state = state.copyWith(fontScale: scale);
    ref.read(sharedPrefsProvider).setDouble(_kScale, scale);
  }

  void setFontFamily(String family) {
    state = state.copyWith(fontFamily: family);
    ref.read(sharedPrefsProvider).setString(_kFont, family);
  }

  void setSeedColor(Color color) {
    state = state.copyWith(seedColor: color);
    ref.read(sharedPrefsProvider).setInt(_kSeed, color.toARGB32());
  }

  void applyPreset(ThemePreset preset) {
    setSeedColor(preset.seed);
    setFontFamily(preset.fontFamily);
  }

  void setLanguage(AppLanguage? language) {
    state = state.copyWith(language: () => language);
    final prefs = ref.read(sharedPrefsProvider);
    if (language == null) {
      prefs.remove(_kLang);
    } else {
      prefs.setString(_kLang, language.locale.languageCode);
    }
  }

  void setSound(bool enabled) {
    state = state.copyWith(soundEnabled: enabled);
    ref.read(sharedPrefsProvider).setBool(_kSound, enabled);
  }

  /// Volta aparência e som ao padrão (o idioma é mantido).
  void reset() {
    final prefs = ref.read(sharedPrefsProvider);
    for (final k in [_kTheme, _kScale, _kFont, _kSeed, _kSound]) {
      prefs.remove(k);
    }
    state = AppSettings(language: state.language);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);
