import 'package:firebase_ui_localizations/firebase_ui_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'routing/app_router.dart';
import 'settings/app_theme.dart';
import 'settings/settings_controller.dart';

class EmplakeApp extends ConsumerWidget {
  const EmplakeApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      routerConfig: router,
      // Tema: por padrão segue o dispositivo (ThemeMode.system).
      themeMode: settings.themeMode,
      theme: buildTheme(settings, Brightness.light),
      darkTheme: buildTheme(settings, Brightness.dark),
      // Idioma: `null` segue o dispositivo.
      locale: settings.language?.locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        FirebaseUILocalizations.delegate,
      ],
      builder: (context, child) {
        // Tamanho da fonte escolhido nas configurações, combinado com o
        // tamanho de fonte de acessibilidade do sistema.
        final media = MediaQuery.of(context);
        final systemScale = media.textScaler.scale(1.0);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(
              (systemScale * settings.fontScale).clamp(0.8, 2.0),
            ),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
