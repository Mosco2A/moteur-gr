/// Le catalogue, qui montre les sentiers EMBARQUES pour rester navigable hors
/// ligne ; le manifeste distant est l'etage suivant.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/screen_entry.dart';
import '../../../core/config/trail_config.dart';
import '../../../core/config/trail_selection.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/routing/home_location_provider.dart';
import '../../../core/services/monetization_service.dart';
import '../../../core/services/pilote_demo.dart';
import '../../../core/services/session_demo.dart';
import '../../../core/theme/app_theme.dart';
import '../../ads/ads_facade.dart' show AdStateBadge, BannerAdSlot;
import '../../ads/domain/ad_state.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/grise_en_demo.dart';
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
/// reel). Chaque sentier propose UNE action, celle qui correspond a son etat
/// (tache 639, bug 2) : ACHETER quand il n'est pas possede, PREPARER quand il
/// l'est — « Preparer » ecrit la selection ([selectedTrailIdProvider]) puis
/// ouvre le cockpit de preparation, c'est l'entree du coeur de l'app.
class TrailCatalogScreen extends ConsumerWidget {
  const TrailCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // LA MIETTE D ENTREE D ECRAN (lot 645-09). Cet ecran n a pas
    // d etat : le service deduplique, donc une miette part par
    // ENTREE et non par reconstruction. Rien n est attendu ici.
    observeScreenEntry(ref, ScreenBreadcrumb.trailCatalog);
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
              icon: StepwaysIcons.trailCatalog,
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
                //
                // IL RESTE A LA MEME PLACE, AVANT ET APRES UNE DEMO, ET MEME
                // AVEC DES SENTIERS ACHETES (tache 638, bug 18 —
                // DEM-260930-1027) : aucun drapeau « deja vue » ne le cache.
                // Seul le randonneur peut le faire disparaitre, en cochant
                // « Cacher le mode demo » en sortant — et il le retrouve alors
                // dans Mon compte (precision du 30/09 10:30).
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
    // « PREPARER » PREPARE, MEME SANS ACHAT (tache 639 avenant, DEM-260930-1241).
    //
    // HISTOIRE DE CETTE GARDE, EN TROIS TEMPS, PARCE QU'ELLE A CHANGE DEUX FOIS.
    //
    //  1. AVANT LE LOT 634 : aucune garde. Taper « Entrer » sur un sentier payant
    //     qu'on ne possede pas ouvrait son cockpit avec la banniere, sans un mot
    //     d'explication — le mode gratuit etait SUBI, pas choisi. Verbatim de
    //     Christophe : « MAIS NON !!! il s ouvre en mode prepa AVEC PUB !!! ».
    //  2. LOT 634 : un sentier non achete ne s'ouvrait PLUS DU TOUT, il menait au
    //     parcours de deblocage. Ca reglait le « subi », mais ca FERMAIT la
    //     preparation gratuite, qui est un niveau du modele eco.
    //  3. DECISION DU 30/09 12:41 : la preparation sans achat est ROUVERTE, AVEC
    //     publicite, et elle est ANNONCEE. « je suis en prepa avec pub » est un
    //     etat legitime — le troisieme des trois que Christophe veut voir
    //     distingues. Ce qui reste ferme, c'est la REALISATION : partir en rando
    //     exige l'achat, et c'est `canRealizeTrail` (lot 594) qui le tient, en
    //     bas du cockpit, la ou on appuie sur « Demarrer ».
    //
    // CE QUI FAIT QUE CE N'EST PLUS « SUBI » : la carte le DIT avant d'ouvrir —
    // l'icone pub sur le bouton et la marque « Avec publicite » juste au-dessus
    // ([AdStateBadge]). Le randonneur sait ce qu'il va trouver, et il a
    // « Acheter » a cote s'il n'en veut pas.

    // On CHANGE DE SENTIER, puis on change d'ecran — dans cet ordre, et la
    // bascule est resolue avant la navigation ([chooseTrail] dit pourquoi :
    // sans cela, quatre « setState during build » par bascule).
    chooseTrail(ref, trailId);
    context.go('/home');
  }
}

