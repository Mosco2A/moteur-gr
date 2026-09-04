import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/poi.dart';
import '../../../../core/models/stage_duration.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/ui/error_view.dart';
import '../../../../core/ui/loading_view.dart';
import '../../../../i18n/translations.g.dart';
import '../../../../shared/widgets/app_data_stat.dart';
import '../../../../shared/widgets/app_gradient_header.dart';
import '../../../../shared/widgets/brand_alti_motif.dart';
import '../../../poi/domain/poi_type_config.dart';
import '../../../trail/providers/pois_provider.dart';
import '../../../trail/providers/stages_provider.dart';
import '../../domain/models/stage.dart';

/// Types de POI consideres comme un HEBERGEMENT d'etape (parite GR20 bloc
/// « Hebergements »). Generique multi-sentiers : couvre les libelles du socle
/// donnees (`shelter`) et les synonymes du registre [PoiTypeConfig] (`refuge`,
/// `accommodation`, `campsite`). Aucune localite en dur.
const Set<String> _kAccommodationPoiTypes = {
  'shelter',
  'refuge',
  'accommodation',
  'campsite',
};

/// Provider qui charge une etape par son ID (stageNumber) dans un sentier.
///
/// Parametre : record (trailId, stageId) ou stageId = stageNumber.
/// Mappe le StageModel (core) vers le Stage (domain trek) avec i18n.
final stageByIdProvider =
    FutureProvider.family<Stage, ({String trailId, int stageId})>(
  (ref, params) async {
    final stages = await ref.watch(stagesProvider(params.trailId).future);
    final match =
        stages.where((s) => s.stageNumber == params.stageId).firstOrNull;

    if (match == null) {
      throw StateError('Etape ${params.stageId} introuvable');
    }

    return Stage(
      id: '${match.stageNumber}',
      nameFr: match.name,
      distance: match.distanceKm,
      elevationGain: match.elevationGainM,
      elevationLoss: match.elevationLossM,
      // Duree par etape (parite GR20 : la fiche affiche toujours une valeur,
      // jamais « -- »). Le mapping oubliait ce champ -> l'affichage retombait
      // sur 0s. On propage la duree EFFECTIVE de l'etape via
      // `stageDurationMinutes` (donnee du sentier `estimatedDurationMinutes` si
      // fournie, sinon estimation Naismith depuis distance + D+), convertie en
      // secondes pour le modele serialisable `Stage`.
      estimatedDurationSeconds: stageDurationMinutes(match) * 60,
      orderIndex: match.stageNumber,
      startLat: match.startLat,
      startLng: match.startLng,
      endLat: match.endLat,
      endLng: match.endLng,
      difficulty: match.difficulty,
      descriptionFr: match.description,
      // Noms depart/arrivee (parite GR20 : sous-ligne « Depart -> Arrivee »).
      // Donnee RICHE du sentier quand fournie ; vide sinon -> la fiche retombe
      // proprement sur le nom de l'etape (fallback, cf. _departureArrivalLine).
      departureName: match.departureName ?? '',
      arrivalName: match.arrivalName ?? '',
    );
  },
);

/// Ecran detail d'une etape de sentier.
///
/// Consumer widget utilisant AsyncValue.when() sur stageByIdProvider.
/// Affiche : nom i18n, description i18n, profil altimetrique (CustomPaint),
/// stats (distance, D+, D-, duree estimee, difficulte), puis les blocs de
/// PARITE GR20 alimentes par les DONNEES du sentier : points d'eau et
/// hebergements (POI de `poisProvider` filtres par etape/type) et conseils
/// (derives des stats de l'etape).
/// Utilise select() pour eviter un full rebuild.
class TrekStageDetailScreen extends ConsumerWidget {
  const TrekStageDetailScreen({
    super.key,
    required this.trailId,
    required this.stageId,
  });

  /// Identifiant du sentier parent.
  final String trailId;

