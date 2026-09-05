import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../domain/shop_info.dart';
import '../providers/shop_providers.dart';

/// Ecran RAVITAILLEMENT (parite GR20 `ShopDetailScreen`, data-driven — regle
/// « donnees en externe » de Christophe #99460).
///
/// Clone strict de l'ecran GR20 (« Ravitaillement » : commerces & services par
/// etape) :
///   * AppBar « Ravitaillement » + back ;
///   * rangee de filtres horizontaux (« Tous » + 4 types) — puce selectionnee =
///     bordure coloree ([shopTypeFilterProvider]) ;
///   * bandeau d'alerte « ravitaillement limite » — DATA-DRIVEN : le texte vient
///     de la donnee du sentier ([TrailShops.limitedSupplyNote]) ; masque si
///     absent (aucun « 8 points sur 180 km » en dur) ;
///   * liste des commerces groupee/ordonnee par ETAPE, chaque carte = en-tete
///     (icone type + nom + badge etape + horaires) + apercu produits (4 max) +
///     alerte « gap » optionnelle ;
///   * bottom sheet detail (Informations : type, etape, GPS, horaires ; Alerte
///     si gap ; Produits disponibles complets).
///
/// Le CONTENU vient du catalogue ravitaillement du sentier ([trailShopsProvider])
/// — PAS de `const gr20Shops` hardcode par localite. Le moteur reste GENERIQUE
/// multi-sentiers (#84627), zero hardcode de localite ni de « GR20 ». Fallback
/// gracieux : sentier sans donnees -> ecran informatif propre (pas de crash).
/// Hors peau : couleurs semantiques d'AppTheme (+ `scheme.secondary` pour le
/// type « gaz », StepWays n'ayant pas de token bleu fige). Tout libelle
/// d'INTERFACE passe par Slang (`t.shop.*`, 5 langues) ; les donnees propres au
/// sentier restent dans la langue de la donnee.
class ShopScreen extends ConsumerWidget {
  const ShopScreen({super.key, required this.trailId});

  /// Identifiant du sentier courant (donnees ravitaillement par sentier).
  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final data = ref.watch(trailShopsProvider(trailId));
    final typeFilter = ref.watch(shopTypeFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(t.shop.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: t.a11y.back,
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
      ),
      // Fallback gracieux : aucune donnee ravitaillement pour ce sentier.
      body: (data == null || !data.hasShops)
          ? const _ShopEmptyState()
          : _ShopBody(data: data, typeFilter: typeFilter, theme: theme),
    );
  }
}

/// Corps de l'ecran quand des donnees existent (parite GR20 : filtres + alerte +
/// liste groupee par etape).
class _ShopBody extends ConsumerWidget {
  const _ShopBody({
    required this.data,
    required this.typeFilter,
    required this.theme,
  });

  final TrailShops data;
  final ShopKind? typeFilter;
  final ThemeData theme;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Filtrage par type (parite GR20). La liste reste triee par etape.
    final filtered = typeFilter == null
        ? data.shops
        : data.shops.where((s) => s.type == typeFilter).toList();

    // Regroupement/ordre par ETAPE (amelioration data-driven vs GR20 qui laisse
    // l'ordre du const) : etapes croissantes, commerces de chaque etape ensemble.
    final stagesOrdered =
        filtered.map((s) => s.stageNumber).toSet().toList()..sort();