/// LE BOUTON DEMO ORANGE, EN TETE DU CATALOGUE (tache 634, DEM-260929-1123).
///
/// Verbatim de Christophe : « UN BOUTON DEMO ORANGE TOUT BETE, au-dessus des
/// sentiers non achetes : quand tu cliques dessus tu arrives a la demo Mare a
/// Mare » ; « un bouton demo qui montre comment marche l appli de A a Z ».
///
/// IL N'OUVRE QU'UN SENTIER, ET TOUJOURS LE MEME : le MARE A MARE CENTRE
/// COMPLET, sept etapes (tache 638, bug 8 — DEM-260930-1014, verbatim : « la demo
/// de Mare a Mare ce doit etre la demo de Mare a Mare, pas un truc avec 2
/// etapes !! »). Il n'accorde aucun droit a personne : `ownsTrail`,
/// `canRealizeTrail` et `isDemoMode` repondent la meme chose pendant la demo
/// qu'en dehors. La demo MONTRE, elle ne DEBLOQUE jamais — c'est le garde-fou que
/// le lot 601 avait paye cher (suppression du drapeau `isShowcaseTrail`, une
/// exemption etant un trou dans le modele d'acces).
///
/// IL DISPARAIT SI, ET SEULEMENT SI, LE RANDONNEUR L'A DEMANDE
/// ([boutonDemoCacheProvider], case « Cacher le mode demo » du dialogue de
/// sortie). Il reste alors relancable depuis Mon compte, et rien d'autre ne peut
/// le faire disparaitre : ni une demo deja faite, ni un sentier achete.
class _BoutonDemo extends ConsumerWidget {
  const _BoutonDemo();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Cache par le randonneur : le catalogue n'en parle plus, Mon compte oui.
    if (ref.watch(boutonDemoCacheProvider)) return const SizedBox.shrink();
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
            // UNE SEULE PORTE D'ENTREE, ET ELLE SE SOUVIENT D'OU L'ON VENAIT
            // ([entrerEnDemo]) : le sentier selectionne avant la demo est note
            // pour etre restaure a la sortie (bug 19, DEM-260930-1028). Sans
            // cela, quitter la demo laissait le sentier de demo actif — « on est
            // toujours en mode demo sans le savoir ».
            entrerEnDemo(ref);
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
/// enfin un refus qui lui proposait de payer. L'achat est desormais sur la
/// carte, et il emprunte le geste unique [buyTrail] — le meme que la
/// preparation et que le depart.
///
/// UNE SEULE ACTION A LA FOIS (tache 639, bug 2). Le lot 614 avait pose l'achat
/// A COTE de « Entrer », si bien qu'un sentier non possede portait DEUX boutons
/// pour la MEME destination : « Entrer » y menait aussi, par la garde du lot 634.
/// La carte ne montre plus que l'action de son etat.
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
    // L'ICONE PUB SUR « PREPARER » (tache 639 avenant, DEM-260930-1223). Elle
    // n'apparait que quand une publicite va EFFECTIVEMENT s'afficher : ni
    // abonne, ni sentier achete, ni recompense video en cours. L'etat est LU
    // ([etatPubliciteProvider], qui consulte la source unique), jamais recalcule
    // ici — un second calcul finirait par dire autre chose que la banniere.
    // Pendant la lecture des droits, on ne promet pas de publicite : `false`.
    final avecPub =
        ref.watch(etatPubliciteProvider(trail.id)).value?.pubAffichee ?? false;
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
          const SizedBox(height: AppTheme.spacingSm),
          // LA MARQUE DE L'ETAT PUBLICITAIRE (tache 639 avenant, DEM-260930-1241).
          //
          // Elle dit LEQUEL des trois etats on vit — abonne, achete, ou
          // preparation avec publicite — parce que Christophe veut les
          // distinguer a l'oeil : « Il faut que l on fasse la diff entre = je
          // suis abonne et je n ai pas de pub en prepa, j ai achete un trek sans
          // pub, je suis en prepa avec pub ».
          Align(
            alignment: Alignment.centerLeft,
            child: AdStateBadge(trailId: trail.id),
          ),
          const SizedBox(height: AppTheme.spacingMd),
          // PREPARER TOUJOURS, ACHETER EN PLUS QUAND IL Y A QUELQUE CHOSE A
          // ACHETER (tache 639 avenant, DEM-260930-1241).
          //
          // CE QUE J'AVAIS FAIT, ET POURQUOI C'ETAIT TROP. Le premier passage de
          // la tache 639 (commit 11e3b8eb) avait mis UNE SEULE action par etat :
          // « Acheter » SEUL sur un sentier non possede. C'etait la bonne
          // correction du defaut d'origine (deux boutons pour une seule
          // destination, « Entrer » qui n'entrait pas) mais c'etait une de trop :
          // ca FERMAIT la preparation gratuite. Christophe l'a rouverte le meme
          // jour a 12:41 : la preparation sans achat reste possible, AVEC
          // publicite — c'est le niveau gratuit du modele eco, et l'achat
          // debloque la REALISATION, pas la preparation.
          //
          // LA CARTE PORTE DONC :
          //   * TOUJOURS « Preparer », qui ouvre le cockpit. Quand une publicite
          //     va s'afficher, le bouton porte l'icone pub qui le PREVIENT
          //     (DEM-260930-1223, « je parlais de l icone pub sur le bouton
          //     Preparer si on n est pas abonne ») ;
          //   * EN PLUS « Acheter », avec son prix, quand le sentier est encore
          //     a vendre — ni possede, ni gratuit, ni couvert par un abonnement.
          //
          // LA REGLE DES PUBS N'EST PAS REDEFINIE ICI, ET C'EST VOULU. Le cockpit
          // porte deja son emplacement ([BannerAdSlot] dans `hub_screen`), branche
          // sur la SOURCE UNIQUE [MonetizationService.isNoAdsActive]. L'icone et
          // la marque LISENT cette meme decision ([etatPubliciteProvider]) : elles
          // annoncent, elles ne decident pas.
          //
          // INTEGRATION 647 — ET GRISEE PENDANT LA DEMO (tache 638, bug 14). Les
          // deux lots ecrivaient ce bouton : 638 l enveloppe dans [GriseEnDemo]
          // parce qu une demo porte sur UN sentier et que basculer de sentier en
          // pleine demo est l etat hybride que le bug 19 denonce ; 639 lui donne
          // son nouveau nom, sa nouvelle icone et son libelle d accessibilite.
          // Les deux tiennent ensemble : le grisage dit QUAND le geste est
          // indisponible, 639 dit LEQUEL c est.
          GriseEnDemo(
            child: SizedBox(
              width: double.infinity,
              child: Semantics(
                button: true,
                label: t.catalog.a11y.prepareButton(nom: nom),
                // SW-SKIN-L3e : FilledButton.icon -> AppButton primary (arbitrage
                // #A5), pleine largeur (SizedBox width infinity conserve).
                child: AppButton(
                  key: ValueKey('catalog-enter-${trail.id}'),
                  icon: avecPub
                      ? StepwaysIcons.panneau
                      : StepwaysIcons.programme,
                  label: t.catalog.prepare,
                  onPressed: onEnter,
                ),
              ),
            ),
          ),
          if (achetable) ...[
            const SizedBox(height: AppTheme.spacingSm),
            // GRISE EN DEMO (tache 638, bug 14) : le refus d'achat en demo
            // existait deja cote service (`refuseEnDemo`), mais le bouton avait
            // l'air actif. Il est desormais visiblement indisponible.
            //
            // INTEGRATION 647 — l enveloppe vient de 638, le panier et le libelle
            // d accessibilite viennent de 639. Rien n est abandonne.
            GriseEnDemo(
              child: SizedBox(
                width: double.infinity,
                child: Semantics(
                  button: true,
                  label: t.catalog.a11y.buyButton(nom: nom),
                  child: AppButton(
                    key: ValueKey('catalog-buy-${trail.id}'),
                    variant: AppButtonVariant.outline,
                    icon: StepwaysIcons.panier,
                    label: t.monetization.buyCtaWithPrice(
                      price: monetisation
                          .eurPriceForTrail(trail.id)
                          .toStringAsFixed(2),
                    ),
                    onPressed: () => buyTrail(context, ref, trailId: trail.id),
                  ),
                ),
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
