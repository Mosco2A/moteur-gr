/// LE BANDEAU QUI DIT QU'UN CONTENU EST FABRIQUE (tache 810).
///
/// LA LOI, POSEE PAR CHRISTOPHE LE 11/10/2026 A 09:27, verbatim : « tu rends
/// accessible le faux journal er le faux recap oui . Demo = toutes les
/// fonctionalite visible mais bouchonnees ». EN DEMO, TOUT SE VOIT, RIEN NE
/// S'ECRIT.
///
/// POURQUOI UN SECOND AVERTISSEMENT, ALORS QUE LE BANDEAU « MODE DEMO » EST
/// DEJA PERMANENT EN HAUT DE L'ECRAN. Parce que les deux ne disent pas la meme
/// chose. Le bandeau orange dit OU L'ON EST — en demonstration. Celui-ci dit CE
/// QU'ON REGARDE — une matiere inventee. La difference compte precisement sur
/// les deux ecrans que ce lot remplit : un recapitulatif qui annonce « 87 km,
/// 4 274 m de denivele, 7 etapes sur 7 » avec de vraies dates, et un carnet de
/// sept pages signees de vrais noms de lieux, se laissent prendre pour une
/// vraie randonnee des qu'on les photographie ou qu'on les fait defiler a
/// quelqu'un. L'exigence de la tache est explicite : un contenu fabrique ne
/// doit JAMAIS pouvoir se confondre avec une vraie randonnee du randonneur.
///
/// HORS DEMONSTRATION, IL N'OCCUPE AUCUNE PLACE. Il ne rend rien du tout — pas
/// une marge, pas un separateur. Un ecran reel est exactement ce qu'il etait
/// avant ce lot.
///
/// IL VIT DANS `shared/`, ET C'EST LA SEULE PLACE POSSIBLE. Deux features le
/// montent — `after` (le recapitulatif) et `journal` (le carnet) — et le
/// plafond des fleches entre features est a ZERO (cf.
/// `test/structurel/couches_respectees_645_test.dart`). Ce qu'elles partagent
/// monte dans `shared/`, comme [GriseEnDemo] avant lui.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/branding/stepways_icons.dart';
import '../../core/services/session_demo.dart';
import '../../core/theme/app_theme.dart';
import '../../i18n/translations.g.dart';
import 'app_card.dart';

/// Dit, pendant une demonstration, que le contenu de l'ecran est fabrique.
///
/// Rend un [SizedBox.shrink] hors demonstration.
class BandeauMatiereFabriquee extends ConsumerWidget {
  /// Construit le bandeau d'avertissement de matiere fabriquee.
  const BandeauMatiereFabriquee({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(enDemoProvider)) return const SizedBox.shrink();
    final theme = Theme.of(context);
    // EXACTEMENT l'orange du bandeau « MODE DEMO » du haut (`cadre_demo.dart`
    // lit la meme constante) : les deux parlent de la demonstration, ils
    // doivent se reconnaitre d'un coup d'oeil.
    const couleur = AppTheme.orangeDifficile;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingBase),
      child: Semantics(
        container: true,
        label: t.demo.matiereFabriquee,
        child: AppCard(
          backgroundColor: couleur.withAlpha(30),
          borderColor: couleur.withAlpha(90),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StepIcon(StepwaysIcons.info, size: 20, color: couleur),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  t.demo.matiereFabriquee,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