    return Column(
      children: [
        // Filtres horizontaux (parite GR20 `_buildFilters`).
        _ShopFilters(theme: theme, typeFilter: typeFilter),

        // Alerte « ravitaillement limite » DATA-DRIVEN (masquee si pas de note).
        if (data.hasLimitedSupplyNote)
          _SupplyAlertBanner(note: data.limitedSupplyNote, theme: theme),

        // Liste groupee par etape (parite GR20 `ListView` de cartes).
        Expanded(
          child: filtered.isEmpty
              // Filtre actif sans resultat : etat vide leger (pas un crash).
              ? _ShopFilterEmpty(theme: theme)
              : ListView.builder(
                  padding: const EdgeInsets.all(AppTheme.spacingBase),
                  itemCount: stagesOrdered.length,
                  itemBuilder: (context, index) {
                    final stageNumber = stagesOrdered[index];
                    final stageShops = filtered
                        .where((s) => s.stageNumber == stageNumber)
                        .toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // En-tete d'etape (regroupement visuel data-driven).
                        Padding(
                          padding: const EdgeInsets.only(
                            top: AppTheme.spacingSm,
                            bottom: AppTheme.spacingSm,
                          ),
                          child: Text(
                            t(context).shop.stageHeader(n: stageNumber),
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppTheme.vertFacile,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        for (final shop in stageShops)
                          Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppTheme.spacingSm,
                            ),
                            child: _ShopCard(shop: shop, data: data),
                          ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  // Petit acces au Translations local (evite de repasser `t` a chaque widget).
  Translations t(BuildContext context) => Translations.of(context);
}

/// Rangee de filtres horizontaux (parite GR20 `_buildFilters` : « Tous » +
/// 4 types, puce selectionnee = bordure coloree).
class _ShopFilters extends ConsumerWidget {
  const _ShopFilters({required this.theme, required this.typeFilter});

  final ThemeData theme;
  final ShopKind? typeFilter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacingSm),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(bottom: BorderSide(color: theme.dividerColor)),
      ),
      child: SizedBox(
        height: 56,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.spacingMd),
          child: Row(
            children: [
              _ShopFilterChip(
                label: t.shop.filterAll,
                icon: Icons.store,
                selected: typeFilter == null,
                color: theme.colorScheme.secondary,
                onSelected: () =>
                    ref.read(shopTypeFilterProvider.notifier).state = null,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              for (final type in ShopKind.values) ...[
                _ShopFilterChip(
                  label: _shopTypeLabel(t, type),
                  icon: _shopTypeIcon(type),
                  selected: typeFilter == type,
                  color: _shopTypeColor(type, theme.colorScheme),
                  onSelected: () => ref
                          .read(shopTypeFilterProvider.notifier)
                          .state =
                      typeFilter == type ? null : type,
                ),
                const SizedBox(width: AppTheme.spacingSm),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Puce de filtre (parite GR20 `_buildFilterChip`). Bordure coloree quand
/// selectionnee. Semantics bouton pour l'a11y.
class _ShopFilterChip extends StatelessWidget {
  const _ShopFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.color,
    required this.onSelected,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final Color color;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: FilterChip(
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: color.withAlpha(40),
        side: BorderSide(
          color: selected ? color : Theme.of(context).dividerColor,
          width: selected ? 2 : 1,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }
}

/// Bandeau d'alerte « ravitaillement limite » (parite GR20 `_buildSupplyAlert`),
/// mais DATA-DRIVEN : le texte vient de la donnee du sentier ([note]).
class _SupplyAlertBanner extends StatelessWidget {
  const _SupplyAlertBanner({required this.note, required this.theme});

  final String note;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.spacingBase,
        AppTheme.spacingMd,
        AppTheme.spacingBase,
        0,
      ),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: AppTheme.orangeDifficile.withAlpha(20),
        border: Border.all(color: AppTheme.orangeDifficile.withAlpha(80)),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber,
              color: AppTheme.orangeDifficile, size: 20),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.shop.limitedTitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.orangeDifficile,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  note,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppTheme.orangeDifficile,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte d'un commerce (parite GR20 `_buildShopCard`). En-tete (icone type + nom
/// + badge etape + horaires), apercu produits (4 max), alerte « gap » optionnelle.
/// Tap -> bottom sheet detail.
class _ShopCard extends StatelessWidget {
  const _ShopCard({required this.shop, required this.data});

  final Shop shop;
  final TrailShops data;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final typeColor = _shopTypeColor(shop.type, scheme);

    // Gap de ravitaillement (parite GR20 : ecart au prochain commerce).
    final gap = data.gapAfter(shop.stageNumber);
    final gapAlert = data.isGapAlert(shop.stageNumber);

    return Semantics(
      button: true,
      label: t.shop.a11y.openDetail(name: shop.name),
      child: AppCard(
        onTap: () => _showShopDetail(context, theme, shop, gap, gapAlert),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tete.
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSm),
                  decoration: BoxDecoration(
                    color: typeColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  ),
                  child: Icon(_shopTypeIcon(shop.type),
                      color: typeColor, size: 22),
                ),
                const SizedBox(width: AppTheme.spacingMd),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        shop.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                              color: AppTheme.vertFacile.withAlpha(40),
                              borderRadius:
                                  BorderRadius.circular(AppTheme.radiusChip),
                            ),
                            child: Text(
                              t.shop.stageBadge(n: shop.stageNumber),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: AppTheme.vertFacile,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (shop.openingHours.isNotEmpty) ...[
                            const SizedBox(width: AppTheme.spacingSm),
                            Icon(Icons.access_time,
                                size: 14,
                                color: AppTheme.grisGranite.withAlpha(180)),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                shop.openingHours,
                                style: theme.textTheme.bodySmall
                                    ?.copyWith(fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Apercu produits (4 premiers, parite GR20).
            if (shop.hasProducts) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Wrap(
                spacing: AppTheme.spacingSm,
                runSpacing: AppTheme.spacingXs,
                children: shop.products.take(4).map((product) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                    ),
                    child: Text(
                      product,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  );
                }).toList(),
              ),
            ],

            // Alerte gap (parite GR20 : bandeau rouge si ecart > seuil).
            if (gapAlert) ...[
              const SizedBox(height: AppTheme.spacingSm),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm, vertical: AppTheme.spacingXs),
                decoration: BoxDecoration(
                  color: AppTheme.rougeUrgence.withAlpha(15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.warning_amber,
                        size: 14, color: AppTheme.rougeUrgence),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        t.shop.gapShort(n: gap),
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppTheme.rougeUrgence,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet detail commerce (parite GR20 `_showShopDetail`).
void _showShopDetail(
  BuildContext context,
  ThemeData theme,
  Shop shop,
  int gap,
  bool gapAlert,
) {
  final t = Translations.of(context);
  final scheme = theme.colorScheme;
  final typeColor = _shopTypeColor(shop.type, scheme);

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(AppTheme.radiusBottomSheet)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (context, scrollController) {
          return SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Titre + icone type.
                Row(
                  children: [
                    Icon(_shopTypeIcon(shop.type), color: typeColor, size: 28),
                    const SizedBox(width: AppTheme.spacingMd),
                    Expanded(
                      child: Text(shop.name,
                          style: theme.textTheme.headlineSmall),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.spacingLg),

                // Informations (parite GR20 : Type, Etape, GPS, Horaires).
                SectionHeader(
                    title: t.shop.sectionInfo, icon: Icons.info_outline),
                const SizedBox(height: AppTheme.spacingSm),
                _DetailRow(
                    icon: Icons.category,
                    label: t.shop.fieldType,
                    value: _shopTypeLabel(t, shop.type)),
                _DetailRow(
                    icon: Icons.map,
                    label: t.shop.fieldStage,
                    value: t.shop.stageBadge(n: shop.stageNumber)),
                // GPS masque si non verifie (honnetete #99460 : pas de 0,0 faux).
                if (shop.hasCoordinates)
                  _DetailRow(
                    icon: Icons.gps_fixed,
                    label: t.shop.fieldGps,
                    value:
                        '${shop.latitude!.toStringAsFixed(4)}, ${shop.longitude!.toStringAsFixed(4)}',
                  ),
                if (shop.openingHours.isNotEmpty)
                  _DetailRow(
                      icon: Icons.access_time,
                      label: t.shop.fieldHours,
                      value: shop.openingHours),

                // Contact / site (extension StepWays, cables url_launcher).
                if (shop.hasPhone || shop.hasWebsite) ...[
                  const SizedBox(height: AppTheme.spacingSm),
                  Row(
                    children: [
                      if (shop.hasPhone)
                        Expanded(
                          child: Semantics(
                            button: true,
                            label: t.shop.a11y.call(label: shop.name),
                            child: InkWell(
                              onTap: () => _call(shop.phone),
                              child: Row(
                                children: [
                                  Icon(Icons.phone,
                                      size: 18, color: scheme.secondary),
                                  const SizedBox(width: 6),
                                  Text(
                                    shop.phone,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: scheme.secondary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      if (shop.hasWebsite)
                        Semantics(
                          button: true,
                          label: t.shop.a11y.website,
                          child: IconButton(
                            icon: Icon(Icons.open_in_new,
                                size: 18, color: scheme.secondary),
                            tooltip: t.shop.website,
                            onPressed: () => _openUrl(shop.website!),
                          ),
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: AppTheme.spacingLg),

                // Alerte gap (parite GR20 : bloc rouge si ecart > seuil).
                if (gapAlert) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(AppTheme.spacingMd),
                    decoration: BoxDecoration(
                      color: AppTheme.rougeUrgence.withAlpha(20),
                      border:
                          Border.all(color: AppTheme.rougeUrgence.withAlpha(100)),
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning,
                            color: AppTheme.rougeUrgence, size: 20),
                        const SizedBox(width: AppTheme.spacingSm),
                        Expanded(
                          child: Text(
                            t.shop.gapLong(n: gap),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.rougeUrgence,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                ],

                // Produits disponibles (liste complete, parite GR20).
                if (shop.hasProducts) ...[
                  SectionHeader(
                      title: t.shop.sectionProducts,
                      icon: Icons.shopping_basket),
                  const SizedBox(height: AppTheme.spacingSm),
                  for (final product in shop.products)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 16, color: scheme.secondary),
                          const SizedBox(width: AppTheme.spacingMd),
                          Expanded(
                            child: Text(product,
                                style: theme.textTheme.bodyMedium),
                          ),
                        ],
                      ),
                    ),
                ],
                const SizedBox(height: AppTheme.spacingBase),
              ],
            ),
          );
        },
      );
    },
  );
}

/// Ligne d'information du bottom sheet (parite GR20 `_buildDetailRow`).
class _DetailRow extends StatelessWidget {
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.grisGranite),
          const SizedBox(width: AppTheme.spacingMd),
          SizedBox(
            width: 70,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}

/// Etat vide leger quand un filtre ne renvoie aucun commerce (pas un crash,
/// parite « ecran informatif propre »).
class _ShopFilterEmpty extends StatelessWidget {
  const _ShopFilterEmpty({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Text(
          t.shop.filterEmpty,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: AppTheme.grisGranite),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

/// Etat informatif quand aucune donnee ravitaillement n'est disponible pour le
/// sentier (fallback gracieux — parite « ecran informatif propre », pas de crash).
class _ShopEmptyState extends StatelessWidget {
  const _ShopEmptyState();

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 72, color: AppTheme.grisGranite.withAlpha(80)),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              t.shop.empty.title,
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: AppTheme.grisGranite),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              t.shop.empty.message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppTheme.grisGranite.withAlpha(180)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// --- Helpers (le domaine ne connait pas Material) ---------------------------

Future<void> _call(String phone) async {
  final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri);
  }
}

Future<void> _openUrl(String urlStr) async {
  final uri = Uri.parse(urlStr);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

/// Icone Material pour un type de commerce (parite GR20 `_typeIcon`).
IconData _shopTypeIcon(ShopKind type) {
  switch (type) {
    case ShopKind.epicerie:
      return Icons.shopping_cart;
    case ShopKind.bar:
      return Icons.restaurant;
    case ShopKind.pharmacie:
      return Icons.local_pharmacy;
    case ShopKind.gaz:
      return Icons.propane_tank;
  }
}

/// Libelle traduit pour un type de commerce (parite GR20 `_typeLabel`, mais i18n).
String _shopTypeLabel(Translations t, ShopKind type) {
  switch (type) {
    case ShopKind.epicerie:
      return t.shop.typeEpicerie;
    case ShopKind.bar:
      return t.shop.typeBar;
    case ShopKind.pharmacie:
      return t.shop.typePharmacie;
    case ShopKind.gaz:
      return t.shop.typeGaz;
  }
}

/// Couleur semantique d'un type (parite esprit GR20 `_typeColor`). Hors peau :
/// tokens semantiques stables d'AppTheme, sauf le type « gaz » (bleu chez GR20)
/// qui suit la couleur secondaire de la peau active ([scheme.secondary]),
/// StepWays n'ayant pas de token bleu fige.
Color _shopTypeColor(ShopKind type, ColorScheme scheme) {
  switch (type) {
    case ShopKind.epicerie:
      return AppTheme.vertFacile;
    case ShopKind.bar:
      return AppTheme.orangeDifficile;
    case ShopKind.pharmacie:
      return AppTheme.rougeUrgence;
    case ShopKind.gaz:
      return scheme.secondary;
  }
}
