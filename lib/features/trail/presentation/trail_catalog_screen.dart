import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/trail_config.dart';
import '../../../core/config/trail_selection.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/routing/home_location_provider.dart';
import '../../../core/services/monetization_service.dart';
import '../../../core/services/session_demo.dart';
import '../../../core/theme/app_theme.dart';
import '../../ads/presentation/banner_ad_slot.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/paywall_sheet.dart';
import '../../../core/branding/stepways_icons.dart';

/// Ecran catalogue des sentiers disponibles.
///
/// Cablage navigation (design #88246) : en P2-P3 (donnees fictives, sans
/// Firebase, #84627) le catalogue affiche la liste des sentiers EMBARQUES
/// ([availableTrailsProvider] = catalogue statique [TrailCatalog]) — toujours
/// presents et resolvables, donc navigables hors ligne. Le manifeste distant
/// Drift ([catalogStateProvider]) reste reserve a la Phase 4 (telechargement
/// reel). Chaque sentier propose un bouton "Entrer" qui ecrit la selection
/// ([selectedTrailIdProvider]) puis ouvre le shell sur /map : c'est l'entree
/// du coeur de l'app (anciennement orpheline).
class TrailCatalogScreen extends ConsumerWidget {
  const TrailCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final trails = ref.watch(availableTrailsProvider);

