import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../../core/models/poi.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../i18n/translations.g.dart';
import '../../../../map/widgets/poi_marker.dart';
import '../../../../poi/domain/poi_type_config.dart';
import '../../../../poi/domain/poi_type_label.dart';
import '../../../domain/models/stage.dart';
import '../marker_overlap.dart';
import 'stage_markers_layer.dart';

/// LA COUCHE UNIQUE DES REPERES DU SENTIER (tache 571).
///
/// Retour de Chris en testant l'appli, mot pour mot : « 14rando les numeros
/// d'etapes son caches par les refucge, il ne faut pas que les icones se
/// superposent ».
///
/// CE QUI CLOCHAIT, ET POURQUOI IL FALLAIT UNE SEULE COUCHE. L'ecran carte
/// posait DEUX couches de marqueurs : les numeros d'etape, puis les points
/// d'interet. La seconde etait peinte apres, donc AU-DESSUS, et l'icone de
/// couchage recouvrait le numero d'etape. Or une etape se TERMINE a un
/// hebergement et la suivante en REPART : les deux marqueurs sont au meme point
/// par construction, sur tout sentier de randonnee. Deux couches empilees ne
/// peuvent pas s'entendre sur un repere commun — chacune ignore ce que l'autre
/// dessine. D'ou cette couche unique, qui voit les deux familles de reperes et
/// decide UNE fois.
///
/// CE QU'ELLE FAIT :
///  * elle demande a [MarkerOverlap] quels reperes sont indistinguables au zoom
///    courant (critere GEOMETRIQUE : l'ecart en metres converti en pixels) ;
///  * un groupe d'un seul repere est dessine EXACTEMENT comme avant — disque
///    numerote pour une etape, icone de type pour un point d'interet, memes
///    tailles, memes taps. Aucune regression sur le cas courant ;
///  * un groupe de plusieurs reperes devient UN repere qui porte les deux
///    informations : le numero d'etape reste au centre et lisible, la nature du
///    lieu vient en pastille, et le tap ouvre une feuille qui donne l'etape ET
///    chaque lieu.
///
/// CE QU'ELLE NE FAIT PAS : deplacer un repere. Pas de decalage de trois pixels
/// pour faire semblant — un decalage ferait mentir la position et se reformerait
/// au zoom suivant. On fusionne, ou on separe.
///
/// CE QUI RESTE DEHORS, DELIBEREMENT : la position GPS du randonneur garde sa
/// couche et son marqueur propres. Elle ne designe pas un lieu du sentier mais
/// l'endroit ou se trouve la personne — la fondre dans un repere de lieu lui
/// ferait dire « tu es au refuge » quand elle dit « tu es a vingt metres du
/// refuge ». La carte de reference (GR20, `map_navigation_screen`) fait le meme
/// choix ; et elle n'affiche AUCUN marqueur de numero d'etape, ce qui explique
/// que le defaut n'existe pas chez elle et qu'il n'y avait aucune solution a y
/// copier.
class TrailMarkersLayer extends StatelessWidget {
  const TrailMarkersLayer({
    super.key,
    required this.stages,
    required this.pois,
    required this.zoom,
    this.onStageTap,
    this.onPoiTap,
    this.stageMarkerSize = 32.0,
    this.poiMarkerSize = 36.0,
    this.mergedMarkerSize = 48.0,
  });

  /// Etapes du sentier, dans l'ordre d'affichage (la couleur du disque depend
  /// de la place dans cette liste : depart vert, arrivee rouge).
  final List<Stage> stages;

  /// Points d'interet a afficher (deja filtres par le panneau Calques).
  final List<PoiModel> pois;

  /// Zoom auquel evaluer le recouvrement.
  ///
  /// L'appelant passe le PLUS PETIT zoom de la bande courante (cf.
  /// [MarkerOverlap.lowestZoomOfBand]) : la carte ne notifie le zoom qu'arrondi,
  /// et fusionner un peu tot vaut mieux que laisser deux icones se marcher
  /// dessus en attendant l'arrondi suivant.
  final double zoom;

  /// Tap sur un repere d'etape seul.
  final void Function(Stage stage)? onStageTap;

  /// Tap sur un repere de point d'interet seul.
  final void Function(PoiModel poi)? onPoiTap;

  /// Diametre du disque numerote d'une etape.
  final double stageMarkerSize;

