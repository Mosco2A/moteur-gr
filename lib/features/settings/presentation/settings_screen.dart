import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/firebase/firebase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../notifications/providers/notification_provider.dart';
import '../providers/settings_provider.dart';

/// Ecran des parametres complets.
///
/// Sections : langue, unites, theme, cache, notifications, version.
/// Tous les textes passent par Slang (t.settings.*).
/// Utilise select() pour minimiser les rebuilds Riverpod 3.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tr = Translations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(tr.settings.title)),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        children: [
          // --- Langue ---
          _buildLanguageSection(context, ref, theme, tr),
          const SizedBox(height: AppTheme.spacingLg),

          // --- Unites ---
          _buildUnitsSection(context, ref, theme, tr),
          const SizedBox(height: AppTheme.spacingLg),

          // --- Theme ---
          _buildThemeSection(context, ref, theme, tr),
          const SizedBox(height: AppTheme.spacingLg),

          // --- Cache ---
          _buildCacheSection(context, ref, theme, tr),
          const SizedBox(height: AppTheme.spacingLg),

          // --- Notifications ---
          _buildNotificationsSection(context, ref, theme, tr),
          const SizedBox(height: AppTheme.spacingLg),

          // --- Cloud (P1-4 audit #327 : etat explicite du mode local) ---
          _buildCloudSection(context, ref, theme, tr),
          const SizedBox(height: AppTheme.spacingLg),

          // --- Confidentialite et consentement (D4A-02, RGPD) ---
          _buildPrivacySection(context, theme, tr),
          const SizedBox(height: AppTheme.spacingLg),

          // --- Version ---
          _buildVersionSection(context, theme, tr),
          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }

  /// Section langue - radio list avec select() sur language.
  Widget _buildLanguageSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Translations tr,
  ) {
    final language = ref.watch(
      settingsProvider.select((s) => s.language),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(theme, Icons.language, tr.settings.language),
        Card(
          child: Column(
            children: AppLanguageValues.values.map((lang) {
              final selected = lang == language;
              return ListTile(
                title: Text(AppLanguageValues.labelFor(lang)),
                leading: Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? theme.colorScheme.primary : null,
                ),
                onTap: () {
                  ref.read(settingsProvider.notifier).setLanguage(lang);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Section unites - distance + temperature avec SegmentedButton.
  Widget _buildUnitsSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Translations tr,
  ) {
    final distanceUnit = ref.watch(
      settingsProvider.select((s) => s.distanceUnit),
    );
    final temperatureUnit = ref.watch(
      settingsProvider.select((s) => s.temperatureUnit),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(theme, Icons.straighten, tr.settings.units),
        Card(
          child: Column(
            children: [
              // Distance
              ListTile(
                title: Text(tr.settings.distance),
                trailing: SegmentedButton<String>(
                  segments: DistanceUnitValues.values
                      .map((u) => ButtonSegment(
                            value: u,
                            label: Text(DistanceUnitValues.symbolFor(u)),
                          ))
                      .toList(),
                  selected: {distanceUnit},
                  onSelectionChanged: (values) {
                    ref
                        .read(settingsProvider.notifier)
                        .setDistanceUnit(values.first);
                  },
                ),
              ),
              const Divider(height: 1),
              // Temperature
              ListTile(
                title: Text(tr.settings.temperature),
                trailing: SegmentedButton<String>(
                  segments: TemperatureUnitValues.values
                      .map((u) => ButtonSegment(
                            value: u,
                            label: Text(TemperatureUnitValues.symbolFor(u)),
                          ))
                      .toList(),
                  selected: {temperatureUnit},
                  onSelectionChanged: (values) {
                    ref
                        .read(settingsProvider.notifier)
                        .setTemperatureUnit(values.first);
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Section theme - radio list avec select() sur themeMode.
  Widget _buildThemeSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Translations tr,
  ) {
    final themeMode = ref.watch(
      settingsProvider.select((s) => s.themeMode),
    );

    /// Labels Slang pour chaque mode de theme.
    String themeModeLabel(String mode) {
      return switch (mode) {
        AppThemeModeValues.dark => tr.settings.dark,
        AppThemeModeValues.light => tr.settings.light,
        AppThemeModeValues.system => tr.settings.system,
        _ => mode,
      };
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(theme, Icons.palette, tr.settings.theme),
        Card(
          child: Column(
            children: AppThemeModeValues.values.map((mode) {
              final selected = mode == themeMode;
              return ListTile(
                title: Text(themeModeLabel(mode)),
                leading: Icon(
                  selected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: selected ? theme.colorScheme.primary : null,
                ),
                onTap: () {
                  ref.read(settingsProvider.notifier).setThemeMode(mode);
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  /// Section cache - switch + slider via select().
  Widget _buildCacheSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Translations tr,
  ) {
    final cacheEnabled = ref.watch(
      settingsProvider.select((s) => s.cacheEnabled),
    );
    final cacheSizeMb = ref.watch(
      settingsProvider.select((s) => s.cacheSizeMb),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(theme, Icons.storage, tr.settings.cache),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: Text(tr.settings.cacheEnabled),
                subtitle: Text(tr.settings.cacheDesc),
                value: cacheEnabled,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setCacheEnabled(value);
                },
              ),
              if (cacheEnabled) ...[
                const Divider(height: 1),
                ListTile(
                  title: Text(tr.settings.cacheSize),
                  subtitle: Text('$cacheSizeMb Mo'),
                  trailing: SizedBox(
                    width: 200,
                    child: Slider(
                      value: cacheSizeMb.toDouble(),
                      min: 100,
                      max: 2000,
                      divisions: 19,
                      label: '$cacheSizeMb Mo',
                      onChanged: (value) {
                        ref
                            .read(settingsProvider.notifier)
                            .setCacheSizeMb(value.round());
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  /// Section notifications - switches via notification provider.
  Widget _buildNotificationsSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Translations tr,
  ) {
    final notifications = ref.watch(notificationSettingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          theme,
          Icons.notifications,
          tr.settings.notifications,
        ),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                title: Text(tr.settings.morningReminder),
                subtitle: Text(
                  '${notifications.morningReminderHour.toString().padLeft(2, '0')}:'
                  '${notifications.morningReminderMinute.toString().padLeft(2, '0')}',
                ),
                value: notifications.morningReminderEnabled,
                onChanged: (value) {
                  ref
                      .read(notificationSettingsProvider.notifier)
                      .toggleMorningReminder(value);
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: Text(tr.settings.weatherAlerts),
                subtitle: Text(tr.settings.weatherAlertsDesc),
                value: notifications.weatherAlertsEnabled,
                onChanged: (value) {
                  ref
                      .read(notificationSettingsProvider.notifier)
                      .toggleWeatherAlerts(value);
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: Text(tr.settings.countdownReminder),
                subtitle: Text(tr.settings.countdownDesc),
                value: notifications.countdownEnabled,
                onChanged: (value) {
                  ref
                      .read(notificationSettingsProvider.notifier)
                      .toggleCountdown(value);
                },
              ),
              const Divider(height: 1),
              SwitchListTile(
                title: Text(tr.settings.offTrackAlerts),
                subtitle: Text(tr.settings.offTrackAlertsDesc),
                value: notifications.offTrackAlerts,
                onChanged: (value) {
                  ref
                      .read(notificationSettingsProvider.notifier)
                      .toggleOffTrackAlerts(value);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Section cloud - etat explicite du mode local/cloud (P1-4 #327).
  ///
  /// Sans configuration Firebase, l app tourne 100% en local : cette
  /// section le dit clairement (aucune donnee envoyee en ligne) au lieu
  /// de laisser croire a une sauvegarde cloud active.
  Widget _buildCloudSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Translations tr,
  ) {
    final available = ref.watch(isFirebaseAvailableProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          theme,
          available ? Icons.cloud_done : Icons.cloud_off,
          tr.cloud.statusSection,
        ),
        Card(
          child: ListTile(
            leading: Icon(
              available ? Icons.cloud_done : Icons.cloud_off,
              color: available
                  ? theme.colorScheme.primary
                  : AppTheme.grisGranite,
            ),
            title: Text(
              available ? tr.cloud.statusActive : tr.cloud.statusLocal,
            ),
            subtitle: Text(
              available ? tr.cloud.statusActiveDesc : tr.cloud.statusLocalDesc,
            ),
          ),
        ),
      ],
    );
  }

  /// Section confidentialite - acces a la gestion du consentement RGPD.
  ///
  /// D4A-02 : renvoie vers l'ecran de consentement granulaire ou l'utilisateur
  /// peut consulter, modifier et RETIRER chaque consentement (par finalite,
  /// sante isolee). a11y via [Semantics].
  Widget _buildPrivacySection(
    BuildContext context,
    ThemeData theme,
    Translations tr,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          theme,
          Icons.privacy_tip_outlined,
          tr.consent.settingsEntry,
        ),
        Card(
          child: Semantics(
            button: true,
            label: tr.consent.settingsEntry,
            child: ListTile(
              leading: const Icon(Icons.shield_outlined),
              title: Text(tr.consent.settingsEntry),
              subtitle: Text(tr.consent.settingsEntryDesc),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/consent'),
            ),
          ),
        ),
      ],
    );
  }

  /// Section version - affiche version + build depuis PackageInfo.
  Widget _buildVersionSection(
    BuildContext context,
    ThemeData theme,
    Translations tr,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(theme, Icons.info_outline, tr.settings.version),
        Card(
          child: FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final version = snapshot.hasData
                  ? '${snapshot.data!.version}+${snapshot.data!.buildNumber}'
                  : '...';
              return ListTile(
                title: Text(tr.settings.versionLabel),
                trailing: Text(
                  version,
                  style: theme.textTheme.bodySmall,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// En-tete de section avec icone et titre.
  Widget _sectionHeader(ThemeData theme, IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: AppTheme.spacingSm),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}

