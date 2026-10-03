/// Pseudonyme et avatar choisi parmi huit icones locales : il n'y a rien
/// d'autre a saisir, et c'est voulu.
library;

import 'dart:async';

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
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/section_header.dart';
import '../../../core/services/pilote_demo.dart';
import '../../../core/services/session_demo.dart';
import '../../../shared/widgets/grise_en_demo.dart';
import '../../safety/presentation/refus_sauvegarde_systeme_dialog.dart';
import '../../settings/settings_facade.dart'
    show DominantHand, DominantHandValues, settingsProvider;
import '../domain/auth_service.dart';
import '../providers/auth_provider.dart';
import '../../../core/branding/stepways_icons.dart';

/// Liste des icones d'avatars locaux predefinis.
///
/// 8 avatars thematiques randonnee, accessibles par index (0-7).
const _avatarIcons = <String>[
  StepwaysIcons.chaussure,
  StepwaysIcons.sommet,
  StepwaysIcons.sommet,
  StepwaysIcons.foret,
  StepwaysIcons.soleil,
  StepwaysIcons.favori,
  StepwaysIcons.catalogueSentiers,
  StepwaysIcons.sommet,
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
        // L'ATTENTE EST BORNEE (tache 649). Mesure sur l'emulateur du 30/09 :
        // « Mon compte » ouvert depuis le menu du trek tournait SANS FIN — le
        // flux d'identite n'emettait jamais (Firestore repondait
        // `permission-denied` en boucle dans le journal), donc `loading` ne se
        // terminait pas et le randonneur n'avait plus qu'a tuer l'application.
        // La cause du refus Firestore n'est PAS traitee ici : ce lot ferme le
        // silence, pas le refus.
        loading: () => _AttenteBornee(
          message: i18n.auth.errorTimeout,
          libelleReessayer: i18n.common.retry,
          onReessayer: () => ref.invalidate(currentUserProvider),
        ),
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
          SectionHeader(
            title: i18n.auth.profile,
            icon: StepwaysIcons.monCompte,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // GRISEE EN DEMO (tache 638, bug 14) : se connecter a Google, se
          // deconnecter, changer son pseudo ou son avatar touchent a l'IDENTITE
          // du randonneur, et l'identite n'est pas une demonstration. La section
          // reste lisible, ses gestes sont visiblement indisponibles.
          GriseEnDemo(
            child: _buildAccountSection(context, ref, theme, i18n, user),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // Section « Main dominante » (lateralite, R9/R10) : place le SOS et
          // les commandes critiques du cote de la main dominante (thumb zone).
          // Donnee NON sensible, defaut droitier. Persiste via settingsProvider.
          SectionHeader(
            title: i18n.navPilote.dominantHand,
            icon: StepwaysIcons.geste,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          GriseEnDemo(
            child: _buildDominantHandSection(context, ref, theme, i18n),
          ),
          const SizedBox(height: AppTheme.spacingLg),

          // SECTION « MODE DEMO » (tache 638, bug 18 — precision de Christophe du
          // 30/09 10:30, verbatim : « on pourra le retrouver dans Mon compte »).
          //
          // C'est l'autre porte d'entree de la demo, et la SEULE quand le
          // randonneur a coche « Cacher le mode demo » en sortant. Elle ne parle
          // jamais de droits : la demo ne debloque rien, elle montre.
          SectionHeader(
            title: i18n.demo.compteTitre,
            icon: StepwaysIcons.eprouvette,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          _buildDemoSection(context, ref, i18n),
          const SizedBox(height: AppTheme.spacingLg),

          // Zone dangereuse — suppression de compte (parite GR20 : section
          // dediee en rouge, requise par les stores).
          SectionHeader(
            title: i18n.auth.deleteAccount,
            icon: StepwaysIcons.danger,
            iconColor: AppTheme.rougeUrgence,
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // GRISEE EN DEMO : on ne supprime pas un compte depuis une demo.
          GriseEnDemo(child: _buildDangerZone(context, ref, theme, i18n)),
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
        // GRISES EN DEMO (bug 14) : avatar et pseudo s'ecrivent dans le compte.
        GriseEnDemo(
          child: _buildAvatarSection(context, ref, theme, i18n, user),
        ),
        const SizedBox(height: AppTheme.spacingXs),
        GriseEnDemo(
          child: _buildPseudoSection(context, ref, theme, i18n, user),
        ),
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
        // TACHE 639 (bug 4) : le geste est pose a l interieur, la carte le DECLARE pour etre dessinee en relief.
        interactif: true,
        padding: EdgeInsets.zero,
        child: ListTile(
          key: const ValueKey('profil-connexion-google'),
          leading: const StepIcon(StepwaysIcons.connexion),
          title: Text(i18n.auth.signInGoogle),
          subtitle: Text(i18n.auth.signInGoogleDesc),
          trailing: const StepIcon(StepwaysIcons.chevronDroite),
          onTap: () async {
            final service = ref.read(authServiceProvider);
            await service.signInWithGoogleSilent();
            // LA CASE PRE-COCHEE DE REFUS, ICI ET PAS AILLEURS (tache 612).
            // Decision de Christophe du 28/09 10:49 : « quand il se connecte ».
            // Posee APRES la connexion, parce qu'une question posee avant
            // aurait ete posee aussi a qui renonce a se connecter — et il n'y a
            // rien a lui demander, la protection s'applique deja pour lui.
            // Elle ne se repose pas une fois tranchee.
            if (context.mounted) {
              await RefusSauvegardeSystemeDialog.poserSiNecessaire(
                context,
                ref,
              );
            }
          },
        ),
      );
    }

    // Connecte : proposer la deconnexion.
    return AppCard(
      // TACHE 639 (bug 4) : le geste est pose a l interieur, la carte le DECLARE pour etre dessinee en relief.
      interactif: true,
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: const StepIcon(StepwaysIcons.deconnexion),
        title: Text(i18n.auth.signOut),
        subtitle: Text(i18n.auth.signOutDesc),
        onTap: () => _confirmSignOut(context, ref, i18n),
      ),
    );
  }

  /// Section « Mode demo » (tache 638, bug 18 ; tache 649).
  ///
  /// DEUX LIGNES, ET PAS PLUS. « Revoir la demo » la relance (elle est toujours
  /// relancable, un nombre illimite de fois : rien ne s'ecrit, donc il n'y a rien
  /// a epuiser).
  ///
  /// LA SECONDE LIGNE EST DEVENUE UN INTERRUPTEUR, ET ELLE EST TOUJOURS LA
  /// (tache 649). Elle n'apparaissait qu'une fois le bouton CACHE, parce que le
  /// seul endroit ou l'on pouvait le cacher etait le dialogue de fin de demo. Ce
  /// dialogue ne s'ouvrait JAMAIS — il etait pose au-dessus du `Navigator` — donc
  /// le reglage etait en pratique inatteignable dans les deux sens. Il vit
  /// desormais ici en permanence, ou Christophe a dit qu'on retrouve la demo, et
  /// il se defait aussi bien qu'il se fait.
  Widget _buildDemoSection(
    BuildContext context,
    WidgetRef ref,
    Translations i18n,
  ) {
    final cache = ref.watch(boutonDemoCacheProvider);
    return Column(
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: ListTile(
            key: const ValueKey('compte-revoir-demo'),
            leading: const StepIcon(StepwaysIcons.eprouvette),
            title: Text(i18n.demo.compteRelancer),
            subtitle: Text(i18n.demo.compteRelancerSous),
            trailing: const StepIcon(StepwaysIcons.chevronDroite),
            onTap: () => relancerLaDemoDepuisMonCompte(ref, context),
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        AppCard(
          padding: EdgeInsets.zero,
          child: SwitchListTile(
            key: const ValueKey('compte-reafficher-bouton-demo'),
            secondary: const StepIcon(StepwaysIcons.catalogueSentiers),
            title: Text(i18n.demo.compteReafficher),
            subtitle: Text(i18n.demo.compteReafficherSous),
            // L'INTERRUPTEUR DIT « AFFICHER », LE REGLAGE STOCKE « CACHER » :
            // il est donc l'inverse de la valeur en base, et il faut le lire
            // comme ca pour que l'etiquette ne mente pas.
            value: !cache,
            onChanged: (afficher) =>
                ref.read(boutonDemoCacheProvider.notifier).definir(!afficher),
          ),
        ),
      ],
    );
  }

  /// Version + build en bas de page (parite GR20, tache 517).
  ///
  /// Lue dynamiquement via package_info_plus. Format mandate :
  /// « StepWays v0.1.0 (build 1) ». Fallback discret « ... » le temps du
  /// chargement du plugin (jamais de spinner — coherent avec l'offline-first).
  /// TACHE 632 — LE LOGO AU-DESSUS DE LA VERSION. Ce pied de page etait le seul
  /// endroit de toute l'application ou le mot « StepWays » etait ecrit, et il
  /// n'y avait aucune marque a cote. L'application n'a pas d'ecran « a propos »
  /// (aucune route) : ce bloc en tient lieu, c'est donc ici que la marque se
  /// montre en clair.
  Widget _buildVersionFooter(ThemeData theme, Translations i18n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const AppLogo.horizontal(hauteur: 28),
          const SizedBox(height: AppTheme.spacingSm),
          FutureBuilder<PackageInfo>(
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
        ],
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
                icon: const StepIcon(StepwaysIcons.geste),
              ),
              ButtonSegment<DominantHand>(
                value: DominantHandValues.left,
                label: Text(i18n.navPilote.dominantHandLeft),
                icon: const StepIcon(StepwaysIcons.geste),
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
      // TACHE 639 (bug 4) : le geste est pose a l interieur, la carte le DECLARE pour etre dessinee en relief.
      interactif: true,
      padding: EdgeInsets.zero,
      borderColor: AppTheme.rougeUrgence.withValues(alpha: 0.4),
      child: ListTile(
        leading: const StepIcon(
          StepwaysIcons.corbeille,
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
              child: StepIcon(
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
                    child: StepIcon(
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
            // FIX-1 (finding m2) : aucun `trim` n'etait applique — un pseudo de
            // 3 espaces passait tel quel et s'affichait comme un nom vide. Le
            // pseudo est desormais trimme a l'enregistrement, et le bouton
            // reste DESACTIVE tant qu'il est vide une fois les espaces retires
            // (etat visible, plutot qu'un enregistrement muet de rien).
            TextField(
              key: const ValueKey('profile-pseudo-field'),
              controller: _pseudoController,
              autofocus: true,
              maxLength: 30,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: i18n.auth.pseudonym,
                hintText: i18n.auth.pseudonymHint,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            // DEBORDEMENT constate pendant FIX-1 (hors findings, corrige au
            // passage) : en 390 px de large, cette rangee d'actions debordait de
            // 7,8 px (bandes jaunes et noires a l'ecran). `Wrap` la fait passer
            // a la ligne au lieu de deborder, sans changer le rendu au large.
            Wrap(
              alignment: WrapAlignment.end,
              spacing: AppTheme.spacingSm,
              runSpacing: AppTheme.spacingXs,
              children: [
                AppButton(
                  variant: AppButtonVariant.text,
                  label: i18n.auth.cancel,
                  isFullWidth: false,
                  onPressed: () {
                    setState(() => _isEditingPseudo = false);
                  },
                ),
                // SW-SKIN-L3e : ElevatedButton -> AppButton primary.
                // isFullWidth:false pour rester dans la rangee d'actions
                // alignee a droite (iso-rendu du CTA d'edition).
                AppButton(
                  key: const ValueKey('profile-pseudo-save'),
                  isFullWidth: false,
                  label: i18n.auth.save,
                  onPressed: _pseudoController.text.trim().isEmpty
                      ? null
                      : () {
                          ref
                              .read(authServiceProvider)
                              .updateDisplayName(_pseudoController.text.trim());
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
    // MINEUR-1 (campagne personas N2) : le pseudo etait pose dans une `Row`
    // sans contrainte de largeur. Un pseudo a la longueur MAXIMALE que la
    // saisie autorise elle-meme (`maxLength: 30` ci-dessus) debordait l'ecran
    // de 126 px, bandes jaunes et noires a l'appui.
    // POURQUOI `Flexible` et pas une troncature : l'application accepte 30
    // caracteres, elle doit donc savoir les AFFICHER. `Flexible` borne le texte
    // a la largeur disponible et le laisse passer a la ligne — le pseudo reste
    // lisible en entier, et la rangee reste centree sur les pseudos courts
    // grace a `MainAxisSize.min`.
    // Les deux autres points d'affichage du meme pseudo (l'en-tete du HUB via
    // AppGradientHeader, la carte de membre de groupe) placent deja leur texte
    // dans un `Expanded` : ils sont bornes, rien a corriger la-bas.
    return Center(
      child: GestureDetector(
        onTap: () {
          _pseudoController.text = user.displayName ?? '';
          setState(() => _isEditingPseudo = true);
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                displayName,
                style: theme.textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: AppTheme.spacingXs),
            StepIcon(
              StepwaysIcons.crayon,
              size: 18,
              color: theme.colorScheme.primary,
            ),
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
          AppButton(
            variant: AppButtonVariant.text,
            label: i18n.auth.cancel,
            isFullWidth: false,
            onPressed: () => Navigator.pop(context),
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
          AppButton(
            variant: AppButtonVariant.text,
            label: i18n.auth.cancel,
            isFullWidth: false,
            onPressed: () => Navigator.pop(context),
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

/// UNE ATTENTE QUI FINIT TOUJOURS PAR DIRE QUELQUE CHOSE (tache 649).
///
/// CE QUI A ETE MESURE. Sur l'emulateur, « Mon compte » ouvert depuis le menu du
/// trek tournait indefiniment : le flux d'identite n'emettait jamais, le journal
/// repetait des refus Firestore (`permission-denied`), et l'ecran restait un
/// rond qui tourne. Un rond qui tourne ne dit RIEN : ni « patiente », ni « c'est
/// casse ». Le randonneur ne pouvait que tuer l'application.
///
/// CE WIDGET NE CHANGE RIEN QUAND CA MARCHE : pendant [kDelaiAvantEchecCompte]
/// il montre exactement le meme rond qu'avant, et une reponse qui arrive dans ce
/// delai le fait disparaitre sans que rien d'autre ne s'affiche. Passe ce delai,
/// il remplace le rond par un message et un bouton « Reessayer ».
///
/// LE DELAI N'EST PAS UN DELAI DE RESEAU, C'EST UN DELAI DE PATIENCE : il ne
/// coupe aucune requete et n'annule rien. La requete continue ; si elle finit
/// par repondre, l'ecran se remplit tout seul.
class _AttenteBornee extends StatefulWidget {
  const _AttenteBornee({
    required this.message,
    required this.libelleReessayer,
    required this.onReessayer,
  });

  final String message;
  final String libelleReessayer;
  final VoidCallback onReessayer;

  @override
  State<_AttenteBornee> createState() => _AttenteBorneeState();
}

/// Au-dela de ce delai, une attente devient un echec qui se dit.
///
/// Huit secondes : assez pour un reseau lent et un demarrage a froid de
/// Firebase, trop peu pour laisser croire que l'ecran est mort.
const Duration kDelaiAvantEchecCompte = Duration(seconds: 8);

class _AttenteBorneeState extends State<_AttenteBornee> {
  Timer? _minuteur;
  bool _tropLong = false;

  @override
  void initState() {
    super.initState();
    _armer();
  }

  void _armer() {
    _minuteur?.cancel();
    _minuteur = Timer(kDelaiAvantEchecCompte, () {
      if (mounted) setState(() => _tropLong = true);
    });
  }

  @override
  void dispose() {
    _minuteur?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_tropLong) {
      return const Center(child: CircularProgressIndicator());
    }
    return Center(
      key: const ValueKey('compte-echec-attente'),
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const StepIcon(StepwaysIcons.danger, size: 40),
            const SizedBox(height: AppTheme.spacingBase),
            Text(widget.message, textAlign: TextAlign.center),
            const SizedBox(height: AppTheme.spacingBase),
            AppButton(
              key: const ValueKey('compte-reessayer'),
              isFullWidth: false,
              label: widget.libelleReessayer,
              onPressed: () {
                // ON REPART POUR UN TOUR, PAS POUR L'ETERNITE : le minuteur est
                // rearme, donc un second echec se dira aussi.
                setState(() => _tropLong = false);
                _armer();
                widget.onReessayer();
              },
            ),
          ],
        ),
      ),
    );
  }
}
