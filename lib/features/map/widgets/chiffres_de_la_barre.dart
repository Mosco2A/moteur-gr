/// LES SIX CASES DE CHIFFRES DE LA BARRE DE LA CARTE — forme GR20.
///
/// SORTIES DE `stage_progress_bar.dart` A LA TACHE 762, et pas par gout du
/// rangement : ce fichier tenait EXACTEMENT sur les 500 lignes du plafond
/// ECR-15, et les deux ajouts de ce lot — le compte des etapes a la place de
/// l'altitude, et le bouton qui dit sa destination — le faisaient passer a 588.
/// La garde `taille_et_rangement_645_test.dart` l'a refuse, a raison : passe
/// cette taille, plus personne ne lit le fichier en entier avant d'y toucher.
///
/// CE QUI EST ICI EST UNE UNITE, PAS UNE DECOUPE ARBITRAIRE : la seconde ligne
/// de la barre, celle qui porte les chiffres MESURES. Elle ne prend aucune
/// decision — elle recoit six valeurs deja choisies par la barre, qui est seule
/// a savoir quel perimetre elle montre, et les met en forme.
///
/// LA FORME EST CELLE QUE CHRIS A TRANCHEE (tache 558), mot pour mot :
/// « respecte la FORME GR20 pour cet ecran! ». Les six chiffres tenaient dans
/// un `Wrap` a plat, icone et texte sur la meme ligne, en petit — la navigation
/// de reference les pose en SIX CASES SUR DEUX LIGNES centrees (colonne, grosse
/// icone de 28 px, valeur en gras dessous, libelle plus discret en dernier).
/// Elle se lit d'un coup d'oeil en marchant, ce qu'une ligne de six petites
/// mentions ne permet pas.
///
/// AUCUNE VALEUR N'EST AFFICHEE A ZERO (regle du correctif L5-6) : une valeur
/// absente disparait, ou porte un tiret quand
/// [ChiffresDeLaBarre.showPendingValues] est vrai. Un zero se lirait comme une
/// mesure.
library;

import 'package:flutter/material.dart';

import '../../../core/branding/stepways_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';

/// La seconde ligne de la barre : six chiffres mesures, sur deux rangees.
///
/// INFORMATIVE ET RIEN D'AUTRE : la barre l'enveloppe dans un [IgnorePointer]
/// pour qu'elle ne vole aucun geste a la carte.
class ChiffresDeLaBarre extends StatelessWidget {
  /// Recoit les six valeurs, deja choisies par la barre selon son perimetre.
  const ChiffresDeLaBarre({
    required this.accent,
    required this.showPendingValues,
    super.key,
    this.totalDistanceKm,
    this.distanceCoveredKm,
    this.avgSpeedKmh,
    this.elevationGainM,
    this.elevationLossM,
    this.altitudeM,
    this.etapesFaites,
    this.etapesTotal,
  });

  /// Marque d'une valeur qui n'est pas encore mesurable (parite GR20 : `'--'`).
  ///
  /// Volontairement un SIGNE et non un mot : il ne demande aucune traduction et
  /// se lit dans les cinq langues.
  static const String pendingValueLabel = '--';

  /// La teinte du PERIMETRE affiche (tache 747) : couleur du sentier pour
  /// l'etape, bleu pour le sentier entier.
  final Color accent;

  /// Affiche les valeurs absentes en attente au lieu de les masquer (LOT D).
  final bool showPendingValues;

  /// Total du perimetre en kilometres. `null` = masque.
  final double? totalDistanceKm;

  /// Parcouru du perimetre en kilometres. `null` = masque.
  final double? distanceCoveredKm;

  /// Vitesse moyenne mesuree en km/h. `null` = masquee, jamais zero.
  final double? avgSpeedKmh;

  /// Denivele positif du perimetre. `null` = masque.
  final int? elevationGainM;

  /// Denivele negatif du perimetre. `null` = masque.
  final int? elevationLossM;

  /// Altitude courante en metres. `null` = masquee.
  final double? altitudeM;

  /// Etapes faites, en vue sentier entier (tache 762). `null` = l'altitude
  /// garde la troisieme case.
  final int? etapesFaites;

  /// Nombre total d'etapes du sentier (voir [etapesFaites]).
  final int? etapesTotal;

  /// Vrai des qu'au moins une valeur est disponible, ou en mode « en attente ».
  bool get aQuelqueChoseAMontrer =>
      showPendingValues ||
      totalDistanceKm != null ||
      distanceCoveredKm != null ||
      elevationGainM != null ||
      elevationLossM != null ||
      avgSpeedKmh != null ||
      altitudeM != null ||
      _montreLesEtapes;

