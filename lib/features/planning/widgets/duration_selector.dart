/// Le curseur de duree, et le qualificatif d'effort qui n'a plus qu'UNE base de
/// calcul : un second systeme a ete retire.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../domain/feasibility_formula.dart';

/// LE QUALIFICATIF D'EFFORT N'A PLUS QU'UNE SEULE BASE DE CALCUL (tache 634,
/// DEM-260929-1132).
///
/// CE QUI A ETE RETIRE. Ce fichier portait un SECOND systeme de qualificatif,
/// `durationDifficultyFor` : un simple ratio etapes / jours de marche (<=0,8
/// « Confortable », <=1,0 « Standard », <=1,3 « Sportif », au-dela « Tres
/// exigeant »), herite du GR20. Il ne connaissait ni le profil du randonneur,
/// ni l'energie d'une journee, ni son plafond. Il servait de repli quand le
/// verdict n'etait pas calculable — si bien que la MEME pastille pouvait dire
/// « Sportif » (un ratio) ou « Decoupage exigeant » (une energie rapportee a
/// une capacite) selon l'etat du profil, sans que rien ne distingue les deux.
///
/// Retour de Christophe du 29/09 11:32 : « pourquoi la faisabilite de mare a
/// mare te le propose en 4 jours ?????? En te disant que c'est exigeant, c'est
/// completement con !!! ». Le plan et le jugement doivent venir de la MEME base
/// de calcul. Il n'en reste donc qu'une : le verdict. Quand il n'est pas
/// calculable, la pastille ne s'affiche PAS — se taire vaut mieux que qualifier
/// l'effort d'un randonneur sur une echelle qui ne le connait pas.

/// COULEUR DU VERDICT DE FAISABILITE (retour Chris 6c du 25/09, spec #100417).
///
/// Mot pour mot : « le curseur jour change de couleur dans programme ». Ce sont
/// les MEMES couleurs que le feu tricolore de l'ecran Faisabilite, et c'est
/// obligatoire : deux palettes pour un seul verdict, ce sont deux verdicts pour
/// le randonneur.
Color durationVerdictColor(FeasibilityVerdict verdict) {
  switch (verdict) {
    case FeasibilityVerdict.green:
      return AppTheme.vertFacile;
    case FeasibilityVerdict.orange:
      return AppTheme.orangeDifficile;
    case FeasibilityVerdict.red:
      return AppTheme.rougeUrgence;
  }
}

/// Libelle i18n du verdict (memes textes que le feu tricolore).
String durationVerdictLabel(FeasibilityVerdict verdict) {
  final v = t.feasibility.formula.verdicts;
  switch (verdict) {
    case FeasibilityVerdict.green:
      return v.green;
    case FeasibilityVerdict.orange:
      return v.orange;
    case FeasibilityVerdict.red:
      return v.red;
  }
}

/// Selecteur de duree pour le programme (parite GR20 : le CURSEUR de duree).
///
/// Reprend le curseur d'origine de GR20 (`ItineraryConfigScreen`) : un [Slider]
/// borne par le nombre d'etapes du sentier ([minDuration]..[maxDuration],
/// divisions entieres), dont la piste active et le pouce prennent la COULEUR de
/// la DIFFICULTE = ratio etapes / jours de marche. Au-dessus, la valeur courante
/// est affichee en grand dans la meme couleur, avec un petit label de difficulte
/// (Confortable / Standard / Sportif / Tres exigeant), exactement comme GR20.
/// Sous le curseur, les bornes min / max encadrent la plage.
///
/// RETOUR CHRIS #9 (LOT 2) : le nombre de jours affiche en grand suit DESORMAIS
/// le programme REEL, jours de repos inclus ([totalDays] = marche + repos), et
/// non plus la seule duree de MARCHE ([selectedDuration]) pilotee par le slider.
/// Ainsi, ajouter un jour de repos ou separer une etape (qui augmentent le total
/// de jours) met a jour ce compteur immediatement. Le SLIDER, lui, continue de
/// regler la repartition sur les jours de MARCHE (son role d'origine) ; quand des
/// repos existent, le libelle detaille « {total} j (dont {rest} repos) ».
///
/// Hors systeme de peaux : les couleurs vert / jaune / orange / rouge sont des
/// couleurs SEMANTIQUES de difficulte (AppTheme), jamais la peau du sentier.
/// Tout libelle passe par Slang (t.programme.duration.*).
class DurationSelector extends StatelessWidget {
  const DurationSelector({
    super.key,
    required this.minDuration,
    required this.maxDuration,
    required this.selectedDuration,
    required this.stageCount,
    required this.walkingDays,
    required this.totalDays,
    required this.restDays,
    required this.onDurationChanged,
    this.verdict,
  });

  /// Nombre minimal de jours (borne basse du sentier).
  final int minDuration;

  /// Nombre maximal de jours (borne haute du sentier).
  final int maxDuration;