  /// Diametre de l'icone d'un point d'interet.
  final double poiMarkerSize;

  /// Cote de la boite d'un repere FUSIONNE.
  ///
  /// Plus grande que les deux precedentes : elle doit loger le disque numerote
  /// ET ses pastilles. C'est aussi la taille retenue pour juger du
  /// recouvrement, afin que la garantie « aucun repere rendu n'en recouvre un
  /// autre » tienne meme pour deux reperes fusionnes voisins.
  final double mergedMarkerSize;

  @override
  Widget build(BuildContext context) {
    final candidates = <MapMarkerCandidate<TrailPinSubject>>[
      // LES ETAPES D'ABORD : l'ordre vaut priorite. Le numero d'etape est
      // l'information de reperage la plus utile de la carte — c'est lui qui
      // repond a « ou suis-je dans le parcours » — donc c'est lui qui donne sa
      // position et son visage au repere fusionne.
      for (var i = 0; i < stages.length; i++)
        MapMarkerCandidate<TrailPinSubject>(
          position: LatLng(stages[i].startLat, stages[i].startLng),
          diameterPx: mergedMarkerSize,
          data: StagePinSubject(
            stage: stages[i],
            color: stageMarkerColor(i, stages.length),
          ),
        ),
      for (final poi in pois)
        MapMarkerCandidate<TrailPinSubject>(
          position: LatLng(poi.lat, poi.lng),
          diameterPx: mergedMarkerSize,
          data: PoiPinSubject(poi),
        ),
    ];

    if (candidates.isEmpty) return const SizedBox.shrink();

    final groups = MarkerOverlap.groupByLocation<TrailPinSubject>(
      candidates,
      zoom: zoom,
    );

    return MarkerLayer(
      markers: [
        for (final group in groups) _marker(context, group),
      ],
    );
  }

  /// Construit le marqueur d'un groupe : repere seul ou repere fusionne.
  Marker _marker(BuildContext context, MapMarkerGroup<TrailPinSubject> group) {
    if (!group.isMerged) {
      final subject = group.anchor.data;
      return switch (subject) {
        StagePinSubject(:final stage, :final color) => Marker(
            point: group.position,
            width: stageMarkerSize,
            height: stageMarkerSize,
            child: Semantics(
              button: onStageTap != null,
              label: t.a11y.stageMarker(number: stage.orderIndex),
              child: GestureDetector(
                onTap: onStageTap == null ? null : () => onStageTap!(stage),
                child: ExcludeSemantics(
                  child: StageNumberCircle(
                    number: stage.orderIndex,
                    color: color,
                    size: stageMarkerSize,
                  ),
                ),
              ),
            ),
          ),
        PoiPinSubject(:final poi) => Marker(
            point: group.position,
            width: poiMarkerSize,
            height: poiMarkerSize,
            child: Semantics(
              button: true,
              label: t.a11y.poiMarker(name: poi.name),
              child: GestureDetector(
                onTap: onPoiTap == null ? null : () => onPoiTap!(poi),
                child: ExcludeSemantics(
                  child: PoiMarker(type: poi.type, size: poiMarkerSize),
                ),
              ),
            ),
          ),
      };
    }

    return Marker(
      point: group.position,
      width: mergedMarkerSize,
      height: mergedMarkerSize,
      child: Semantics(
        button: true,
        // L'ETIQUETTE VOCALE DIT TOUT LE GROUPE, pas seulement son visage : un
        // lecteur d'ecran ne voit pas la pastille. Les libelles existants sont
        // reutilises, aucun mot neuf a traduire.
        label: group.members.map(_memberLabel).join(', '),
        child: GestureDetector(
          onTap: () => showTrailPinSheet(context, group),
          child: ExcludeSemantics(
            child: _MergedPin(
              group: group,
              size: mergedMarkerSize,
              stageCircleSize: stageMarkerSize,
            ),
          ),
        ),
      ),
    );
  }

  static String _memberLabel(MapMarkerCandidate<TrailPinSubject> member) {
    return switch (member.data) {
      StagePinSubject(:final stage) =>
        t.a11y.stageMarker(number: stage.orderIndex),
      PoiPinSubject(:final poi) => t.a11y.poiMarker(name: poi.name),
    };
  }
}