    return Scaffold(
      // Ph5 (L6d) : AppHeader universel (catalogue — §4 header standard ; barre
      // filtres/tri non prevue concretement -> pas de barre contextuelle).
      //
      // Q2 (tache 568) — LE RETOUR NE DERIVE PLUS VERS UN SENTIER QU'ON N'A PAS
      // CHOISI. Defaut de Chris (26/09 09:48), verbatim : « un retour arriere
      // arrive a mare a mare », a la premiere ouverture de l'application.
      //
      // MECANIQUE DU DEFAUT : on entre ici par `context.go('/catalog')`, qui
      // REMPLACE la pile. Sans historique, `context.canPop()` est faux et
      // l'`AppHeader` retombe sur l'accueil CONTEXTUEL
      // ([homeLocationProvider]) — donc sur le COCKPIT (`/home`) des qu'une
      // rando active existe. Le randonneur atterrissait sur le cockpit d'un
      // sentier qu'il n'avait ni choisi ni telecharge.
      //
      // CORRECTIF : le catalogue FORCE son accueil de repli sur « Mes treks ».
      // C'est le seul ecran ou la derivation maison/terrain n'a pas de sens : on
      // vient ICI pour CHOISIR un sentier, le retour doit donc ramener a la liste
      // des treks, jamais dans un trek. Les portes d'entree de l'accueil maison
      // EMPILENT par ailleurs le catalogue (`push`), si bien qu'en usage nominal
      // le retour DEPILE — ce repli ne sert qu'a l'arrivee depuis l'onboarding,
      // pile vide.
      appBar: AppHeader(
        title: t.catalog.title,
        homeLocation: HomeLocations.maison,
      ),
      // --- LA BANNIERE PUBLICITAIRE, VOLET APP-WIDE (tache 595, B1/B2) ---
      //
      // Le catalogue n'a AUCUN trek en contexte — c'est justement l'ecran ou
      // l'on choisit le sien. La regle d'or #99404 y garde malgre tout ses deux
      // volets app-wide : un ABONNE ACTIF est sans pub PARTOUT tant qu'il paie,
      // et une RECOMPENSE VIDEO couvre 24 h, partout aussi. Seul « trek achete
      // = sans pub sur CE trek » n'a rien a dire ici, et c'est precisement ce
      // que dit [BannerAdSlot.horsTrek].
      //
      // Aucun bouton d'urgence sur cet ecran : le SOS ne vit qu'en terrain.
      bottomNavigationBar: const BannerAdSlot.horsTrek(),
      body: trails.isEmpty
          ? EmptyState(
              icon: StepwaysIcons.catalogueSentiers,
              title: t.catalog.emptyTitle,
              subtitle: t.catalog.emptySubtitle,
            )
          : ListView(
              key: const ValueKey('trail-catalog-list'),
              padding: const EdgeInsets.only(
                top: AppTheme.spacingSm,
                bottom: AppTheme.spacingXl,
              ),
              children: [
                // LE BOUTON DEMO, EN TETE (tache 634, DEM-260929-1123).
                //
                // Verbatim de Christophe : « il faut mettre demo en haut des
                // sentiers juste un bouton "paasez en mode demo" », puis « UN
                // BOUTON DEMO ORANGE TOUT BETE, au-dessus des sentiers non
                // achetes : quand tu cliques dessus tu arrives a la demo Mare a
                // Mare ». Il est ici, et il est orange.
                const _BoutonDemo(),
                for (final trail in trails)
                  _AvailableTrailCard(
                    trail: trail,
                    onEnter: () => _enterTrail(context, ref, trail.id),
                  ),
              ],
            ),
    );
  }

  /// Entre dans le sentier [trailId] : ecrit la selection (le moteur entier
  /// suit via trailConfigProvider) puis ouvre le COCKPIT DE PREPARATION.
  ///
  /// FIX CYCLE 2 (issue 1) : « Entrer » ouvrait la CARTE DE NAVIGATION LIVE
  /// (`/map`) — une debutante atterrissait directement sur la carte au lieu de la
  /// fiche/prepa. NOMINAL GR20 : selectionner un sentier ouvre son COCKPIT (hub
  /// Preparer/Randonner/Apres : faisabilite -> itineraire -> prepa), la carte
  /// live restant reservee au DEMARRAGE EFFECTIF du trek. On aligne donc sur le
  /// geste eprouve de l'accueil « Mes treks » ([MyTreksScreen] : selection +
  /// `go('/home')`) : `go` bascule vers l'accueil « terrain » (cockpit), pas un
  /// `push` d'ecran de detail — c'est un changement d'accueil contextuel, tout le
  /// contexte du sentier suit la selection (trailConfigProvider en derive).
  void _enterTrail(BuildContext context, WidgetRef ref, String trailId) {
    // UN SENTIER NON ACHETE NE S'OUVRE PLUS DU TOUT (tache 634, DEM-1123).
    //
    // CE QUI SE PASSAIT, MESURE. Cette methode n'avait AUCUNE garde d'acces :
    // taper « Entrer » sur un sentier payant qu'on ne possede pas ouvrait son
    // cockpit de preparation, avec la banniere publicitaire, sans un mot. Pas
    // de bandeau, pas d'explication — le « mode demo » etait SUBI. Verbatim de
    // Christophe : « MAIS NON !!! il s ouvre en mode prepa AVEC PUB !!! ».
    //
    // CE QUI SE PASSE MAINTENANT : un sentier qu'on ne peut pas jouer mene au
    // PARCOURS DE DEBLOCAGE qui existait deja (la vitrine : etapes ou
    // paiement). Pour DECOUVRIR l'application, il y a le bouton demo, en tete
    // de cette liste — un mode qu'on choisit, pas un bridage qu'on subit.
    final jouable = !(ref.read(isDemoModeProvider(trailId)).value ?? false);
    if (!jouable) {
      acheterSentier(context, ref, trailId: trailId);
      return;
    }

    // On CHANGE DE SENTIER, puis on change d'ecran — dans cet ordre, et la
    // bascule est resolue avant la navigation ([choisirSentier] dit pourquoi :
    // sans cela, quatre « setState during build » par bascule).
    choisirSentier(ref, trailId);
    context.go('/home');
  }
}

