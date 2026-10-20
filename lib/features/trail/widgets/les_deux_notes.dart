/// LES DEUX NOTES D'UNE JOURNEE, NOMMEES ET COLOREES — effort et raideur.
library;

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import 'choix_des_jours.dart';

/// LA COULEUR D'UNE NOTE SUR VINGT, sur le degrade vert-jaune-orange-rouge.
///
/// POURQUOI UN DEGRADE CONTINU ET PAS QUATRE BANDES. Christophe a demande le
/// score sur vingt AVEC le degrade, et une bande exigerait un SEUIL — or les
/// seuils de niveau ne sont pas tranches (18/10 : « on tranchera les niveaux
/// apres »). Un degrade continu colore sans decider : il n'affirme aucune
/// frontiere, il montre une position.
///
/// LA COULEUR NE PORTE JAMAIS L'INFORMATION SEULE. Le nombre est toujours
/// ecrit a cote, parce qu'une couleur est illisible pour une partie des
/// lecteurs et parce qu'elle ne dit pas de combien.
Color couleurDeLaNote(double note) {
  final part = (note / 20.0).clamp(0.0, 1.0);
  if (part <= 1 / 3) {
    return Color.lerp(AppTheme.vertFacile, AppTheme.jauneModere, part * 3)!;
  }
  if (part <= 2 / 3) {
    return Color.lerp(
      AppTheme.jauneModere,
      AppTheme.orangeDifficile,
      (part - 1 / 3) * 3,
    )!;
  }
  return Color.lerp(
    AppTheme.orangeDifficile,
    AppTheme.rougeExtreme,
    (part - 2 / 3) * 3,
  )!;
}

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
    this.titre,
    super.key,
  });

  /// La note d'EFFORT sur vingt : ce que la journee coute.
  final double effort;

  /// La note de RAIDEUR sur vingt : a quel point ca monte pour la distance.
  final double raideur;

  /// Le chiffre brut de la raideur, en metres de montee par kilometre.
  final double metresParKm;

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
              ),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Expanded(
              child: _UneNote(
                nom: 'Raideur',
                note: raideur,
                cle: 'note-de-raideur',
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
    this.brut,
  });

  final String nom;
  final double note;
  final String cle;
  final String? brut;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final couleur = couleurDeLaNote(note);
    final chiffre = nombreAUneDecimale(note);
    final enBrut = brut;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // LA PASTILLE PORTE LA COULEUR, PAS LE TEXTE : du texte colore
            // sur fond clair tombe sous le contraste exige des qu'on approche
            // du jaune. Une pastille a cote d'un texte lisible donne la
            // couleur sans rien sacrifier.
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: couleur, shape: BoxShape.circle),
            ),
            const SizedBox(width: AppTheme.spacingXs),
            Flexible(
              child: Text(
                '$nom $chiffre sur 20',
                key: ValueKey(cle),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        if (enBrut != null)
          Padding(
            padding: const EdgeInsets.only(left: 16 + AppTheme.spacingXs),
            child: Text(
              enBrut,
              key: const ValueKey('raideur-en-brut'),
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.grisTexteSecondaire,
              ),
            ),
          ),
      ],
    );
  }
}
