import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/providers.dart';
import '../l10n/app_localizations.dart';
import '../settings/settings_controller.dart';
import 'l10n_extensions.dart';
import 'widgets/language_selector.dart';
import 'widgets/page_frame.dart';

/// Configurações: tema claro/escuro, tamanho e tipo da fonte, cor semente,
/// temas prontos, som, idioma e conta.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(settingsProvider.notifier);

    return PageFrame(
      title: l10n.settingsTitle,
      maxWidth: 760,
      actions: [
        TextButton.icon(
          onPressed: controller.reset,
          icon: const Icon(Icons.restart_alt_rounded),
          label: Text(l10n.resetSettings),
        ),
      ],
      child: LayoutBuilder(
        builder: (context, constraints) {
          final pad = PageFrame.gutter(constraints.maxWidth);
          return ListView(
            padding: EdgeInsets.fromLTRB(pad, 8, pad, 24),
            children: const [
              _AppearanceSection(),
              SizedBox(height: 16),
              _ColorSection(),
              SizedBox(height: 16),
              _SoundSection(),
              SizedBox(height: 16),
              _LanguageSection(),
              SizedBox(height: 16),
              _AccountSection(),
            ],
          );
        },
      ),
    );
  }
}

class _AppearanceSection extends ConsumerWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);

    return SectionCard(
      title: l10n.appearanceSection,
      icon: Icons.palette_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // (a) claro / escuro / sistema
          Text(l10n.themeMode, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<ThemeMode>(
            segments: [
              ButtonSegment(
                value: ThemeMode.system,
                icon: const Icon(Icons.brightness_auto_rounded),
                label: Text(l10n.themeSystem),
              ),
              ButtonSegment(
                value: ThemeMode.light,
                icon: const Icon(Icons.light_mode_rounded),
                label: Text(l10n.themeLight),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: const Icon(Icons.dark_mode_rounded),
                label: Text(l10n.themeDark),
              ),
            ],
            showSelectedIcon: false,
            selected: {settings.themeMode},
            onSelectionChanged: (s) => controller.setThemeMode(s.first),
          ),
          const SizedBox(height: 20),

          // (b) tamanho da fonte
          Row(
            children: [
              Expanded(
                child: Text(l10n.fontSize, style: theme.textTheme.labelLarge),
              ),
              Text(
                '${(settings.fontScale * 100).round()}%',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          Row(
            children: [
              const ExcludeSemantics(
                child: Text('A', textScaler: TextScaler.noScaling),
              ),
              Expanded(
                child: Slider(
                  value: settings.fontScale,
                  min: AppSettings.minFontScale,
                  max: AppSettings.maxFontScale,
                  divisions: 13,
                  label: '${(settings.fontScale * 100).round()}%',
                  semanticFormatterCallback: (v) => '${(v * 100).round()}%',
                  onChanged: controller.setFontScale,
                ),
              ),
              const ExcludeSemantics(
                child: Text(
                  'A',
                  textScaler: TextScaler.noScaling,
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // (c) tipo da fonte
          Text(l10n.fontFamily, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final family in fontFamilies)
                ChoiceChip(
                  label: Text(
                    family,
                    style: GoogleFonts.getFont(family),
                  ),
                  selected: settings.fontFamily == family,
                  onSelected: (_) => controller.setFontFamily(family),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(l10n.fontPreview, style: theme.textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}

class _ColorSection extends ConsumerWidget {
  const _ColorSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final seed = settings.seedColor;
    final hue = HSVColor.fromColor(seed).hue;

    return SectionCard(
      title: l10n.seedColor,
      icon: Icons.colorize_rounded,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // (d) cor semente
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final color in seedColors)
                _ColorDot(
                  color: color,
                  selected: color.toARGB32() == seed.toARGB32(),
                  onTap: () => controller.setSeedColor(color),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(l10n.customColor, style: theme.textTheme.labelLarge),
          const SizedBox(height: 4),
          _HueSlider(
            hue: hue,
            label: l10n.customColor,
            onChanged: (h) => controller.setSeedColor(
              HSVColor.fromAHSV(1, h, 0.7, 0.8).toColor(),
            ),
          ),
          const SizedBox(height: 16),

          // Temas prontos (cor + fonte).
          Text(l10n.presetThemes, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final preset in ThemePreset.values)
                ChoiceChip(
                  avatar: CircleAvatar(backgroundColor: preset.seed),
                  showCheckmark: false,
                  label: Text(
                    l10n.presetName(preset),
                    style: GoogleFonts.getFont(preset.fontFamily),
                  ),
                  selected: settings.activePreset == preset,
                  onSelected: (_) => controller.applyPreset(preset),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hex = color.toARGB32().toRadixString(16).substring(2).toUpperCase();
    return Semantics(
      button: true,
      selected: selected,
      label: '#$hex',
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(
              color: selected ? scheme.onSurface : Colors.transparent,
              width: 3,
            ),
          ),
          child: selected
              ? const Icon(Icons.check_rounded, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

/// Controle deslizante de matiz, com o espectro de cores ao fundo.
class _HueSlider extends StatelessWidget {
  const _HueSlider({
    required this.hue,
    required this.label,
    required this.onChanged,
  });

  final double hue;
  final String label;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          height: 14,
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            gradient: LinearGradient(
              colors: [
                for (var h = 0; h <= 360; h += 30)
                  HSVColor.fromAHSV(1, h.toDouble(), 0.7, 0.8).toColor(),
              ],
            ),
          ),
        ),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: Colors.transparent,
            inactiveTrackColor: Colors.transparent,
            thumbColor: HSVColor.fromAHSV(1, hue, 0.7, 0.8).toColor(),
            overlayColor: Colors.transparent,
          ),
          child: Semantics(
            label: label,
            child: Slider(
              value: hue.clamp(0, 360),
              max: 360,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _SoundSection extends ConsumerWidget {
  const _SoundSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final on = ref.watch(settingsProvider.select((s) => s.soundEnabled));
    return SectionCard(
      title: l10n.soundSection,
      icon: Icons.volume_up_rounded,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: Text(l10n.soundEffects),
        subtitle: Text(l10n.soundEffectsSubtitle),
        value: on,
        onChanged: ref.read(settingsProvider.notifier).setSound,
      ),
    );
  }
}

class _LanguageSection extends StatelessWidget {
  const _LanguageSection();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      title: l10n.languageSection,
      icon: Icons.translate_rounded,
      child: const Align(
        alignment: AlignmentDirectional.centerStart,
        child: LanguageSelector(alignment: WrapAlignment.start),
      ),
    );
  }
}

class _AccountSection extends ConsumerWidget {
  const _AccountSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider);
    final identity = user?.email ?? user?.displayName ?? '';
    return SectionCard(
      title: l10n.accountSection,
      icon: Icons.account_circle_rounded,
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 12,
        runSpacing: 12,
        children: [
          Text(l10n.signedInAs(identity)),
          OutlinedButton.icon(
            // O go_router redireciona para o login quando a sessão termina.
            onPressed: () => FirebaseUIAuth.signOut(context: context),
            icon: const Icon(Icons.logout_rounded),
            label: Text(l10n.signOut),
          ),
        ],
      ),
    );
  }
}
