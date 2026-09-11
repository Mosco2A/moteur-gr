import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/firebase/cloud_unavailable_notice.dart';
import '../../../core/firebase/firebase_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/section_header.dart';
import '../../settings/providers/settings_provider.dart';
import '../domain/auth_service.dart';
import '../providers/auth_provider.dart';

/// Liste des icones d'avatars locaux predefinis.
///
/// 8 avatars thematiques randonnee, accessibles par index (0-7).
const _avatarIcons = <IconData>[
  Icons.hiking,
  Icons.landscape,
  Icons.terrain,
  Icons.forest,
  Icons.wb_sunny,
  Icons.star,
  Icons.explore,
  Icons.nature_people,
];

/// Ecran de profil utilisateur.
///
/// Parite GR20 (tache 517) : meme charpente que l'ecran profil GR20 —
/// en-tete avatar centre + pseudo, sections regroupees par [SectionHeader]
/// (compte, main dominante, zone dangereuse), et VERSION visible en bas de
/// page (« StepWays v0.1.0 (build 1) », lue via package_info_plus).
///
/// Acquis finitions conserves : profil OK hors-ligne (aucun spinner infini —
/// etat explicite si l'utilisateur est absent), acces au code de reconnexion
/// via les Reglages, choix de la main dominante. Tous les textes passent par
/// Slang (zero texte en dur), 5 langues.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _pseudoController = TextEditingController();
  bool _isEditingPseudo = false;

  @override
  void dispose() {
    _pseudoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);
    final i18n = Translations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      // Ph5 (L6d) : AppHeader universel (Mon compte — §4 header standard).
      appBar: AppHeader(title: i18n.auth.profile),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(i18n.auth.errorLoading)),
        data: (user) => _buildProfile(context, ref, theme, i18n, user),
      ),
    );
  }

  Widget _buildProfile(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Translations i18n,
    AuthUser? user,
  ) {
    if (user == null) {
      // P1-4 audit #327 : etat explicite — un spinner infini masquait
      // l absence d utilisateur (le stream a emis null, rien n arrivera).
      return Center(child: Text(i18n.auth.errorLoading));
    }

    // Parite GR20 : SingleChildScrollView + Column, sections espacees de
    // spacingLg entre elles (iso-rythme de l'ecran profil GR20).
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tete : avatar centre + pseudo editable + methode de connexion.
          _buildProfileHeader(context, ref, theme, i18n, user),
          const SizedBox(height: AppTheme.spacingLg),

          // Section « Mon compte » (connexion / deconnexion).
          SectionHeader(title: i18n.auth.profile, icon: Icons.person_outline),
          const SizedBox(height: AppTheme.spacingSm),
          _buildAccountSection(context, ref, theme, i18n, user),
          const SizedBox(height: AppTheme.spacingLg),

          // Section « Main dominante » (lateralite, R9/R10) : place le SOS et
          // les commandes critiques du cote de la main dominante (thumb zone).
          // Donnee NON sensible, defaut droitier. Persiste via settingsProvider.
          SectionHeader(
            title: i18n.navPilote.dominantHand,
            icon: Icons.pan_tool_outlined,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _buildDominantHandSection(context, ref, theme, i18n),
          const SizedBox(height: AppTheme.spacingLg),

          // Zone dangereuse — suppression de compte (parite GR20 : section
          // dediee en rouge, requise par les stores).
          SectionHeader(
            title: i18n.auth.deleteAccount,
            icon: Icons.warning_amber_rounded,
            iconColor: AppTheme.rougeUrgence,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _buildDangerZone(context, ref, theme, i18n),
          const SizedBox(height: AppTheme.spacingXl),

          // Version + build en bas de page (parite GR20, tache 517) :
          // « StepWays v0.1.0 (build 1) », discret, centre, lu dynamiquement
          // via package_info_plus. But : Chris VOIT la version a l'ecran.
          _buildVersionFooter(theme, i18n),
          const SizedBox(height: AppTheme.spacingMd),
        ],
      ),
    );
  }

  /// En-tete profil (parite GR20) : avatar centre cliquable, pseudo editable
  /// centre sous l'avatar, puis la puce « methode de connexion ».
  Widget _buildProfileHeader(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Translations i18n,
    AuthUser user,
  ) {
    return Column(
      children: [
        _buildAvatarSection(context, ref, theme, i18n, user),
        const SizedBox(height: AppTheme.spacingXs),
        _buildPseudoSection(context, ref, theme, i18n, user),
        const SizedBox(height: AppTheme.spacingSm),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppTheme.spacingMd,
              vertical: AppTheme.spacingXs,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            ),
            child: Text(
              '${i18n.auth.connectedVia} ${AuthMethodValues.labelFor(user.authMethod)}',
              style: theme.textTheme.bodySmall,
            ),
          ),
        ),
      ],
    );
  }

  /// Section « Mon compte » : connexion Google (si anonyme + Firebase dispo),
  /// deconnexion (si connecte), ou notice cloud indisponible.
  Widget _buildAccountSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Translations i18n,
    AuthUser user,
  ) {
    // P1-4 audit #327 : sans Firebase, la connexion Google ne peut
    // qu echouer en silence — etat explicite a la place de la tuile.
    if (user.isAnonymous && !ref.watch(isFirebaseAvailableProvider)) {
      return const CloudUnavailableNotice();
    }

    if (user.isAnonymous && ref.watch(isFirebaseAvailableProvider)) {
      // SW-SKIN-L3e : Card -> AppCard. padding zero car le ListTile porte
      // deja son padding interne (iso-rendu de la tuile cliquable).
      return AppCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: const Icon(Icons.login),
          title: Text(i18n.auth.signInGoogle),
          subtitle: Text(i18n.auth.signInGoogleDesc),
          trailing: const Icon(Icons.chevron_right),
          onTap: () async {
            final service = ref.read(authServiceProvider);
            await service.signInWithGoogleSilent();
          },
        ),
      );
    }

    // Connecte : proposer la deconnexion.
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: const Icon(Icons.logout),
        title: Text(i18n.auth.signOut),
        subtitle: Text(i18n.auth.signOutDesc),
        onTap: () => _confirmSignOut(context, ref, i18n),
      ),
    );
  }

  /// Version + build en bas de page (parite GR20, tache 517).
  ///
  /// Lue dynamiquement via package_info_plus. Format mandate :
  /// « StepWays v0.1.0 (build 1) ». Fallback discret « ... » le temps du
  /// chargement du plugin (jamais de spinner — coherent avec l'offline-first).
  Widget _buildVersionFooter(ThemeData theme, Translations i18n) {
    return Center(
      child: FutureBuilder<PackageInfo>(
        future: PackageInfo.fromPlatform(),
        builder: (context, snapshot) {
          final String versionText;
          if (snapshot.hasData) {
            final info = snapshot.data!;
            versionText = i18n.auth.appVersion(
              version: info.version,
              build: info.buildNumber,
            );
          } else {
            versionText = '...';
          }
          return Text(
            versionText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          );
        },
      ),
    );
  }

  /// Section « main dominante » (lateralite, R9/R10).
  ///
  /// Choix droitier/gaucher (defaut droitier) via [SegmentedButton] : positionne
  /// le SOS et les commandes critiques du cote de la main dominante (thumb zone,
  /// atteignabilite a une main en marchant). Persiste par [settingsProvider].
  Widget _buildDominantHandSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Translations i18n,
  ) {
    final hand = ref.watch(settingsProvider.select((s) => s.dominantHand));
    return AppCard(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            i18n.navPilote.dominantHandDesc,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          SegmentedButton<DominantHand>(
            segments: [
              ButtonSegment<DominantHand>(
                value: DominantHandValues.right,
                label: Text(i18n.navPilote.dominantHandRight),
                icon: const Icon(Icons.back_hand_outlined),
              ),
              ButtonSegment<DominantHand>(
                value: DominantHandValues.left,
                label: Text(i18n.navPilote.dominantHandLeft),
                icon: const Icon(Icons.front_hand_outlined),
              ),
            ],
            selected: {DominantHandValues.fromString(hand)},
            onSelectionChanged: (selection) {
              ref
                  .read(settingsProvider.notifier)
                  .setDominantHand(selection.first);
            },
          ),
        ],
      ),
    );
  }

  /// Zone dangereuse — suppression de compte (parite GR20).
  Widget _buildDangerZone(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Translations i18n,
  ) {
    // SW-SKIN-L3e : Card -> AppCard (padding zero, ListTile interne).
    return AppCard(
      padding: EdgeInsets.zero,
      borderColor: AppTheme.rougeUrgence.withValues(alpha: 0.4),
      child: ListTile(
        leading: const Icon(
          Icons.delete_forever,
          color: AppTheme.rougeUrgence,
        ),
        title: Text(
          i18n.auth.deleteAccount,
          style: const TextStyle(color: AppTheme.rougeUrgence),
        ),
        subtitle: Text(i18n.auth.deleteAccountDesc),
        onTap: () => _confirmDelete(context, ref, i18n),
      ),
    );
  }

  /// Section avatar : cercle avec icone + grille de selection
  Widget _buildAvatarSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Translations i18n,
    AuthUser user,
  ) {
    return Column(
      children: [
        Center(
          child: GestureDetector(
            onTap: () => _showAvatarPicker(context, ref, theme, i18n, user),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Icon(
                _avatarIcons[user.avatarIndex.clamp(
                  0,
                  _avatarIcons.length - 1,
                )],
                size: 48,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Center(
          child: Text(
            i18n.auth.changeAvatar,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  /// Grille de selection d'avatar dans un bottom sheet
  void _showAvatarPicker(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Translations i18n,
    AuthUser user,
  ) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusBottomSheet),
        ),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(i18n.auth.chooseAvatar, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppTheme.spacingBase),
            GridView.builder(
              shrinkWrap: true,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: AppTheme.spacingSm,
                crossAxisSpacing: AppTheme.spacingSm,
              ),
              itemCount: _avatarIcons.length,
              itemBuilder: (context, index) {
                final isSelected = index == user.avatarIndex;
                return GestureDetector(
                  onTap: () {
                    ref.read(authServiceProvider).updateAvatarIndex(index);
                    Navigator.pop(context);
                  },
                  child: CircleAvatar(
                    backgroundColor: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    child: Icon(
                      _avatarIcons[index],
                      color: isSelected
                          ? theme.colorScheme.onPrimary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Section pseudonyme : affichage + edition inline
  Widget _buildPseudoSection(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    Translations i18n,
    AuthUser user,
  ) {
    if (_isEditingPseudo) {
      // SW-SKIN-L3e : Card -> AppCard, padding porte par AppCard (iso-rendu).
      return AppCard(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        child: Column(
          children: [
            TextField(
              controller: _pseudoController,
              autofocus: true,
              maxLength: 30,
              decoration: InputDecoration(
                labelText: i18n.auth.pseudonym,
                hintText: i18n.auth.pseudonymHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    setState(() => _isEditingPseudo = false);
                  },
                  child: Text(i18n.auth.cancel),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                // SW-SKIN-L3e : ElevatedButton -> AppButton primary.
                // isFullWidth:false pour rester dans la rangee d'actions
                // alignee a droite (iso-rendu du CTA d'edition).
                AppButton(
                  isFullWidth: false,
                  label: i18n.auth.save,
                  onPressed: () {
                    ref
                        .read(authServiceProvider)
                        .updateDisplayName(_pseudoController.text);
                    setState(() => _isEditingPseudo = false);
                  },
                ),
              ],
            ),
          ],
        ),
      );
    }

    // Mode affichage
    final displayName = user.displayName ?? i18n.auth.anonymous;
    return Center(
      child: GestureDetector(
        onTap: () {
          _pseudoController.text = user.displayName ?? '';
          setState(() => _isEditingPseudo = true);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(displayName, style: theme.textTheme.headlineMedium),
            const SizedBox(width: AppTheme.spacingXs),
            Icon(Icons.edit, size: 18, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }

  void _confirmSignOut(BuildContext context, WidgetRef ref, Translations i18n) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(i18n.auth.signOutConfirm),
        content: Text(i18n.auth.signOutMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(i18n.auth.cancel),
          ),
          // SW-SKIN-L3e : ElevatedButton -> AppButton primary, isFullWidth:false
          // (action de dialogue, aux cotes du TextButton Annuler laisse tel quel).
          AppButton(
            isFullWidth: false,
            label: i18n.auth.signOut,
            onPressed: () {
              ref.read(authServiceProvider).signOut();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Translations i18n) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(i18n.auth.deleteConfirm),
        content: Text(i18n.auth.deleteMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(i18n.auth.cancel),
          ),
          // SW-SKIN-L3e : ElevatedButton a fond rouge -> AppButton filledTone
          // (fond plein = rougeUrgence, texte blanc). Conserve la couleur
          // SEMANTIQUE de danger de la suppression de compte, isFullWidth:false
          // pour rester une action de dialogue.
          AppButton(
            variant: AppButtonVariant.filledTone,
            tone: AppTheme.rougeUrgence,
            isFullWidth: false,
            label: i18n.auth.deleteAccount,
            onPressed: () {
              ref.read(authServiceProvider).deleteAccount();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