/// LE BOUTON DEMO ORANGE, EN TETE DU CATALOGUE (tache 634, DEM-260929-1123).
///
/// Verbatim de Christophe : « UN BOUTON DEMO ORANGE TOUT BETE, au-dessus des
/// sentiers non achetes : quand tu cliques dessus tu arrives a la demo Mare a
/// Mare » ; « un bouton demo qui montre comment marche l appli de A a Z ».
///
/// IL N'OUVRE QU'UN SENTIER, ET TOUJOURS LE MEME : le sentier de demonstration
/// du lot 601, deux etapes, GRATUIT pour tout le monde. Il n'accorde donc aucun
/// droit a personne — la demo MONTRE, elle ne DEBLOQUE jamais, et c'est le
/// garde-fou que le lot 601 avait paye cher (suppression du drapeau
/// `isShowcaseTrail`, une exemption etant un trou dans le modele d'acces).
class _BoutonDemo extends ConsumerWidget {
  const _BoutonDemo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingBase,
        AppTheme.spacingSm,
        AppTheme.spacingBase,
        AppTheme.spacingBase,
      ),
      child: Material(
        color: AppTheme.orangeDifficile,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: InkWell(
          key: const ValueKey('catalog-demo-button'),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          onTap: () {
            // On entre en demo AVANT de choisir le sentier : le cadre orange
            // et la sortie sont donc deja poses quand le cockpit s'affiche.
            ref.read(sessionDemoProvider.notifier).entrer();
            choisirSentier(ref, kSentierDeDemo);
            context.go('/home');
          },
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            child: Row(
              children: [
                const StepIcon(
                  StepwaysIcons.eprouvette,
                  size: 28,
                  color: Colors.white,
                ),
                const SizedBox(width: AppTheme.spacingBase),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.demo.boutonTitre,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        t.demo.boutonSous,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const StepIcon(
                  StepwaysIcons.flecheAvant,
                  size: 20,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// LE NOM D'UN SENTIER TEL QUE LE RANDONNEUR LE LIT, dans SA langue.
///
/// Pour un sentier payant, c'est son nom propre — « Mare a Mare Centre » ne se
/// traduit pas. Pour un SENTIER GRATUIT (tache 601), le nom se COMPOSE : le nom
/// propre du terrain, plus la mention de gratuite dans les cinq langues
/// (`catalog.freeTrailName`). Chris a demande que le sentier demo ait « son
/// propre nom dans les cinq langues » : le voici, sans recopier cinq fois un
/// toponyme corse qui est le meme partout.
String trailDisplayName(Translations t, TrailConfig trail) => trail.isFreeTrail
    ? t.catalog.freeTrailName(nom: trail.displayName)
    : trail.displayName;

/// Carte d'un sentier disponible au catalogue : nom, region, stats + bouton
/// primaire "Entrer". Pas de notion de telechargement en P2-P3 (donnees
/// embarquees) : le sentier est directement utilisable.
///
/// UN SENTIER GRATUIT LE DIT (tache 601) : pastille « Gratuit » sous son nom, et
/// une ligne qui annonce ce qu'il contient. Le randonneur doit pouvoir choisir
/// entre les DEUX entrees du Mare a Mare sans ouvrir ni l'une ni l'autre — c'est
/// tout le sens de « il y a mare a mare ET mare a mare demo des le catalogue ».
///
/// ET ON PEUT L'ACHETER D'ICI (tache 614, demande de Christophe du 28/09 11:41).
/// La carte portait une seule action — « Entrer » — donc le randonneur qui
/// DECOUVRE un sentier et veut l'acheter tout de suite devait d'abord entrer
/// dedans, preparer trois cartes, puis appuyer sur « Démarrer » pour rencontrer
/// enfin un refus qui lui proposait de payer. Le bouton d'achat est desormais
/// sur la carte, a cote de « Entrer », et il emprunte le geste unique
/// [acheterSentier] — le meme que la preparation et que le depart.
class _AvailableTrailCard extends ConsumerWidget {
  const _AvailableTrailCard({required this.trail, required this.onEnter});

  final TrailConfig trail;
  final VoidCallback onEnter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final nom = trailDisplayName(t, trail);
    // ACHETABLE = « en mode demo » : ni possede, ni gratuit, ni couvert par un
    // abonnement ([MonetizationService.isDemoMode], source unique et REACTIVE
    // — un achat repeint la carte sans changer d'ecran). Un bouton d'achat sur
    // un sentier deja acquis ou gratuit serait un bouton qui ment, exactement
    // comme le bouton video sur une banniere qui n'existe pas.
    final achetable = ref.watch(isDemoModeProvider(trail.id)).value ?? false;
    // LE PRIX SE DEMANDE AU SERVICE, il ne se recalcule pas ici — et depuis
    // l'avenant 614 le service le LIT AU CATALOGUE, donc cet ecran ne lui
    // transmet meme plus le nombre d'etapes du sentier. Une seconde formule
    // dans le catalogue serait la meme faute que trois chemins d'achat, sur le
    // montant ; un second NOMBRE l'etait tout autant.
    final monetisation = ref.watch(monetizationServiceProvider);

    // SW-SKIN-L3e : Card -> AppCard. key + margin conserves ; padding base porte
    // par AppCard (iso-rendu de la carte sentier du catalogue).
    return AppCard(
      key: ValueKey('catalog-trail-${trail.id}'),
      margin: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre + icone.
          Row(
            children: [
              ExcludeSemantics(
                child: StepIcon(
                  StepwaysIcons.sommet,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  nom,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          // Region + pays.
          Text(
            '${trail.region}, ${trail.country}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.grisTexteSecondaire,
            ),
          ),
          // GRATUIT : la pastille, et ce que le sentier contient vraiment.
          if (trail.isFreeTrail) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Semantics(
              label: t.catalog.a11y.freeTrailBadge,
              child: Container(
                key: ValueKey('catalog-free-badge-${trail.id}'),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.vertFacile.withAlpha(28),
                  borderRadius: BorderRadius.circular(AppTheme.spacingSm),
                  border: Border.all(color: AppTheme.vertFacile.withAlpha(90)),
                ),
                child: Text(
                  t.catalog.freeBadge,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppTheme.vertFacile,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingXs),
            Text(
              t.catalog.freeTrailTagline(etapes: trail.totalStages),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.grisTexteSecondaire,
              ),
            ),
          ],
          const SizedBox(height: AppTheme.spacingXs),
          // Stats principales — Wrap pour ne pas deborder a textScale 2x.
          Wrap(
            spacing: AppTheme.spacingBase,
            runSpacing: AppTheme.spacingXs,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _InfoChip(
                icon: StepwaysIcons.distance,
                label: '${trail.totalDistanceKm.toStringAsFixed(0)} km',
                theme: theme,
              ),
              _InfoChip(
                icon: StepwaysIcons.denivelePlus,
                label: '${trail.totalElevationGain} m D+',
                theme: theme,
              ),
              _InfoChip(
                icon: StepwaysIcons.depart,
                label: '${trail.totalStages}',
                theme: theme,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingMd),
          // Action primaire : entrer dans le sentier (cablage nav #88246).
          SizedBox(
            width: double.infinity,
            child: Semantics(
              button: true,
              label: t.catalog.a11y.enterButton(nom: nom),
              // SW-SKIN-L3e : FilledButton.icon -> AppButton primary (arbitrage
              // #A5), pleine largeur (SizedBox width infinity conserve).
              // key/Semantics(button+label) preserves.
              child: AppButton(
                key: ValueKey('catalog-enter-${trail.id}'),
                icon: StepwaysIcons.flecheAvant,
                label: t.catalog.enter,
                onPressed: onEnter,
              ),
            ),
          ),
          // ACHETER DEPUIS LE CATALOGUE (tache 614) — premier des trois points
          // d'entree. Absent des que le sentier n'est plus a vendre : possede,
          // gratuit, ou couvert par un abonnement.
          if (achetable) ...[
            const SizedBox(height: AppTheme.spacingSm),
            SizedBox(
              width: double.infinity,
              child: AppButton(
                key: ValueKey('catalog-buy-${trail.id}'),
                variant: AppButtonVariant.outline,
                icon: StepwaysIcons.cadenasOuvert,
                label: t.monetization.buyCtaWithPrice(
                  price: monetisation
                      .eurPriceForTrail(trail.id)
                      .toStringAsFixed(2),
                ),
                onPressed: () =>
                    acheterSentier(context, ref, trailId: trail.id),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Petit chip d'information avec icone (region, distance, etapes).
class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.theme,
  });

  final String icon;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: StepIcon(icon, size: 14, color: AppTheme.grisTexteSecondaire),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.grisTexteSecondaire,
          ),
        ),
      ],
    );
  }
}