  /// Vrai quand la troisieme case de la seconde rangee porte le compte des
  /// etapes (vue sentier entier) plutot que l'altitude du moment.
  bool get _montreLesEtapes => etapesFaites != null && etapesTotal != null;

  /// Libelle d'un chiffre : sa valeur si elle existe, sinon le tiret d'attente.
  String _valeurOuTiret(String? formatted) => formatted ?? pendingValueLabel;

  /// Vrai si la case doit etre rendue : valeur connue, ou mode « en attente ».
  bool _montre(Object? valeur) => valeur != null || showPendingValues;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Rangee 1 — CE QUI AVANCE : total du perimetre, parcouru, vitesse
        // moyenne.
        _Rangee(
          children: [
            if (_montre(totalDistanceKm))
              _CaseMesuree(
                accent: accent,
                icon: StepwaysIcons.distance,
                label: t.tracking.total,
                value: _valeurOuTiret(
                  totalDistanceKm == null
                      ? null
                      : '${totalDistanceKm!.toStringAsFixed(1)} km',
                ),
              ),
            if (_montre(distanceCoveredKm))
              _CaseMesuree(
                accent: accent,
                icon: StepwaysIcons.pas,
                label: t.tracking.covered,
                value: _valeurOuTiret(
                  distanceCoveredKm == null
                      ? null
                      : '${distanceCoveredKm!.toStringAsFixed(1)} km',
                ),
              ),
            if (_montre(avgSpeedKmh))
              _CaseMesuree(
                accent: accent,
                icon: StepwaysIcons.vitesse,
                label: t.tracking.avgSpeed,
                value: _valeurOuTiret(
                  avgSpeedKmh == null
                      ? null
                      : '${avgSpeedKmh!.toStringAsFixed(1)} km/h',
                ),
              ),
          ],
        ),
        // Rangee 2 — LE RELIEF : D+, D-, puis l'altitude ou les etapes faites.
        _Rangee(
          children: [
            if (_montre(elevationGainM))
              _CaseMesuree(
                accent: accent,
                icon: StepwaysIcons.denivelePlus,
                label: t.tracking.dPlus,
                value: _valeurOuTiret(
                  elevationGainM == null ? null : '$elevationGainM m',
                ),
              ),
            if (_montre(elevationLossM))
              _CaseMesuree(
                accent: accent,
                icon: StepwaysIcons.deniveleMoins,
                label: t.tracking.dMinus,
                value: _valeurOuTiret(
                  elevationLossM == null ? null : '$elevationLossM m',
                ),
              ),
            // TROISIEME CASE : LES ETAPES FAITES EN VUE SENTIER, L'ALTITUDE EN
            // VUE ETAPE (tache 762, decision de Christophe du 09/10 16:29 puis
            // 16:32). Une seule des deux, jamais les deux : la rangee tient
            // trois cases.
            if (_montreLesEtapes)
              _CaseMesuree(
                accent: accent,
                icon: StepwaysIcons.itineraire,
                label: t.tracking.stagesDone,
                value: '$etapesFaites / $etapesTotal',
              )
            else if (_montre(altitudeM))
              _CaseMesuree(
                accent: accent,
                icon: StepwaysIcons.sommet,
                label: t.tracking.altitude,
                value: _valeurOuTiret(
                  altitudeM == null ? null : '${altitudeM!.round()} m',
                ),
              ),
          ],
        ),
      ],
    );
  }
}

/// Une RANGEE de trois chiffres, repartis a egalite (tache 558).
///
/// Ne se rend PAS quand elle n'a rien a montrer : une rangee vide laisserait un
/// blanc au milieu de la barre. Chaque case occupe le tiers de la largeur — le
/// libelle se replie donc sur deux lignes au lieu de deborder ou d'etre coupe,
/// ce qui compte d'autant plus que les cinq langues n'ont pas la meme longueur
/// de mots (« Vit. moy. » / « Ø Geschw. »).
class _Rangee extends StatelessWidget {
  const _Rangee({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingXs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [for (final child in children) Expanded(child: child)],
      ),
    );
  }
}

/// Une valeur mesuree : icone, chiffre, libelle — FORME GR20 (tache 558).
class _CaseMesuree extends StatelessWidget {
  const _CaseMesuree({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final String icon;
  final String label;
  final String value;

  /// La teinte du perimetre affiche, posee par la barre.
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: '$label $value',
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Grosse icone (parite GR20 : 28 px), dans la couleur d'accent du
          // sentier plutot qu'en gris : c'est le repere qu'on attrape en
          // premier sur un ecran de terrain.
          StepIcon(icon, size: 28, color: accent),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.grisTexteSecondaire,
            ),
          ),
        ],
      ),
    );
  }
}
