import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import 'help_dialog.dart';

/// Estrutura das páginas internas: conteúdo + barra de navegação curva, que
/// fica visível durante todo o uso do aplicativo após o login.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  /// Posição do botão de ajuda na barra (não é uma página).
  static const _helpIndex = 2;

  /// Ramo do roteador -> posição na barra.
  static int _barIndexOf(int branch) => branch >= _helpIndex ? branch + 1 : branch;

  /// Posição na barra -> ramo do roteador.
  static int _branchOf(int barIndex) =>
      barIndex > _helpIndex ? barIndex - 1 : barIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final current = _barIndexOf(navigationShell.currentIndex);

    final destinations = [
      (Icons.calculate_rounded, l10n.navGame),
      (Icons.emoji_events_rounded, l10n.navProgress),
      (Icons.help_rounded, l10n.navHelp),
      (Icons.settings_rounded, l10n.navSettings),
    ];

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: ColoredBox(
        // Preenche a área segura inferior com a cor da barra.
        color: scheme.primaryContainer,
        child: SafeArea(
          top: false,
          child: ColoredBox(
            color: scheme.surface,
            child: CurvedNavigationBar(
              index: current,
              height: 64,
              maxWidth: 640,
              color: scheme.primaryContainer,
              buttonBackgroundColor: scheme.primary,
              backgroundColor: scheme.surface,
              animationDuration: const Duration(milliseconds: 350),
              animationCurve: Curves.easeOutCubic,
              items: [
                for (final (i, (icon, label)) in destinations.indexed)
                  Tooltip(
                    message: label,
                    child: Icon(
                      icon,
                      size: 28,
                      semanticLabel: label,
                      color: i == current
                          ? scheme.onPrimary
                          : scheme.onPrimaryContainer,
                    ),
                  ),
              ],
              // A ajuda abre um diálogo e não muda a página selecionada.
              letIndexChange: (index) {
                if (index != _helpIndex) return true;
                showHelpDialog(context);
                return false;
              },
              onTap: (index) {
                final branch = _branchOf(index);
                navigationShell.goBranch(
                  branch,
                  initialLocation: branch == navigationShell.currentIndex,
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