  /// Numero de l'etape a afficher.
  final int stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stageAsync = ref.watch(
      stageByIdProvider((trailId: trailId, stageId: stageId)).select(
        (async) => async,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: Consumer(
          builder: (context, ref, _) {
            final name = ref.watch(
              stageByIdProvider((trailId: trailId, stageId: stageId)).select(
                (async) => async.value?.nameFr ?? 'Etape $stageId',
              ),
            );
            return Text(name);
          },
        ),
      ),
      body: stageAsync.when(
        loading: () => LoadingView(
          message: t.stage.loading,
        ),
        error: (error, _) => ErrorView(
          message: 'Impossible de charger cette etape',
          onRetry: () => ref.invalidate(
            stageByIdProvider((trailId: trailId, stageId: stageId)),
          ),
        ),
        data: (stage) => _StageDetailContent(stage: stage, trailId: trailId),
      ),
    );
  }
}

/// Contenu principal de l'ecran detail etape.
///
/// ConsumerWidget : au-dela du `Stage` (stats/profil), il observe
/// `poisProvider(trailId)` pour alimenter les blocs eau/hebergement a partir
/// des DONNEES du sentier (zero hardcode, generique multi-sentiers).
class _StageDetailContent extends ConsumerWidget {
  const _StageDetailContent({required this.stage, required this.trailId});

  final Stage stage;
  final String trailId;

  /// Retourne le nom de l'etape selon la locale courante.
  /// Fallback : nameFr si la traduction est vide.
  String _localizedName(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    switch (languageCode) {
      case 'en':
        return stage.nameEn.isNotEmpty ? stage.nameEn : stage.nameFr;
      case 'de':
        return stage.nameDe.isNotEmpty ? stage.nameDe : stage.nameFr;
      case 'it':
        return stage.nameIt.isNotEmpty ? stage.nameIt : stage.nameFr;
      case 'es':
        return stage.nameEs.isNotEmpty ? stage.nameEs : stage.nameFr;
      default:
        return stage.nameFr;
    }
  }

  /// Couple (depart, arrivee) a afficher sur la sous-ligne « Depart -> Arrivee »
  /// (parite GR20). Retourne `null` quand aucune donnee exploitable n'est
  /// disponible -> la sous-ligne est alors masquee (fallback propre).
  ///
  /// Priorite : (1) les noms RICHES du sentier (`departureName`/`arrivalName`)
  /// quand ils sont fournis ; (2) a defaut, on derive les deux extremites du
  /// NOM de l'etape lui-meme (convention socle « Depart — Arrivee », separateur
  /// tiret demi-cadratin ou trait d'union). Aucune localite codee en dur.
  ({String departure, String arrival})? _departureArrival() {
    final dep = stage.departureName.trim();
    final arr = stage.arrivalName.trim();
    if (dep.isNotEmpty && arr.isNotEmpty) {
      return (departure: dep, arrival: arr);
    }

    // Fallback : decouper le nom « Depart — Arrivee » (em-dash ou trait d'union
    // entoure d'espaces, pour ne pas casser un nom compose type « Guitera-les-
    // Bains »).
    final name = stage.nameFr.trim();
    final match = RegExp(r'\s+[—–-]\s+').firstMatch(name);
    if (match != null) {
      final left = name.substring(0, match.start).trim();
      final right = name.substring(match.end).trim();
      if (left.isNotEmpty && right.isNotEmpty) {
        return (departure: left, arrival: right);
      }
    }
    return null;
  }

  /// Retourne la description de l'etape selon la locale courante.
  /// Fallback : descriptionFr si la traduction est vide.
  String _localizedDescription(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    switch (languageCode) {
      case 'en':
        return stage.descriptionEn.isNotEmpty
            ? stage.descriptionEn
            : stage.descriptionFr;
      case 'de':
        return stage.descriptionDe.isNotEmpty
            ? stage.descriptionDe
            : stage.descriptionFr;
      case 'it':
        return stage.descriptionIt.isNotEmpty
            ? stage.descriptionIt
            : stage.descriptionFr;
      case 'es':
        return stage.descriptionEs.isNotEmpty
            ? stage.descriptionEs
            : stage.descriptionFr;
      default:
        return stage.descriptionFr;
    }
  }