/// CE QU'UN REPERE DE LA CARTE DESIGNE : une etape, ou un point d'interet.
///
/// Publique parce que la feuille ouverte au tap ([showTrailPinSheet]) en prend
/// un groupe en parametre, et qu'une API publique ne se decrit pas avec des
/// types caches.
/// Ce qu'un repere de la carte designe : une etape, ou un point d'interet.
sealed class TrailPinSubject {
  const TrailPinSubject();
}

/// Un depart d'etape, avec la couleur qu'il a dans le sentier.
final class StagePinSubject extends TrailPinSubject {
  const StagePinSubject({required this.stage, required this.color});

  final Stage stage;
  final Color color;
}

/// Un point d'interet du sentier.
final class PoiPinSubject extends TrailPinSubject {
  const PoiPinSubject(this.poi);

  final PoiModel poi;
}

/// LE REPERE FUSIONNE : un seul marqueur, deux informations.
///
/// COMPOSITION, et chaque choix repond a une contrainte :
///  * au CENTRE, le disque numerote de l'etape, a sa taille habituelle et pose
///    sur le point exact — le numero reste l'information principale, et il
///    reste lisible. Sans etape dans le groupe, c'est l'icone du lieu le plus
///    decisif qui prend le centre ;
///  * en BAS A DROITE, une pastille qui porte l'icone du lieu (couchage, eau,
///    commerce...) dans sa couleur de type. Elle est posee dans le coin, HORS
///    du disque : elle ne peut donc pas recouvrir le numero ;
///  * en HAUT A DROITE, un compteur, uniquement s'il reste des lieux au-dela du
///    premier. Le detail complet est dans la feuille ouverte au tap.
///
/// ORDRE DE PRIORITE DU LIEU MIS EN PASTILLE : le couchage d'abord, puis l'eau,
/// puis le reste. C'est l'ordre des decisions d'un randonneur, et il s'appuie
/// sur les ensembles deja definis dans [PoiTypeConfig] — pas sur une seconde
/// definition du mot « hebergement ».
class _MergedPin extends StatelessWidget {
  const _MergedPin({
    required this.group,
    required this.size,
    required this.stageCircleSize,
  });

  final MapMarkerGroup<TrailPinSubject> group;
  final double size;
  final double stageCircleSize;

