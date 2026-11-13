import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';

import '../core/constants.dart';
import '../l10n/app_localizations.dart';
import 'widgets/language_selector.dart';
import 'widgets/license_plate.dart';

/// Tela de login (firebase_ui_auth): e-mail/senha ou Google. Mostra também
/// os integrantes do grupo e o seletor de idioma com bandeiras.
///
/// A navegação após o login é feita pelo redirecionamento do go_router, que
/// observa a sessão de autenticação.
class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SignInScreen(
      breakpoint: 840,
      showPasswordVisibilityToggle: true,
      headerMaxExtent: 190,
      // Telas estreitas: marca no topo.
      headerBuilder: (context, constraints, shrinkOffset) =>
          const _Brand(compact: true),
      // Telas largas: marca em um painel lateral.
      sideBuilder: (context, constraints) => const _BrandPanel(),
      footerBuilder: (context, action) => const _LoginFooter(),
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 32),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LicensePlate(
                text: 'EMPLAKE',
                country: l10n.plateCountry,
                height: compact ? 72 : 104,
              ),
              SizedBox(height: compact ? 12 : 24),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 360),
                child: Text(
                  l10n.loginTagline,
                  textAlign: TextAlign.center,
                  style: (compact
                          ? theme.textTheme.bodyMedium
                          : theme.textTheme.titleLarge)
                      ?.copyWith(
                    color: compact
                        ? theme.colorScheme.onSurfaceVariant
                        : theme.colorScheme.onPrimaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [scheme.primaryContainer, scheme.tertiaryContainer],
        ),
      ),
      child: const _Brand(compact: false),
    );
  }
}

class _LoginFooter extends StatelessWidget {
  const _LoginFooter();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Divider(),
          const SizedBox(height: 12),
          Text(
            l10n.languageLabel,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(color: muted),
          ),
          const SizedBox(height: 8),
          const LanguageSelector(),
          const SizedBox(height: 20),
          Text(
            l10n.groupMembersTitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(color: muted),
          ),
          const SizedBox(height: 4),
          for (final name in groupMembers)
            Text(
              name,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
