import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/app_localizations.dart';
import '../../settings/settings_controller.dart';

/// Bandeira de um idioma.
class LanguageFlag extends StatelessWidget {
  const LanguageFlag(this.language, {super.key, this.height = 20});

  final AppLanguage language;
  final double height;

  @override
  Widget build(BuildContext context) => CountryFlag.fromCountryCode(
        language.countryCode,
        theme: ImageTheme(
          width: height * 1.45,
          height: height,
          shape: const RoundedRectangle(4),
        ),
      );
}

/// Seletor de idioma com bandeiras. Usado no login e nas configurações.
class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key, this.alignment = WrapAlignment.center});

  final WrapAlignment alignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(settingsProvider.select((s) => s.language));
    // Sem escolha explícita, destaca o idioma que está de fato em uso.
    final effective = selected ??
        AppLanguage.fromCode(Localizations.localeOf(context).languageCode);

    return Semantics(
      label: l10n.languageLabel,
      container: true,
      child: Wrap(
        alignment: alignment,
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final language in AppLanguage.values)
            ChoiceChip(
              avatar: LanguageFlag(language, height: 16),
              showCheckmark: false,
              label: Text(language.nativeName),
              selected: language == effective,
              onSelected: (_) =>
                  ref.read(settingsProvider.notifier).setLanguage(language),
            ),
        ],
      ),
    );
  }
}
