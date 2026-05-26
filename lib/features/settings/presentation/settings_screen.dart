import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../notifications/providers/notification_provider.dart';
import '../providers/settings_provider.dart';

/// Écran des paramètres complets.
///
/// Permet de configurer la langue, les unités (distance, température),
/// le thème, le cache et les notifications.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifications = ref.watch(notificationSettingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        children: [
          // --- Langue ---
          _sectionHeader(theme, Icons.language, 'Langue'),
          Card(
            child: Column(
              children: AppLanguage.values.map((lang) {
                final selected = lang == settings.language;
                return ListTile(
                  title: Text(lang.label),
                  leading: Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: selected ? theme.colorScheme.primary : null,
                  ),
                  onTap: () {
                    ref.read(settingsProvider.notifier).setLanguage(lang);
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // --- Unités ---
          _sectionHeader(theme, Icons.straighten, 'Unités'),
          Card(
            child: Column(
              children: [
                // Distance
                ListTile(
                  title: const Text('Distance'),
                  trailing: SegmentedButton<DistanceUnit>(
                    segments: DistanceUnit.values
                        .map((u) => ButtonSegment(
                              value: u,
                              label: Text(u.symbol),
                            ))
                        .toList(),
                    selected: {settings.distanceUnit},
                    onSelectionChanged: (values) {
                      ref
                          .read(settingsProvider.notifier)
                          .setDistanceUnit(values.first);
                    },
                  ),
                ),
                const Divider(height: 1),
                // Température
                ListTile(
                  title: const Text('Température'),
                  trailing: SegmentedButton<TemperatureUnit>(
                    segments: TemperatureUnit.values
                        .map((u) => ButtonSegment(
                              value: u,
                              label: Text(u.symbol),
                            ))
                        .toList(),
                    selected: {settings.temperatureUnit},
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
          const SizedBox(height: AppTheme.spacingLg),

          // --- Thème ---
          _sectionHeader(theme, Icons.palette, 'Thème'),
          Card(
            child: Column(
              children: AppThemeMode.values.map((mode) {
                final selected = mode == settings.themeMode;
                return ListTile(
                  title: Text(mode.label),
                  leading: Icon(
                    selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: selected ? theme.colorScheme.primary : null,
                  ),
                  onTap: () {
                    ref.read(settingsProvider.notifier).setThemeMode(mode);
                  },
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // --- Cache ---
          _sectionHeader(theme, Icons.storage, 'Cache'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Cache activé'),
                  subtitle: const Text('Données disponibles hors ligne'),
                  value: settings.cacheEnabled,
                  onChanged: (value) {
                    ref
                        .read(settingsProvider.notifier)
                        .setCacheEnabled(value);
                  },
                ),
                if (settings.cacheEnabled) ...[
                  const Divider(height: 1),
                  ListTile(
                    title: const Text('Taille du cache'),
                    subtitle: Text('${settings.cacheSizeMb} Mo'),
                    trailing: SizedBox(
                      width: 200,
                      child: Slider(
                        value: settings.cacheSizeMb.toDouble(),
                        min: 100,
                        max: 2000,
                        divisions: 19,
                        label: '${settings.cacheSizeMb} Mo',
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
          const SizedBox(height: AppTheme.spacingLg),

          // --- Notifications ---
          _sectionHeader(theme, Icons.notifications, 'Notifications'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Rappel du matin'),
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
                  title: const Text('Alertes météo'),
                  subtitle:
                      const Text('Prévenu si conditions dangereuses'),
                  value: notifications.weatherAlertsEnabled,
                  onChanged: (value) {
                    ref
                        .read(notificationSettingsProvider.notifier)
                        .toggleWeatherAlerts(value);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Rappel J-2'),
                  subtitle: const Text(
                      'Notification 2 jours avant le départ'),
                  value: notifications.countdownEnabled,
                  onChanged: (value) {
                    ref
                        .read(notificationSettingsProvider.notifier)
                        .toggleCountdown(value);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }

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
