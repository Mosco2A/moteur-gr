import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/firebase/firebase_service.dart';
import '../../../core/services/coffre_de_reconnexion.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';
import '../../notifications/providers/notification_provider.dart';
import '../providers/settings_provider.dart';
import 'data_erasure_section.dart';
import '../../../core/branding/stepways_icons.dart';

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
      // Ph5 (L6d) : AppHeader universel (reglages — §4 header standard, barre absente).
      appBar: AppHeader(title: tr.settings.title),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        children: [
          // --- Abonnement & achats — EN TETE (tache 601) ----------------------
          //
          // ELLE ETAIT NEUVIEME SUR DIX, juste avant le numero de version :
          // derriere la langue, les unites, le theme, le cache, les
          // notifications, le nuage, la vie privee, l'effacement et la
          // reconnexion. C'est-a-dire exactement ce que Chris appelle
          // « planque au fin fond de l appli » (27/09 13:09).
          //
          // POURQUOI ELLE PASSE PREMIERE, ET CE N'EST PAS UNE PREFERENCE DE
          // GOUT. L'article L215-1-1 du code de la consommation exige que la
          // resiliation soit GRATUITE, DIRECTE, PERMANENTE et FACILE D'ACCES
          // (en vigueur depuis le 1er juin 2023 ; sources en base #100700).
          // « Facile d'acces » et « neuvieme rubrique d'un ecran qui defile »
          // ne vont pas ensemble. Et c'est aussi la rubrique la plus
          // consequente pour celui qui paie : son argent.
          //
          // Le compte de gestes est verrouille par un test qui les COMPTE
          // (`resiliation_trois_clics_601_test.dart`), pas par cette intention.
          _buildPurchasesSection(context, theme, tr),
          const SizedBox(height: AppTheme.spacingLg),

          // --- Langue ---
          _buildLanguageSection(context, ref, theme, tr),
          const SizedBox(height: AppTheme.spacingLg),

          // --- Unites ---
          _buildUnitsSection(context, ref, theme, tr),
          const SizedBox(height: AppTheme.spacingLg),

          // --- Theme ---
          _buildThemeSection(context, ref, theme, tr),
          const SizedBox(height: AppTheme.spacingLg),

          // --- PLUS DE SECTION APPARENCE (tache 570, S4) ---
          // Elle offrait le choix entre trois peaux dont deux n'existent pas :
          // sur les trois proprietes qui les distinguent, `headerStyle` est lue
          // par un seul widget, `cardStyle` et `photoScrimOpacity` par personne,
          // et Grand Air n'a meme pas ses photos. Decision de Chris du 26/09,
          // un mot : « retire ». Le MOTEUR de peaux, lui, reste en place (voir
          // `core/theme/skin_theme.dart`) pour que le choix puisse revenir le
          // jour ou les trois peaux existent vraiment.

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

          // --- Mes donnees : droit a l'effacement (art. 17, tache 562 K1) ---
          // Pose JUSTE APRES la vie privee et les consentements : c'est la que
          // le randonneur cherche ce qui touche a ses donnees. Avant cette
          // tache, l'effacement etait implemente, prouve, et introuvable.
          const DataErasureSection(),
          const SizedBox(height: AppTheme.spacingLg),

          // --- Compte & reconnexion (Finitions V1, point 4) ---
          _buildRecoverySection(context, theme, tr),
          const SizedBox(height: AppTheme.spacingLg),

          // --- La section ACHATS a remonte EN TETE de cet ecran (tache 601).
          // Elle etait ici, en avant-derniere position. Voir la raison en haut.

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
        _sectionHeader(theme, StepwaysIcons.langue, tr.settings.language),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: AppLanguageValues.values.map((lang) {
              final selected = lang == language;
              return ListTile(
                title: Text(AppLanguageValues.labelFor(lang)),
                leading: StepIcon(
                  selected
                      ? StepwaysIcons.radioCoche
                      : StepwaysIcons.radio,
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
        _sectionHeader(theme, StepwaysIcons.distance, tr.settings.units),
        AppCard(
          padding: EdgeInsets.zero,
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
        _sectionHeader(theme, StepwaysIcons.palette, tr.settings.theme),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: AppThemeModeValues.values.map((mode) {
              final selected = mode == themeMode;
              return ListTile(
                title: Text(themeModeLabel(mode)),
                leading: StepIcon(
                  selected
                      ? StepwaysIcons.radioCoche
                      : StepwaysIcons.radio,
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
        _sectionHeader(theme, StepwaysIcons.horsLigne, tr.settings.cache),
        AppCard(
          padding: EdgeInsets.zero,
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
          StepwaysIcons.notifications,
          tr.settings.notifications,
        ),
        // LE TELEPHONE REFUSE LES NOTIFICATIONS — ET L ECRAN LE DIT (596 C3).
        //
        // `checkPermissions()` valait `async => true` : l'appli croyait
        // TOUJOURS avoir le droit de notifier, et `permissionGranted` n'etait
        // lu par personne. Le randonneur pouvait donc regler quatre rappels
        // avec soin alors qu'aucun ne lui parviendrait jamais.
        if (!notifications.permissionGranted)
          Padding(
            padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
            child: AppCard(
              padding: const EdgeInsets.all(AppTheme.spacingBase),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const StepIcon(StepwaysIcons.notifications,
                          color: AppTheme.orangeDifficile, size: 22),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: Text(
                          tr.notifications.permissionBlockedTitle,
                          style: theme.textTheme.titleSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Text(
                    tr.notifications.permissionBlockedBody,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppTheme.spacingSm),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      icon: const StepIcon(StepwaysIcons.notifications,
                          size: 18),
                      label: Text(tr.notifications.permissionAsk),
                      onPressed: () => ref
                          .read(notificationSettingsProvider.notifier)
                          .requestPermissions(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        AppCard(
          padding: EdgeInsets.zero,
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
          available ? StepwaysIcons.synchronise : StepwaysIcons.horsLigne,
          tr.cloud.statusSection,
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            leading: StepIcon(
              available ? StepwaysIcons.synchronise : StepwaysIcons.horsLigne,
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
          StepwaysIcons.bouclier,
          tr.consent.settingsEntry,
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Semantics(
            button: true,
            label: tr.consent.settingsEntry,
            child: ListTile(
              leading: const StepIcon(StepwaysIcons.bouclier),
              title: Text(tr.consent.settingsEntry),
              subtitle: Text(tr.consent.settingsEntryDesc),
              trailing: const StepIcon(StepwaysIcons.chevronDroite),
              onTap: () => context.push('/consent'),
            ),
          ),
        ),
      ],
    );
  }

  /// Section « Compte & reconnexion » (Finitions V1, point 4).
  ///
  /// Entrée vers l'écran « Afficher mon code de reconnexion » (modèle
  /// code-sur-tel blindé, #99784) : le code ouvre le coffre chiffré (profil +
  /// fiche santé + solde wallet) sur un autre téléphone. a11y via [Semantics].
  Widget _buildRecoverySection(
    BuildContext context,
    ThemeData theme,
    Translations tr,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(theme, StepwaysIcons.cle, tr.recovery.section),
        AppCard(
          padding: EdgeInsets.zero,
          child: Semantics(
            button: true,
            label: tr.recovery.title,
            child: ListTile(
              leading: const StepIcon(StepwaysIcons.cle),
              title: Text(tr.recovery.title),
              // TACHE 596 (C2) : la porte reste — c'est une invariante du LOT Q
              // — mais son sous-titre ne promet plus un code qui ne sera pas
              // affiche. Tant que le coffre n'est pas alimente, il annonce
              // l'etat reel, que l'ecran detaille ensuite.
              subtitle: Text(CoffreDeReconnexion.alimente
                  ? tr.recovery.sectionDesc
                  : tr.recovery.noVaultTitle),
              trailing: const StepIcon(StepwaysIcons.chevronDroite),
              onTap: () => context.push('/recovery-code'),
            ),
          ),
        ),
      ],
    );
  }

  /// Section ACHATS : recharger le compte-etapes, s'abonner, restaurer.
  ///
  /// Trois portes qui n'existaient nulle part avant la tache 594 : la grille
  /// des packs etait ecrite dans le code sans ecran, `subscribe()` n'avait
  /// aucun appelant, et il n'y avait pas de bouton « Restaurer mes achats ».
  Widget _buildPurchasesSection(
    BuildContext context,
    ThemeData theme,
    Translations tr,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          theme,
          StepwaysIcons.portefeuille,
          tr.monetization.walletTitle,
        ),
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              ListTile(
                key: const ValueKey('reglages-recharge'),
                leading: const StepIcon(StepwaysIcons.plus),
                title: Text(tr.monetization.rechargeTitle),
                subtitle: Text(tr.monetization.rechargeSubtitle),
                trailing: const StepIcon(StepwaysIcons.chevronDroite),
                onTap: () => context.push('/wallet'),
              ),
              ListTile(
                key: const ValueKey('reglages-abonnement'),
                leading: const StepIcon(StepwaysIcons.diplome),
                title: Text(tr.monetization.subscriptionTitle),
                subtitle: Text(tr.monetization.subscriptionSubtitle),
                trailing: const StepIcon(StepwaysIcons.chevronDroite),
                onTap: () => context.push('/subscription'),
              ),
            ],
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
        _sectionHeader(theme, StepwaysIcons.info, tr.settings.version),
        AppCard(
          padding: EdgeInsets.zero,
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
  Widget _sectionHeader(ThemeData theme, String icon, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        children: [
          StepIcon(icon, size: 20, color: theme.colorScheme.primary),
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

