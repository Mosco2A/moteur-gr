/// LES DEUX NOTES D'UNE JOURNEE, NOMMEES ET COLOREES — effort et raideur.
library;

import 'package:flutter/material.dart';

import '../../../core/branding/stepways_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../domain/niveau_des_icones.dart';
import 'choix_des_jours.dart';
import 'icones_de_niveau.dart';

/// LES DEUX NOTES D'UNE JOURNEE, COTE A COTE (tache 861).
///
/// POURQUOI DEUX ET PAS UNE, ET CE N'EST PAS UN CHOIX DE GOUT. Le releve des
/// methodes publiees du monde a rendu un resultat qui condamnait la recherche
/// d'une note unique : PERSONNE NE RESOUT LA DIFFICULTE D'UNE JOURNEE DANS UN
/// CHIFFRE UNIQUE. Le MIDE espagnol affiche quatre axes, la FFRandonnee trois,
/// Komoot deux, le SAC et le CAI cotent la technique separement de l'effort.
/// Le seul chiffre unique qui internalise la concentration est l'IBP, et sa
/// formule n'est pas publique.
///
/// LA PREUVE EST DANS NOS PROPRES MESURES. Sur le GR20 entier a sept jours,
/// les jours 2 et 7 ont le MEME effort — 17,78 et 17,77 — et des raideurs de
/// 14,53 contre 3,85. Deux journees qui coutent la meme energie et qui ne se
/// ressemblent en rien : 13,9 km a 145 m/km contre 39,9 km a 39 m/km. Aucune
/// note unique ne pouvait dire ca, quelle que soit sa formule.
///
/// LE CHIFFRE BRUT EST AFFICHE A COTE DE LA RAIDEUR, JAMAIS A SA PLACE. Les
/// deux se corrigent l'un l'autre : une couleur se lit en une seconde mais
/// « 145 metres par kilometre » ne dit rien a un debutant, et inversement une
/// note sur vingt suggere une precision au dixieme que la pente moyenne n'a
/// pas. Il faut les deux, et c'est pour cela qu'ils ne se separent pas.
class LesDeuxNotes extends StatelessWidget {
  /// Les deux notes d'une journee, avec le chiffre brut de la raideur.
  const LesDeuxNotes({
    required this.effort,
    required this.raideur,
    required this.metresParKm,
    required this.niveauDEffort,
    required this.niveauDeRaideur,
    required this.libelleDEffort,
    required this.libelleDeRaideur,
    this.titre,
    super.key,
  });

  /// La note d'EFFORT sur vingt : ce que la journee coute.
  final double effort;

  /// La note de RAIDEUR sur vingt : a quel point ca monte pour la distance.
  final double raideur;

  /// Le chiffre brut de la raideur, en metres de montee par kilometre.
  final double metresParKm;

  /// Le niveau de la rangee de CHAUSSURES, lu sur les seuils du bareme.
  final NiveauDIcone niveauDEffort;

  /// Le niveau de la rangee de MONTAGNES, lu sur les bandes de l'IMBA.
  final NiveauDIcone niveauDeRaideur;

  /// Ce que la bande d'effort dit, pour le lecteur d'ecran.
  final String libelleDEffort;

  /// Ce que la bande de raideur dit, pour le lecteur d'ecran.
  final String libelleDeRaideur;

  /// Ce que ces deux notes decrivent, s'il faut le dire.
  final String? titre;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nom = titre;
    return Column(
      key: const ValueKey('les-deux-notes'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (nom != null) ...[
          Text(
            nom,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.grisTexteSecondaire,
            ),
          ),
          const SizedBox(height: AppTheme.spacingXs),
        ],
        Row(
          children: [
            Expanded(
              child: _UneNote(
                nom: 'Effort',
                note: effort,
                cle: 'note-d-effort',
                // LA CHAUSSURE POUR L EFFORT : elle dit la marche. Et un
                // glyphe different de la montagne evite de laisser croire que
                // les couleurs de pistes fondent les deux axes de la meme
                // facon — elles graduent une PENTE, donc elles collent a la
                // raideur et sont empruntees sur l'effort.
                glyphe: StepwaysIcons.chaussure,
                niveau: niveauDEffort,
                libelle: libelleDEffort,
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _UneNote(
                nom: 'Raideur',
                note: raideur,
                cle: 'note-de-raideur',
                glyphe: StepwaysIcons.sommet,
                niveau: niveauDeRaideur,
                libelle: libelleDeRaideur,
                // LE CHIFFRE BRUT, ET IL EST ARRONDI A L'ENTIER : une pente
                // moyenne au dixieme de metre par kilometre serait une fausse
                // precision, c'est la reserve meme que ce chiffre corrige.
                brut: '${metresParKm.round()} m/km',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// UNE NOTE NOMMEE, AVEC SA COULEUR ET, s'il y en a, son chiffre brut.
class _UneNote extends StatelessWidget {
  const _UneNote({
    required this.nom,
    required this.note,
    required this.cle,
    required this.glyphe,
    required this.niveau,
    required this.libelle,
    this.brut,
  });

  final String nom;
  final double note;
  final String cle;
  final String glyphe;
  final NiveauDIcone niveau;
  final String libelle;
  final String? brut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final chiffre = nombreAUneDecimale(note);
    final enBrut = brut;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // LA RANGEE D'ICONES PORTE LA COULEUR, PAS LE TEXTE : du texte colore
        // sur fond clair tombe sous le contraste exige des qu'on approche du
        // jaune, et surtout la rangee porte DEUX choses a la fois — la teinte
        // pour le coup d'oeil et le NOMBRE pour qui ne distingue pas les
        // teintes. Le texte, lui, reste a la couleur normale et donc lisible.
        IconesDeNiveau(
          niveau: niveau,
          glyphe: glyphe,
          axe: nom,
          noteLue: chiffre,
          libelle: libelle,
        ),
        const SizedBox(height: AppTheme.spacingXs),
        Text(
          '$nom $chiffre sur 20',
          key: ValueKey(cle),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        if (enBrut != null)
          Text(
            enBrut,
            key: const ValueKey('raideur-en-brut'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.grisTexteSecondaire,
            ),
          ),
      ],
    );
  }
}