  /// Formate la duree estimee en heures et minutes.
  String _formattedDuration() {
    final duration = stage.estimatedDuration;
    if (duration.inSeconds == 0) return "--";
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0 && minutes > 0) {
      return '${hours}h${minutes.toString().padLeft(2, "0")}';
    }
    if (hours > 0) return '${hours}h';
    return '${minutes}min';
  }

  /// Retourne le libelle de difficulte (i18n via l'enum, jamais de FR en dur).
  String _difficultyLabel() {
    switch (stage.difficulty) {
      case 'easy':
        return t.stage.difficulty.easy;
      case 'moderate':
        return t.stage.difficulty.moderate;
      case 'hard':
        return t.stage.difficulty.hard;
      case 'extreme':
        return t.stage.difficulty.extreme;
      default:
        return stage.difficulty;
    }
  }

  /// Retourne la couleur associee a la difficulte.
  Color _difficultyColor() {
    switch (stage.difficulty) {
      case 'easy':
        return AppTheme.vertFacile;
      case 'moderate':
        return AppTheme.jauneModere;
      case 'hard':
        return AppTheme.orangeDifficile;
      case 'extreme':
        return AppTheme.rougeExtreme;
      default:
        return AppTheme.grisGranite;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final name = _localizedName(context);
    final description = _localizedDescription(context);

    // POI du sentier -> on ne garde que ceux de CETTE etape (parite GR20 :
    // eau/hebergement listes par etape). `orderIndex` == stageNumber.
    // AsyncValue tolerant : liste vide tant que la donnee n'est pas prete
    // (pas de spinner bloquant, le corps de la fiche reste affiche).
    final stagePois = ref
            .watch(poisProvider(trailId))
            .value
            ?.where((p) => p.stageNumber == stage.orderIndex)
            .toList() ??
        const <PoiModel>[];
    final waterPois =
        stagePois.where((p) => p.type == 'water').toList(growable: false);
    final accommodationPois = stagePois
        .where((p) => _kAccommodationPoiTypes.contains(p.type))
        .toList(growable: false);

    return SingleChildScrollView(
      // SW-SKIN-L5 : l'en-tete a degrade est plein cadre (pas de padding lateral
      // pour le bandeau) ; le CORPS conserve le padding via un Padding interne.
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- En-tete a degrade d'accent (SW-SKIN-L5) ---
          // Remplace l'en-tete maison (CircleAvatar + nom + badge). Le numero
          // d'etape devient le `trailing` (pastille accent), le nom le titre.
          // Contraste texte garanti (§1.6). Le badge difficulte descend dans le
          // corps (chip semantique), comme la maquette CCO peau A.
          AppGradientHeader(
            title: name,
            trailing: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              foregroundColor: Colors.white,
              child: Text('${stage.orderIndex}'),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Badge difficulte (chip semantique, couleur denivele) ---
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingSm,
                    vertical: AppTheme.spacingXs,
                  ),
                  decoration: BoxDecoration(
                    color: _difficultyColor().withAlpha(50),
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                    border: Border.all(color: _difficultyColor()),
                  ),
                  child: Text(
                    _difficultyLabel(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: _difficultyColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // --- Sous-ligne « Depart -> Arrivee » (parite GR20) ---
                // Affichee uniquement si une donnee exploitable existe (noms du
                // sentier ou derivation du nom d'etape) ; masquee proprement
                // sinon. Icone + « Depart  ->  Arrivee » en gris (parite GR20
                // `_StageHeader`).
                if (_departureArrival() case final route?) ...[
                  const SizedBox(height: AppTheme.spacingSm),
                  _DepartureArrivalLine(
                    departure: route.departure,
                    arrival: route.arrival,
                  ),
                ],

                // --- Description i18n ---
                if (description.isNotEmpty) ...[
                  const SizedBox(height: AppTheme.spacingBase),
                  Text(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(200),
                    ),
                  ),
                ],

                const SizedBox(height: AppTheme.spacingLg),

                // --- Profil altimetrique ---
                Text(
                  t.stage.altitudeProfile,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                // Motif de profil altimetrique de marque (SW-SKIN-L6).
                // Ex-CustomPaint inline (_ElevationProfilePainter) factorise
                // vers BrandAltiMotif. Variante `hero` = degrade d'accent
                // (nouvelle identite assumee). Le modele Stage ne portant que
                // D+/D-/distance (pas de points reels), on emploie le
                // constructeur `.synthetic` -> parite de trace avec l'existant.
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  child: Container(
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: BrandAltiMotif.synthetic(
                      elevationGain: stage.elevationGain,
                      elevationLoss: stage.elevationLoss,
                      distance: stage.distance,
                    ),
                  ),
                ),

                const SizedBox(height: AppTheme.spacingLg),

                // --- Statistiques : rangee de gros chiffres data (SW-SKIN-L5) ---
                // Bloc plat (_StatRow) remplace par une rangee d'AppDataStat
                // (distance, D+, D-, duree) en role data tabular L1. La valeur
                // et l'unite sont separees (rendu tabular) ; la difficulte reste
                // le chip ci-dessus (couleur denivele, jamais un gros chiffre).
                Text(
                  t.stage.statistics,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppTheme.spacingSm),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: AppDataStat(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        label: t.stage.distance,
                        value: stage.distance.toStringAsFixed(1),
                        unit: 'km',
                      ),
                    ),
                    Expanded(
                      child: AppDataStat(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        label: t.stage.dPlus,
                        value: '+${stage.elevationGain}',
                        unit: 'm',
                      ),
                    ),
                    Expanded(
                      child: AppDataStat(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        label: t.stage.dMinus,
                        value: '-${stage.elevationLoss}',
                        unit: 'm',
                      ),
                    ),
                    Expanded(
                      child: AppDataStat(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        label: t.stage.duration,
                        value: _formattedDuration(),
                      ),
                    ),
                  ],
                ),

                // --- Points d'eau (parite GR20) — POI type `water` ---
                const SizedBox(height: AppTheme.spacingLg),
                _WaterSourcesSection(waterPois: waterPois),

                // --- Hebergements de l'etape (parite GR20) — POI hebergement ---
                const SizedBox(height: AppTheme.spacingLg),
                _AccommodationSection(accommodationPois: accommodationPois),

                // --- Conseils (parite GR20) — derives des stats de l'etape ---
                const SizedBox(height: AppTheme.spacingLg),
                _AdviceSection(
                  stage: stage,
                  waterSourcesCount: waterPois.length,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sous-ligne « Depart -> Arrivee » de la fiche etape (parite GR20
/// `_StageHeader`).
///
/// Icone de depart (accent du sentier, skin-aware) + « Depart  ->  Arrivee » en
/// gris secondaire. `Expanded` pour tronquer proprement les noms longs.
/// Un `Semantics` fournit un libelle accessible (i18n).
class _DepartureArrivalLine extends StatelessWidget {
  const _DepartureArrivalLine({
    required this.departure,
    required this.arrival,
  });

  final String departure;
  final String arrival;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: t.stage.departureArrival
          .replaceAll('{from}', departure)
          .replaceAll('{to}', arrival),
      child: Row(
        children: [
          Icon(
            Icons.play_arrow,
            size: 22,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: AppTheme.spacingXs),
          Expanded(
            child: Text(
              '$departure  →  $arrival',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.grisTexteSecondaire,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Section « Points d'eau » (parite GR20, bloc `_WaterSourcesSection`).
///
/// Alimentee par les POI de type `water` de l'etape (donnees du sentier). En
/// tete : titre + pastille du nombre de sources. Sans source : carte
/// d'avertissement (prevoir de l'eau). Sinon : liste des points d'eau.
class _WaterSourcesSection extends StatelessWidget {
  const _WaterSourcesSection({required this.waterPois});

  final List<PoiModel> waterPois;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final count = waterPois.length;
    // Couleur « eau » = source de verite du registre POI (generique, jamais un
    // hex en dur specifique a cette page).
    final waterColor = PoiTypeConfig.getStyle('water').color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.water_drop, size: 20, color: waterColor),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              t.stage.waterSources.title,
              style: theme.textTheme.titleMedium,
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: waterColor.withAlpha(30),
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              ),
              child: Text(
                // Placeholder litteral `{n}` remplace en Dart (convention du
                // projet : Slang ne fait pas d'interpolation, cf. `remaining`).
                t.stage.waterSources.count.replaceAll('{n}', '$count'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: waterColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),
        if (count == 0)
          Container(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            decoration: BoxDecoration(
              color: AppTheme.rougeUrgence.withAlpha(20),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              border: Border.all(color: AppTheme.rougeUrgence.withAlpha(60)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber,
                    size: 20, color: AppTheme.rougeUrgence),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    t.stage.waterSources.none,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppTheme.rougeUrgence,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...waterPois.map((poi) => _WaterPointTile(poi: poi)),
      ],
    );
  }
}

/// Tuile d'un point d'eau (parite GR20 `_WaterPointTile`).
class _WaterPointTile extends StatelessWidget {
  const _WaterPointTile({required this.poi});

  final PoiModel poi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final waterColor = PoiTypeConfig.getStyle('water').color;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Icon(Icons.water_drop_outlined,
                size: 20, color: waterColor),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  poi.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (poi.description.isNotEmpty)
                  Text(
                    poi.description,
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (poi.altitudeM > 0)
            Padding(
              padding: const EdgeInsets.only(left: AppTheme.spacingSm),
              child: Text(
                '${poi.altitudeM}m',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppTheme.grisTexteSecondaire,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Section « Hebergements » (parite GR20, bloc `_AccommodationSection`).
///
/// Alimentee par les POI d'hebergement de l'etape (`shelter`/`refuge`/...).
/// Sans hebergement : message neutre. Sinon : liste des hebergements typees.
class _AccommodationSection extends StatelessWidget {
  const _AccommodationSection({required this.accommodationPois});

  final List<PoiModel> accommodationPois;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.hotel, size: 20, color: AppTheme.orangeDifficile),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              t.stage.accommodation.title,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),
        if (accommodationPois.isEmpty)
          Text(
            t.stage.accommodation.none,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.grisTexteSecondaire,
            ),
          )
        else
          ...accommodationPois.map((poi) => _AccommodationTile(poi: poi)),
      ],
    );
  }
}

/// Tuile d'hebergement (parite GR20 `_AccommodationTile`).
///
/// Icone/couleur/label derives du type via [PoiTypeConfig] (generique, jamais
/// de mapping localite en dur).
class _AccommodationTile extends StatelessWidget {
  const _AccommodationTile({required this.poi});

  final PoiModel poi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = PoiTypeConfig.getStyle(poi.type);
    final color = style.color;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: color.withAlpha(50)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(style.icon, size: 32, color: color),
          const SizedBox(width: AppTheme.spacingMd),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        poi.name,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.spacingSm,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withAlpha(120),
                        borderRadius:
                            BorderRadius.circular(AppTheme.radiusChip),
                        border: Border.all(color: color),
                      ),
                      child: Text(
                        style.labelKey,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (poi.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    poi.description,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Section « Conseils » (parite GR20, bloc `_AdviceSection`).
///
/// Conseils DERIVES des stats de l'etape (comme GR20 `_getAdviceForStage`) :
/// nombre de points d'eau, difficulte, D+, et position dans le trek. Generique
/// et calcule : aucun texte code en dur par localite.
class _AdviceSection extends StatelessWidget {
  const _AdviceSection({
    required this.stage,
    required this.waterSourcesCount,
  });

  final Stage stage;
  final int waterSourcesCount;

  /// Conseils contextuels calcules a partir des donnees de l'etape.
  List<String> _adviceForStage() {
    final tips = <String>[];

    // Conseil eau (parite GR20 : selon le nombre de points d'eau).
    if (waterSourcesCount <= 1) {
      tips.add(t.stage.advice.waterScarce);
    } else {
      tips.add(t.stage.advice.waterAmple);
    }

    // Conseil difficulte.
    if (stage.difficulty == 'hard' || stage.difficulty == 'extreme') {
      tips.add(t.stage.advice.hardStage);
    } else {
      tips.add(t.stage.advice.earlyStart);
    }

    // Conseil D+.
    if (stage.elevationGain > 1000) {
      tips.add(t.stage.advice.bigClimb);
    }

    return tips;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final advice = _adviceForStage();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.lightbulb_outline,
                size: 20, color: AppTheme.jauneModere),
            const SizedBox(width: AppTheme.spacingSm),
            Text(
              t.stage.advice.title,
              style: theme.textTheme.titleMedium,
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Container(
          padding: const EdgeInsets.all(AppTheme.spacingBase),
          decoration: BoxDecoration(
            color: AppTheme.jauneModere.withAlpha(15),
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: AppTheme.jauneModere.withAlpha(40)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: advice.map((tip) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Icon(Icons.circle,
                          size: 6, color: AppTheme.jauneModere),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Text(
                        tip,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

// Le profil altimetrique (ex-`_ElevationProfilePainter` inline) est desormais
// factorise dans `BrandAltiMotif` (lib/shared/widgets/brand_alti_motif.dart,
// SW-SKIN-L6). La fiche etape emploie `BrandAltiMotif.synthetic` -> parite de
// trace, plus le degrade d'accent (identite assumee).