  @override
  Widget build(BuildContext context) {
    final stage = _stageOf(group);
    final pois = _poisOf(group);
    final primary = pois.isEmpty ? null : pois.first;
    final extra = pois.length - (primary == null ? 0 : 1);

    final badgeSize = size * 0.42;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Le coeur du repere, CENTRE sur le point geographique.
          Center(
            child: stage != null
                ? StageNumberCircle(
                    number: stage.stage.orderIndex,
                    color: stage.color,
                    size: stageCircleSize,
                  )
                : PoiMarker(type: primary!.type, size: stageCircleSize),
          ),

          // La nature du lieu, en pastille dans le coin — jamais par-dessus le
          // numero.
          if (stage != null && primary != null)
            Positioned(
              right: 0,
              bottom: 0,
              child: _PinBadge(
                size: badgeSize,
                color: PoiMarker.colorFor(primary.type),
                child: Icon(
                  PoiMarker.iconFor(primary.type),
                  color: Colors.white,
                  size: badgeSize * 0.6,
                ),
              ),
            ),

          // Le nombre de lieux supplementaires reunis ici.
          if (extra > 0)
            Positioned(
              right: 0,
              top: 0,
              child: _PinBadge(
                size: badgeSize,
                color: AppTheme.grisTexteSecondaire,
                child: Text(
                  '+$extra',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: badgeSize * 0.45,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Petite pastille ronde posee dans un coin d'un repere fusionne.
class _PinBadge extends StatelessWidget {
  const _PinBadge({
    required this.size,
    required this.color,
    required this.child,
  });

  final double size;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: child,
    );
  }
}

/// L'etape du groupe, s'il y en a une (au plus une : deux departs d'etape
/// confondus n'existent pas sur un sentier lineaire).
StagePinSubject? _stageOf(MapMarkerGroup<TrailPinSubject> group) {
  for (final member in group.members) {
    final subject = member.data;
    if (subject is StagePinSubject) return subject;
  }
  return null;
}

/// Les points d'interet du groupe, RANGES PAR ORDRE DE DECISION : le couchage,
/// puis l'eau, puis le reste. Ordre stable a l'interieur de chaque famille.
List<PoiModel> _poisOf(MapMarkerGroup<TrailPinSubject> group) {
  final pois = <PoiModel>[
    for (final member in group.members)
      if (member.data case PoiPinSubject(:final poi)) poi,
  ];
  int rank(PoiModel poi) {
    if (PoiTypeConfig.accommodationTypes.contains(poi.type)) return 0;
    if (PoiTypeConfig.waterTypes.contains(poi.type)) return 1;
    return 2;
  }

  final indexed = [
    for (var i = 0; i < pois.length; i++) (i, pois[i]),
  ]..sort((a, b) {
    final byRank = rank(a.$2).compareTo(rank(b.$2));
    return byRank != 0 ? byRank : a.$1.compareTo(b.$1);
  });
  return [for (final entry in indexed) entry.$2];
}

/// LA FEUILLE DU REPERE FUSIONNE — le tap donne acces AUX DEUX informations.
///
/// Un repere qui porte une etape et un refuge doit ouvrir les deux, sinon la
/// fusion aurait fait disparaitre une information au lieu d'en sauver une. La
/// feuille montre donc, dans l'ordre : l'etape (numero, nom, distance, D+, D-)
/// puis CHAQUE lieu avec ce qu'on en sait (nature, altitude, description,
/// horaires) — les memes champs que la fiche d'un point d'interet seul, aucune
/// donnee perdue au passage.
Future<void> showTrailPinSheet(
  BuildContext context,
  MapMarkerGroup<TrailPinSubject> group,
) {
  final stage = _stageOf(group);
  final pois = _poisOf(group);

  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (ctx) {
      final theme = Theme.of(ctx);
      return SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppTheme.spacingBase,
              0,
              AppTheme.spacingBase,
              AppTheme.spacingLg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.place),
                    const SizedBox(width: AppTheme.spacingSm),
                    Expanded(
                      child: Text(
                        t.map.pinMergedTitle,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                if (stage != null) ...[
                  const Divider(height: AppTheme.spacingLg),
                  _StageBlock(subject: stage),
                ],
                for (final poi in pois) ...[
                  const Divider(height: AppTheme.spacingLg),
                  _PoiBlock(poi: poi),
                ],
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Bloc « etape » de la feuille : le numero, le nom, et les chiffres du
/// programme (distance, denivele) — les donnees du sentier, sans GPS.
class _StageBlock extends StatelessWidget {
  const _StageBlock({required this.subject});

  final StagePinSubject subject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stage = subject.stage;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            StageNumberCircle(number: stage.orderIndex, color: subject.color),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.a11y.stageMarker(number: stage.orderIndex),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (stage.nameFr.isNotEmpty)
                    Text(stage.nameFr, style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacingSm),
        Wrap(
          spacing: AppTheme.spacingMd,
          runSpacing: AppTheme.spacingXs,
          children: [
            _Figure(
              label: t.stage.distance,
              value: '${stage.distance.toStringAsFixed(1)} km',
            ),
            _Figure(
              label: t.stage.dPlus,
              value: '${stage.elevationGain} m',
            ),
            _Figure(
              label: t.stage.dMinus,
              value: '${stage.elevationLoss} m',
            ),
          ],
        ),
      ],
    );
  }
}

/// Bloc « lieu » de la feuille : tout ce que la base sait du point d'interet.
class _PoiBlock extends StatelessWidget {
  const _PoiBlock({required this.poi});

  final PoiModel poi;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = PoiMarker.colorFor(poi.type);
    final hours = poi.openingHours;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            PoiMarker(type: poi.type, size: 32),
            const SizedBox(width: AppTheme.spacingMd),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    poi.name,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    poi.altitudeM > 0
                        ? '${poiTypeLabel(poi.type)} · ${poi.altitudeM} m'
                        : poiTypeLabel(poi.type),
                    style: theme.textTheme.bodySmall?.copyWith(color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (poi.description.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacingSm),
          Text(poi.description, style: theme.textTheme.bodySmall),
        ],
        if (hours != null && hours.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacingXs),
          _Figure(label: t.poi.hours, value: hours),
        ],
      ],
    );
  }
}

/// Un chiffre etiquete de la feuille (« Distance : 12.5 km »).
class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label : ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.grisTexteSecondaire,
            ),
          ),
          TextSpan(
            text: value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
