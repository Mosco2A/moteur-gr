/// Le defilement des fiches conseil, filtrees par categorie et triees par
/// priorite decroissante.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/couleurs_semantiques.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/mesure_de_texte.dart';
import '../data/tip_card_repository.dart';
import '../data/tip_category_config.dart';
import '../../../domain/tip_card.dart';
import 'tip_detail_sheet.dart';
import 'tip_points_list.dart';
import '../../../core/branding/stepways_icons.dart';

/// Provider des fiches conseil filtrees par categorie.
///
/// null = toutes categories. Sinon filtre par la categorie selectionnee.
/// Tri par priorite decroissante (via TipCardRepository).
final tipCategoryFilterProvider = StateProvider<String?>((ref) => null);

/// Provider de la liste de fiches conseil filtrees.
///
/// Combine le filtre categorie avec le repository pour retourner
/// les fiches pertinentes triees par priorite.
final filteredTipCardsProvider = Provider<List<TipCard>>((ref) {
  final category = ref.watch(tipCategoryFilterProvider);
  final repo = ref.watch(tipCardRepositoryProvider);
  if (category == null) {
    return repo.filterCards();
  }
  return repo.filterByCategory(category);
});

/// Provider du repository de fiches conseil.
///
/// A surcharger dans l arbre widget avec les donnees chargees
/// depuis les fichiers JSON (assets/tips/*.json).
final tipCardRepositoryProvider = Provider<TipCardRepository>((ref) {
  return TipCardRepository(allCards: const []);
});

/// Carrousel swipeable de fiches conseil avec filtrage par categorie.
///
/// Affiche un PageView.builder horizontal avec les fiches pertinentes.
/// Les chips en haut permettent de filtrer par categorie dynamiquement.
/// Tap sur une fiche ouvre le bottom sheet de detail.
class TipCarousel extends ConsumerWidget {
  const TipCarousel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(filteredTipCardsProvider);
    final selectedCategory = ref.watch(tipCategoryFilterProvider);
    final repo = ref.watch(tipCardRepositoryProvider);
    final categories = repo.availableCategories.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CategoryChips(
          categories: categories,
          selectedCategory: selectedCategory,
          onCategorySelected: (cat) {
            ref.read(tipCategoryFilterProvider.notifier).state = cat;
          },
        ),
        const SizedBox(height: AppTheme.spacingMd),
        if (cards.isEmpty) const _EmptyState() else _CarouselView(cards: cards),
      ],
    );
  }
}