  /// Duree de MARCHE actuellement selectionnee (en jours) — reglee par le slider.
  final int selectedDuration;

  /// Nombre total d'etapes du sentier (numerateur du ratio de difficulte).
  final int stageCount;

  /// Nombre de jours de MARCHE du programme courant (repos exclus) : denominateur
  /// du ratio de difficulte, pour que la couleur reflete l'effort reel.
  final int walkingDays;

  /// Nombre TOTAL de jours du programme reel (marche + repos), retour Chris #9 :
  /// c'est LUI qui est affiche en grand (il suit les repos ajoutes / splits).
  final int totalDays;

  /// Nombre de jours de repos du programme courant (detail du libelle total).
  final int restDays;

  /// Callback appele quand l'utilisateur change la duree.
  final ValueChanged<int> onDurationChanged;

  /// VERDICT DE FAISABILITE DU DECOUPAGE COURANT (retour Chris 6c).
  ///
  /// Quand il est fourni, c'est LUI qui colore le curseur et nomme la pastille :
  /// le randonneur bouge le curseur et voit le vert arriver. `null` tant que le
  /// verdict n'est pas calculable (profil incomplet, etapes pas encore
  /// chargees) — on retombe alors sur le ratio etapes/jour d'origine, qui ne
  /// depend d'aucun profil. On n'invente jamais un verdict pour colorer.
  final FeasibilityVerdict? verdict;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // UNE SEULE BASE DE CALCUL (tache 634). Le verdict, ou rien : pas de
    // second qualificatif de repli sur une autre echelle.
    final v = verdict;
    final sliderColor = v == null
        ? AppTheme.grisGranite
        : durationVerdictColor(v);
    final badgeLabel = v == null ? null : durationVerdictLabel(v);

    // Bornes securisees : un slider exige min < max et au moins 1 division.
    final min = minDuration.toDouble();
    final max = maxDuration.toDouble();
    final hasRange = max > min;
    final clamped = selectedDuration.toDouble().clamp(min, max);
    final divisions = hasRange ? (max - min).round() : 1;

    // Retour Chris #9 : le grand compteur = TOTAL de jours (marche + repos), qui
    // suit les repos ajoutes / etapes separees. Avec repos -> libelle detaille.
    //
    // TACHE 569 (R2) : IL DIT DESORMAIS QU'IL COMPTE UN TOTAL. Il affichait
    // « 9 j », l'ecran Faisabilite conseillait « 9 jours » de MARCHE, et les
    // deux 9 n'etaient pas le meme nombre — c'est le retour 7 de Chris, « vise
    // 9 jours et ca propose 11 ». Aucun nombre de jours ne s'affiche plus sans
    // dire s'il compte la marche, le repos ou le total, et ce curseur compte des
    // totaux : ses bornes et sa bulle le disent aussi.
    final daysLabel = restDays > 0
        ? t.programme.duration.daysWithRest
              .replaceAll('{total}', '$totalDays')
              .replaceAll('{rest}', '$restDays')
        : t.programme.duration.daysTotal.replaceAll('{count}', '$totalDays');

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Libelle de section + valeur courante coloree + label difficulte.
          Row(
            children: [
              Text(
                t.programme.duration.label,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              // Pastille de difficulte (couleur semantique + libelle i18n).
              //
              // FLEXIBLE, ET C'EST OBLIGATOIRE : depuis que la pastille peut
              // porter un libelle de VERDICT (« Au-dessus de tes capacites »,
              // trois fois plus long que « Tres exigeant »), une pastille rigide
              // faisait deborder la ligne sur un ecran de telephone — constate
              // en test widget a 468 px de large. Elle se replie desormais sur
              // deux lignes plutot que de deborder.
              if (badgeLabel != null)
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: sliderColor.withAlpha(30),
                      borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                      border: Border.all(color: sliderColor.withAlpha(90)),
                    ),
                    child: Text(
                      badgeLabel,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.end,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: sliderColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          // Valeur courante en grand, dans la couleur de difficulte (parite GR20).
          Text(
            daysLabel,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: sliderColor,
              fontWeight: FontWeight.w700,
            ),
          ),
          // Le curseur : couleur active = difficulte (parite GR20).
          Slider(
            value: clamped,
            min: min,
            max: hasRange ? max : min + 1,
            divisions: divisions,
            label: t.programme.duration.daysTotal.replaceAll(
              '{count}',
              '${clamped.round()}',
            ),
            activeColor: sliderColor,
            inactiveColor: AppTheme.grisGranite.withAlpha(40),
            onChanged: hasRange
                ? (value) => onDurationChanged(value.round())
                : null,
          ),
          // Bornes min / max sous le curseur (parite GR20).
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                t.programme.duration.daysTotal.replaceAll(
                  '{count}',
                  '$minDuration',
                ),
                style: theme.textTheme.bodySmall,
              ),
              Text(
                t.programme.duration.daysTotal.replaceAll(
                  '{count}',
                  '$maxDuration',
                ),
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
