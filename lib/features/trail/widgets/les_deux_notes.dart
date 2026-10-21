/// LES DEUX JAUGES D'UNE JOURNEE — effort et pente, en lecture seule.
library;

import 'package:flutter/material.dart';

import '../../../core/branding/stepways_icons.dart';
import '../../../core/theme/app_theme.dart';
import 'jauge_de_niveau.dart';

/// LES DEUX JAUGES D'UNE JOURNEE, L'UNE SOUS L'AUTRE (taches 861 et 862).
///
/// POURQUOI DEUX AXES ET PAS UNE NOTE, ET CE N'EST PAS UN CHOIX DE GOUT. Le
/// releve des methodes publiees du monde a rendu un resultat qui condamnait la
/// recherche d'une note unique : PERSONNE NE RESOUT LA DIFFICULTE D'UNE
/// JOURNEE DANS UN CHIFFRE UNIQUE. Le MIDE espagnol affiche quatre axes, la
/// FFRandonnee trois, Komoot deux, le SAC et le CAI cotent la technique
/// separement de l'effort. Le seul chiffre unique qui internalise la
/// concentration est l'IBP, et sa formule n'est pas publique.
///
/// LA PREUVE EST DANS NOS PROPRES MESURES. Sur le GR20 entier a sept jours,
/// les jours 2 et 7 ont le MEME effort — 17,78 et 17,77 — et des pentes de
/// 14,53 contre 3,85. Deux journees qui coutent la meme energie et qui ne se
/// ressemblent en rien : 13,9 km a 145 m/km contre 39,9 km a 39 m/km. Aucune
/// note unique ne pouvait dire ca, quelle que soit sa formule.
///
/// POURQUOI DEUX JAUGES PLUTOT QUE DEUX NOMBRES. C'est la POSITION de
/// l'aiguille qui porte l'information, et une position se lit sans percevoir
/// aucune teinte — donc la couleur n'est jamais seule porteuse, ce qu'exige
/// WCAG 1.4.1. Et la barre donne le CONTEXTE qu'un nombre nu ne donne pas : un
/// 16 se voit loin sur l'echelle, un 8 se voit au tiers, sans qu'il faille
/// savoir que l'echelle va a vingt.
///
/// LE CHIFFRE BRUT RESTE A COTE DE LA PENTE, JAMAIS A SA PLACE. Une note sur
/// vingt suggere une precision au dixieme que la pente moyenne n'a pas, et les
/// metres par kilometre corrigent exactement ca. Reserve posee par Athena.
class LesDeuxNotes extends StatelessWidget {
  /// Les deux jauges d'une journee.
  const LesDeuxNotes({
    required this.effort,
    required this.raideur,
    required this.metresParKm,
    required this.libelleDEffort,
    required this.libelleDeRaideur,
    required this.graduationsDEffort,
    required this.graduationsDeRaideur,
    this.titre,
    super.key,
  });

  /// La note d'EFFORT sur vingt : ce que la journee coute.
  final double effort;

  /// La note de PENTE sur vingt : a quel point ca monte pour la distance.
  final double raideur;

  /// Le chiffre brut de la pente, en metres de montee par kilometre.
  final double metresParKm;

  /// Ce que la bande d'effort dit, pour le lecteur d'ecran.
  final String libelleDEffort;

  /// Ce que la bande de pente dit, pour le lecteur d'ecran.
  final String libelleDeRaideur;

  /// Les reperes publies de l'axe effort, en note.
  final List<double> graduationsDEffort;

  /// Les reperes publies de l'axe pente, en note.
  final List<double> graduationsDeRaideur;

  /// Ce que ces deux jauges decrivent, s'il faut le dire.
  final String? titre;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nom = titre;
    return Column(
      key: const ValueKey('les-deux-notes'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (nom != null) ...<Widget>[
          Text(
            nom,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.grisTexteSecondaire,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
        ],
        JaugeDeNiveau(
          axe: 'Effort',
          note: effort,
          // LA CHAUSSURE POUR L EFFORT : elle dit la marche, et sa silhouette
          // ne se confond pas avec celle d'un sommet.
          glyphe: StepwaysIcons.chaussure,
          libelle: libelleDEffort,
          graduations: graduationsDEffort,
        ),
        const SizedBox(height: AppTheme.spacingSm),
        JaugeDeNiveau(
          axe: 'Pente',
          note: raideur,
          glyphe: StepwaysIcons.sommet,
          libelle: libelleDeRaideur,
          graduations: graduationsDeRaideur,
          appoint: '${metresParKm.round()} m de montee par kilometre',
        ),
      ],
    );
  }
}