/// Chips filtrables par categorie avec couleurs dynamiques.
///
/// Affiche un chip par categorie presente dans les donnees.
/// La categorie selectionnee est mise en surbrillance.
class _CategoryChips extends StatelessWidget {
  const _CategoryChips({
    required this.categories,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingBase),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: AppTheme.spacingSm),
            child: FilterChip(
              // « Toutes » etait ecrit en dur en francais alors que
              // `t.tips.allCategories` porte le mot dans les cinq langues
              // (tache 557, meme famille de defaut que les intitules du
              // detail).
              label: Text(t.tips.allCategories),
              selected: selectedCategory == null,
              onSelected: (_) => onCategorySelected(null),
              selectedColor: theme.colorScheme.primary.withAlpha(50),
              checkmarkColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              ),
            ),
          ),
          ...categories.map((cat) {
            final meta = TipCategoryConfig.getConfig(cat);
            final color = categoryColor(cat, theme);
            return Padding(
              padding: const EdgeInsets.only(right: AppTheme.spacingSm),
              child: FilterChip(
                avatar: StepIcon(
                  resolveIcon(meta.icon),
                  size: 16,
                  color: selectedCategory == cat
                      ? color
                      : theme.colorScheme.onSurface.withAlpha(150),
                ),
                label: Text(meta.labelKey),
                selected: selectedCategory == cat,
                onSelected: (_) =>
                    onCategorySelected(selectedCategory == cat ? null : cat),
                selectedColor: color.withAlpha(40),
                checkmarkColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// HAUTEUR DU CARROUSEL, MESUREE SUR LE TITRE LE PLUS LONG (tache 749).
///
/// Part de la hauteur d'origine ([_hauteurPlancherDuCarrousel]) et y ajoute ce
/// que le titre le plus exigeant reclame AU-DELA d'une premiere ligne. Une
/// fiche dont le titre tient sur une ligne ne change rien ; un titre de trois
/// lignes fait grandir le carrousel de deux lignes, au lieu d'etre coupe.
double _hauteurDuCarrousel(
  BuildContext context, {
  required List<TipCard> cards,
}) {
  final theme = Theme.of(context);
  final styleTitre = theme.textTheme.titleMedium;
  if (styleTitre == null || cards.isEmpty) {
    return _hauteurPlancherDuCarrousel;
  }

  final media = MediaQuery.of(context);
  // Largeur offerte au titre : la fiche occupe 85 % de la fenetre
  // (`viewportFraction`), moins ses marges et son padding interne.
  final largeurTexte =
      media.size.width * _fractionDeFenetreDUneFiche -
      AppTheme.spacingSm * 2 -
      AppTheme.spacingMd * 2;
  if (largeurTexte <= 0) return _hauteurPlancherDuCarrousel;

  final echelle = media.textScaler;
  final hauteurDUneLigne = hauteurDesTextes(
    blocs: [(texte: 'M', style: styleTitre, maxLignes: 1)],
    largeurTexte: largeurTexte,
    echelle: echelle,
    direction: Directionality.of(context),
  );

  var supplement = 0.0;
  for (final card in cards) {
    final hauteurDuTitre = hauteurDesTextes(
      blocs: [(texte: card.localizedTitle, style: styleTitre, maxLignes: null)],
      largeurTexte: largeurTexte,
      echelle: echelle,
      direction: Directionality.of(context),
    );
    final delta = hauteurDuTitre - hauteurDUneLigne;
    if (delta > supplement) supplement = delta;
  }
  return _hauteurPlancherDuCarrousel + supplement + margeDArrondiDuPeintre;
}

/// Hauteur du carrousel d'avant le lot 749 — devenue son plancher.
const double _hauteurPlancherDuCarrousel = 220;

/// Part de la largeur de fenetre qu'occupe une fiche (`viewportFraction`).
const double _fractionDeFenetreDUneFiche = 0.85;

/// Vue carrousel PageView.builder swipeable.
///
/// Affiche les fiches conseil en pages horizontales.
/// Tap sur une carte ouvre le bottom sheet de detail.
class _CarouselView extends StatelessWidget {
  const _CarouselView({required this.cards});

  final List<TipCard> cards;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // LE CARROUSEL GRANDIT AVEC LE TITRE LE PLUS LONG (tache 749).
    //
    // La boite faisait 220 px quoi qu'il arrive, et le titre de fiche etait
    // donc coupe a deux lignes pour y tenir. Un carrousel horizontal a besoin
    // d'une hauteur COMMUNE a toutes ses fiches — c'est l'un des rares
    // endroits ou une hauteur unique se justifie vraiment — mais cette hauteur
    // peut etre MESUREE sur le titre le plus exigeant au lieu d'etre ecrite a
    // la main. 220 px reste le plancher : une fiche a titre court est au pixel
    // identique a ce qu'elle etait.
    return SizedBox(
      height: _hauteurDuCarrousel(context, cards: cards),
      child: PageView.builder(
        controller: PageController(viewportFraction: 0.85),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          final meta = TipCategoryConfig.getConfig(card.category);
          final color = categoryColor(card.category, theme);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingSm),
            child: GestureDetector(
              onTap: () => TipDetailSheet.show(context, card),
              // SW-SKIN-L3e : Card -> AppCard. Le liseré colore de CATEGORIE
              // (1.5px) est porte par borderColor/borderWidth ; padding base
              // porte par AppCard (iso-rendu). Le GestureDetector est conserve
              // au-dessus (tap sans encre, comportement inchange).
              child: AppCard(
                borderColor: color.withAlpha(80),
                borderWidth: 1.5,
                padding: const EdgeInsets.all(AppTheme.spacingBase),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StepIcon(
                          resolveIcon(meta.icon),
                          color: color,
                          size: 20,
                        ),
                        const SizedBox(width: AppTheme.spacingSm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingSm,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: color.withAlpha(30),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusChip,
                            ),
                          ),
                          child: Text(
                            card.category,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (card.priority >= 8)
                          const StepIcon(
                            StepwaysIcons.danger,
                            color: AppTheme.emergencyRed,
                            size: 18,
                          ),
                      ],
                    ),
                    const SizedBox(height: AppTheme.spacingMd),
                    // Titre ECRIT EN ENTIER (tache 749) : il etait coupe a
                    // deux lignes, et c'est le carrousel qui grandit
                    // desormais (voir [_hauteurDuCarrousel]).
                    Text(
                      card.localizedTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTheme.spacingSm),
                    // APERCU : les deux premiers points de la fiche (calibre
                    // 555). Le detail complet ouvre les cinq points.
                    //
                    // TACHE 749 — CE BLOC DEFILE VRAIMENT MAINTENANT. Il
                    // portait `NeverScrollableScrollPhysics` : la zone etait
                    // donc un COUPOIR SILENCIEUX, qui rognait la fin du
                    // deuxieme point sans points de suspension et sans aucun
                    // geste pour aller voir la suite. Montrer DEUX points sur
                    // cinq est un choix de produit assume (calibre 555) et il
                    // ne change pas ; couper le deuxieme au milieu d'une
                    // phrase n'en etait pas un.
                    Expanded(
                      child: SingleChildScrollView(
                        child: TipPointsList.fromCard(
                          card: card,
                          maxPoints: 2,
                          bulletColor: color,
                          textStyle: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(180),
                          ),
                        ),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: StepIcon(
                        StepwaysIcons.geste,
                        size: 16,
                        color: theme.colorScheme.onSurface.withAlpha(100),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Etat vide quand aucune fiche ne correspond au filtre.
class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            StepIcon(
              StepwaysIcons.ficheConseil,
              size: 48,
              color: theme.colorScheme.onSurface.withAlpha(100),
            ),
            const SizedBox(height: AppTheme.spacingMd),
            Text(
              t.tips.noTips,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(150),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Fonctions utilitaires partagees (carousel + detail) ---

/// Couleur par categorie (coherente entre chips et cartes).
Color categoryColor(String category, ThemeData theme) {
  switch (category) {
    case "preparation":
      return CouleursSemantiques.conseilPreparation;
    case "equipment":
      return CouleursSemantiques.conseilEquipement;
    case "nutrition":
      return CouleursSemantiques.conseilNutrition;
    case "safety":
      return CouleursSemantiques.conseilSecurite;
    case "nature":
      return CouleursSemantiques.conseilNature;
    case "recovery":
      return CouleursSemantiques.conseilRecuperation;
    default:
      return theme.colorScheme.primary;
  }
}

/// Resout un nom d icone Material en IconData.
String resolveIcon(String iconName) {
  switch (iconName) {
    case "checklist":
      return StepwaysIcons.sacADos;
    case "backpack":
      return StepwaysIcons.sacADos;
    case "restaurant":
      return StepwaysIcons.restauration;
    case "health_and_safety":
      return StepwaysIcons.ficheMedicale;
    case "forest":
      return StepwaysIcons.foret;
    case "self_improvement":
      return StepwaysIcons.preparationPhysique;
    default:
      return StepwaysIcons.info;
  }
}
