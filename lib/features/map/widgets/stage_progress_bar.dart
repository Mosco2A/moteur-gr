/// La ligne de chiffres MESURES en bas de la carte : etape, distance restante,
/// pourcentage, et le signalement d'un ecart au trace.
library;

import 'package:flutter/material.dart';

import '../../../core/branding/stepways_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/texte_ajuste.dart';
import 'chiffres_de_la_barre.dart';
import 'entete_de_la_barre.dart';

/// Barre de progression d'étape affichée en bas de la carte.
///
/// Affiche le nom de l'étape courante, la distance restante,
/// le pourcentage de progression, et un indicateur "hors tracé"
/// si l'utilisateur est à plus de 100m du sentier.
///
/// CORRECTIF L6-2 — LIGNE DE CHIFFRES MESURÉS. La barre ne portait que quatre
/// informations là où la navigation de référence en affiche six sur deux
/// lignes. Les valeurs ajoutées (total, parcouru, dénivelé, vitesse moyenne,
/// altitude) sont OPTIONNELLES et chacune disparaît quand elle vaut `null` :
/// une valeur absente ne s'affiche pas à zéro. C'est la même règle que le
/// correctif L5-6 — une vitesse moyenne mesurée, ou rien.
///
/// Cette seconde ligne est purement informative : elle est enveloppée dans un
/// [IgnorePointer] pour ne jamais voler un geste à la carte.
///
/// LOT D (tâche 554) — JAMAIS D'ÉCRAN NU. Retour de Chris, mot pour mot :
/// « 14 navigation ne ressemble en rien a GR20 !!!!! ». La cause n'était pas un
/// manque de fonctions : c'est que, sans randonnée démarrée, TOUTES les valeurs
/// valent `null`, les six disparaissent d'un coup et il ne reste qu'une carte
/// nue — là où la navigation de référence montre TOUJOURS ses six cases, avec
/// un tiret quand la valeur n'est pas encore connue (`'--'` pour l'altitude
/// sans fix GPS).
///
/// D'où [showPendingValues] : quand il est vrai, une valeur absente s'affiche
/// en attente ([pendingValueLabel]) au lieu de disparaître. La règle du
/// correctif L5-6 est INTACTE — on n'affiche jamais un zéro qui aurait l'air
/// mesuré ; un tiret dit « pas encore », ce qui est la vérité. Le défaut reste
/// `false` : en randonnée réelle, la barre garde son comportement d'origine.
///
/// TÂCHE 558 — LA FORME GR20. Chris tranche l'aspect, mot pour mot : « respecte
/// la FORME GR20 pour cet ecran! ». Les six chiffres étaient posés à plat dans
/// un [Wrap], icône et texte alignés sur une ligne, en petit. Ils occupent
/// désormais SIX CASES SUR DEUX LIGNES centrées, grosses icônes, valeur en gras
/// puis libellé — la disposition de `_buildBottomInfoBar` de la navigation de
/// référence. Rien n'est ajouté ni retiré : ce sont les mêmes six chiffres,
/// avec les mêmes règles d'absence.
///
/// La phrase qui expliquait les tirets a été SUPPRIMÉE avec sa clé i18n (retour
/// Chris : « enleve dans randonnee le laius sur les tiret »). [footer] reste,
/// pour une ligne d'action, mais plus personne ne s'en sert pour commenter.
class StageProgressBar extends StatelessWidget {
  const StageProgressBar({
    super.key,
    required this.stageName,
    required this.distanceRemainingKm,
    required this.progressRatio,
    required this.isOffTrack,
    this.totalDistanceKm,
    this.distanceCoveredKm,
    this.elevationGainM,
    this.elevationLossM,
    this.avgSpeedKmh,
    this.altitudeM,
    this.showPendingValues = false,
    this.footer,
    this.perimetreLabel,
    this.basculeLabel,
    this.etapesFaites,
    this.etapesTotal,
    this.vueSentier = false,
    this.onBasculer,
  });

  /// Marque d'une valeur qui n'est pas encore mesurable (parite GR20 : `'--'`).
  ///
  /// Volontairement un SIGNE et non un mot : il ne demande aucune traduction et
  /// se lit dans les cinq langues.
  ///
  /// IL VIT DESORMAIS AVEC LES CASES QUI L'AFFICHENT (tache 762) et n'est
  /// repris ici que pour les appelants qui le nommaient deja : UNE seule
  /// definition, pas deux chaines a garder d'accord.
  static const String pendingValueLabel = ChiffresDeLaBarre.pendingValueLabel;

  /// La part de la ligne du titre que les marqueurs de droite — pastille et
  /// puce hors-trace — ne depassent jamais (tache 808).
  ///
  /// CE QU'ELLE GARANTIT : le nom de l'etape conserve toujours au moins le
  /// tiers restant de la ligne. Au-dela, les marqueurs se reduisent d'un bloc
  /// plutot que de pousser le nom a zero — ce qui est exactement ce qui
  /// arrivait, mesure au banc, avec une police large ou un reglage
  /// d'agrandissement des textes.
  static const double _partDesMarqueurs = 0.62;

  /// Nom de l'étape courante
  final String stageName;

  /// Distance restante en kilomètres
  final double distanceRemainingKm;

  /// Pourcentage de progression (0.0 à 1.0)
  final double progressRatio;

  /// Indicateur hors tracé (distance > 100m)
  final bool isOffTrack;

  /// Distance totale du sentier en kilomètres (L6-2). `null` = masquée.
  final double? totalDistanceKm;

  /// Distance déjà parcourue en kilomètres (L6-2). `null` = masquée.
  final double? distanceCoveredKm;

  /// Dénivelé positif cumulé, mesuré sur la trace (L6-2). `null` = masqué.
  final int? elevationGainM;

  /// Dénivelé négatif cumulé, mesuré sur la trace (L6-2). `null` = masqué.
  final int? elevationLossM;

  /// Vitesse moyenne mesurée en km/h (L6-2). `null` = masquée, jamais zéro.
  final double? avgSpeedKmh;

  /// Altitude courante en mètres (L6-2). `null` = masquée.
  final double? altitudeM;

  /// Affiche les valeurs absentes en attente au lieu de les masquer (LOT D).
  ///
  /// Employé par l'état AVANT randonnée de la carte : les chiffres connus du
  /// programme sont réels, les chiffres qui demandent le GPS portent un tiret.
  final bool showPendingValues;

  /// Ligne d'explication optionnelle sous les chiffres (LOT D).
  ///
  /// Sert à dire ce qui démarrera avec la randonnée, plutôt que de laisser
  /// deviner pourquoi trois cases portent un tiret.
  final Widget? footer;

  /// LE MOT QUI DIT LE PÉRIMÈTRE DES CHIFFRES (tâche 747). `null` = pas de
  /// mention, et la barre garde l'aspect qu'elle avait avant ce lot.
  ///
  /// POURQUOI UN MOT ET PAS SEULEMENT UNE COULEUR. Christophe l'a demandé
  /// explicitement le 09/10 : la vue sentier est d'une autre couleur, « et tu
  /// ajoutes AUSSI un mot, parce que la couleur seule ne suffit pas à qui
  /// distingue mal les couleurs ». Une personne daltonienne — environ un homme
  /// sur douze — ne verrait aucune différence entre les deux vues, et lirait
  /// des kilomètres de sentier en croyant lire son étape. Le mot est donc
  /// l'information ; la couleur n'est qu'un rappel.
  final String? perimetreLabel;

  /// LE MOT DU BOUTON, ET C'EST SA DESTINATION — PAS L'ENDROIT OU L'ON EST
  /// (tache 762).
  ///
  /// RETOUR DE CHRISTOPHE DU 09/10 16:27, mot pour mot : « Le bouton etape/
  /// sentier entier est inverse. Quand on est etape le bouton doit etre sentier
  /// entier et inversement pour l autre ».
  ///
  /// CE QUI ETAIT CONFONDU, ET POURQUOI LES DEUX BESOINS SONT VRAIS. La
  /// pastille [perimetreLabel] disait « Étape » quand on regardait l'etape :
  /// c'est juste comme INDICATION, et faux comme BOUTON — toute la barre etant
  /// tactile, ce mot etait aussi l'etiquette de l'action, et il annoncait donc
  /// l'inverse de ce qu'un appui faisait. Les deux besoins coexistent : il faut
  /// dire DE QUOI parlent les chiffres, et dire OU MENE l'appui.
  ///
  /// ILS SONT DONC SEPARES, et c'est le seul moyen de ne pas recreer le
  /// malentendu dans l'autre sens : la PASTILLE garde le perimetre affiche, le
  /// BOUTON porte la destination. Les fusionner — pastille devenue bouton, ou
  /// bouton portant le perimetre courant — ramenerait un seul mot pour deux
  /// questions.
  ///
  /// `null` = pas de bouton. Sans [onBasculer] il n'est pas rendu non plus : un
  /// bouton qui ne mene nulle part est un geste mort.
  final String? basculeLabel;

  /// COMBIEN D'ETAPES SONT FAITES, et sur combien (tache 762).
  ///
  /// REMPLACE L'ALTITUDE EN VUE SENTIER ENTIER, decision de Christophe du 09/10
  /// 16:29 puis 16:32 : « En sentier entier l altitude pure n a plus lieue
  /// d etre », et a sa place le nombre d'etapes faites sur le total, forme
  /// « 3 / 7 ». L'altitude du moment reste en vue ETAPE, ou elle repond a « je
  /// suis a quelle altitude » ; a l'echelle du sentier entier elle ne dit rien
  /// du sentier.
  ///
  /// LES DEUX ENSEMBLE OU AUCUN : un compte sans total ne se lit pas. Quand
  /// l'un des deux manque, la case retombe sur l'altitude.
  final int? etapesFaites;

  /// Le nombre total d'etapes du sentier (voir [etapesFaites]).
  final int? etapesTotal;

  /// Vrai quand les chiffres sont ceux du SENTIER ENTIER : ils prennent alors
  /// la teinte [AppTheme.bleuRepos] au lieu de la couleur du sentier.
  final bool vueSentier;

  /// Bascule l'étape vers le sentier entier, et revient. `null` = barre non
  /// tactile (état avant départ : il n'y a qu'un périmètre à montrer).
  final VoidCallback? onBasculer;

  /// La seconde ligne de la barre, SANS sa teinte — qui depend du theme et
  /// n'est connue qu'au `build`.
  ///
  /// SERT A REPONDRE « Y A-T-IL QUELQUE CHOSE A MONTRER ? » hors du `build` et
  /// sans dupliquer la liste des six valeurs : c'est
  /// [ChiffresDeLaBarre.aQuelqueChoseAMontrer] qui en repond, a un seul
  /// endroit. La teinte passee ici n'est jamais celle qui sera affichee ; seul
  /// [_chiffresAvec] construit le widget rendu.
  ChiffresDeLaBarre get _chiffres => _chiffresAvec(AppTheme.bleuRepos);

  /// La seconde ligne de la barre, dans la teinte du perimetre affiche.
  ChiffresDeLaBarre _chiffresAvec(Color accent) => ChiffresDeLaBarre(
    accent: accent,
    showPendingValues: showPendingValues,
    distanceRemainingKm: distanceRemainingKm,
    distanceCoveredKm: distanceCoveredKm,
    avgSpeedKmh: avgSpeedKmh,
    elevationGainM: elevationGainM,
    elevationLossM: elevationLossM,
    altitudeM: altitudeM,
    etapesFaites: etapesFaites,
    etapesTotal: etapesTotal,
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressPercent = (progressRatio * 100).round();
    // LA TEINTE DU PERIMETRE (747) : celle du sentier pour l'etape, un bleu
    // franc pour le sentier entier. Le mot [perimetreLabel] porte le sens ;
    // cette couleur ne fait que le rappeler.
    final primaryColor = vueSentier
        ? AppTheme.bleuRepos
        : theme.colorScheme.primary;

    return GestureDetector(
      // OPAQUE QUAND ELLE EST TACTILE, et seulement alors : la barre entiere
      // devient la cible, y compris au-dessus des six cases, qui sont dans un
      // [IgnorePointer] et ne prendraient donc pas le geste. Les enfants
      // tactiles — le bouton eventuel du [footer] — restent prioritaires :
      // Flutter interroge les enfants avant le parent.
      //
      // SANS BASCULE, ON REVIENT A `deferToChild` : une barre opaque SANS
      // action absorberait les touchers d'une zone ou elle ne fait rien, et
      // c'est exactement ce qui fabrique un geste mort.
      behavior: onBasculer == null
          ? HitTestBehavior.deferToChild
          : HitTestBehavior.opaque,
      onTap: onBasculer,
      child: _corps(context, theme, primaryColor, progressPercent),
    );
  }

  Widget _corps(
    BuildContext context,
    ThemeData theme,
    Color primaryColor,
    int progressPercent,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingMd,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusBottomSheet),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(30),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // LIGNE DU TITRE — ET DESORMAIS CE QUI NE BOUGE PAS (tache 808).
          //
          // LE NOM EST RENDU PAR [TexteAjuste] ET NON PAR UN [Text] NU, et
          // c'est ce qui autorise a le grossir sans risque : il passe de 14 a
          // 18 points, et SI un nom long ne tenait plus, il redescend tout
          // seul — jamais sous 14, la taille qu'il avait avant ce lot. Le
          // bandeau ne peut donc pas devenir moins lisible qu'il ne l'etait,
          // et aucun mot n'est coupe (c'est la regle de la tache 634).
          // LA LIGNE DU TITRE TIENT SUR UNE LIGNE, QUOI QU'ON Y METTE.
          //
          // CE QU'ELLE PORTE DESORMAIS : le nom, la pastille elargie par le
          // total, et — quand le marcheur sort du trace — la puce
          // « Hors trace », elle aussi agrandie. Trois choses sur 360,7 points
          // utiles (mesure faite sur la capture de Christophe : 1080 pixels,
          // rapport 2,75, moins deux fois la marge de 16).
          //
          // LE DEBORDEMENT EST REEL, IL A ETE MESURE. Avec une police dont
          // chaque glyphe occupe un cadratin — le cas du banc de test, mais
          // AUSSI le cas d'un randonneur qui a grossi les textes de son
          // telephone, ce que ce public fait — la rangee debordait de 2,1
          // points et le nom de l'etape etait comprime a ZERO de large. Une
          // [Row] nue ne sait pas faire autrement : elle donne ce qui reste,
          // et quand il ne reste rien, elle deborde.
          //
          // LES DEUX PARADES, ET ELLES SE COMPLETENT :
          //   * LE NOM SE REDUIT PLUTOT QUE DE SE COUPER ([TexteAjuste],
          //     tache 634) : 18 points s'il tient, jamais moins de 14 — la
          //     taille qu'il avait avant ce lot. Sur la capture il demande
          //     245,9 points a 18, et les marqueurs 95,6 : les deux tiennent.
          //   * LES MARQUEURS NE PRENNENT JAMAIS PLUS DE [_partDesMarqueurs]
          //     de la ligne, et se reduisent d'un bloc au-dela. Le nom garde
          //     donc toujours sa part, et plus rien ne peut deborder.
          //
          // UN [Wrap] AURAIT AUSSI EMPECHE LE DEBORDEMENT, et il a ete essaye.
          // Il a ete rejete : il fait TOMBER la pastille a la ligne suivante
          // des que la marge de 15 points manque — or Christophe a demande
          // « passer total AVEC le titre », pas sous le titre.
          LayoutBuilder(
            builder: (context, contraintes) => Row(
              children: [
                Expanded(
                  child: TexteAjuste(
                    stageName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    tailleMin: 14,
                    textAlign: TextAlign.start,
                  ),
                ),
                const SizedBox(width: AppTheme.spacingXs),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: contraintes.maxWidth * _partDesMarqueurs,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // LA PASTILLE DIT LE PERIMETRE **ET SA LONGUEUR**
                        // (tache 808). Le total a quitte le tableau pour venir
                        // ici : il ne bouge pas de toute la marche, et il n'a
                        // de sens que rapporte a ce dont on parle.
                        // « Etape 8,1 km » se lit d'un bloc ; les memes deux
                        // informations separees de dix centimetres d'ecran ne
                        // se lisent pas. La pastille reste le mot qui porte le
                        // sens pour qui distingue mal les couleurs (tache
                        // 747) — elle en porte juste la mesure en plus.
                        if (perimetreLabel != null || totalDistanceKm != null)
                          PastilleDuPerimetre(
                            perimetre: perimetreLabel,
                            // HORS TRACE, LE TOTAL CEDE LA PLACE, et c'est un
                            // arbitrage, pas un oubli. Les trois ne tiennent
                            // pas ensemble sur 360 points : le nom long
                            // s'abregerait. Ordre de ce dont un marcheur a
                            // besoin quand il a quitte le sentier : d'abord
                            // l'avertissement, ensuite le nom du lieu ou il
                            // se trouve, et en dernier une longueur d'etape
                            // qui ne bouge pas et qu'il a deja lue. Le total
                            // revient des qu'il est de nouveau sur la trace.
                            totalDistanceKm: isOffTrack
                                ? null
                                : totalDistanceKm,
                            teinte: primaryColor,
                          ),
                        if (isOffTrack) ...[
                          const SizedBox(width: AppTheme.spacingXs),
                          const PuceHorsTrace(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: AppTheme.spacingSm),

          // LA BARRE ET SON POURCENTAGE SUR LA MEME LIGNE (tache 808).
          //
          // Le pourcentage BOUGE, et la regle de Christophe voudrait donc le
          // mettre au tableau. Il reste ici, et voici pourquoi : il n'est pas
          // une septieme mesure, il est LA LEGENDE DE LA BARRE qu'il touche —
          // les separer rendrait la barre muette et le tableau bavard. Et le
          // tableau doit rester a SIX cases : c'est la forme de la navigation
          // de reference, tranchee par Chris a la tache 558.
          //
          // CE QUE CETTE FUSION RAPPORTE EN PLACE : la ligne « X km restants /
          // Y % » disparait entierement, soit une ligne de texte et son
          // interligne rendus a la carte. En demo, deux bandeaux mangent deja
          // le haut de l'ecran ; cette ligne de moins est ce qui permet au
          // bandeau de tenir sans deborder.
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progressRatio.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppTheme.grisClair,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOffTrack ? AppTheme.emergencyRed : primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                '$progressPercent%',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          // Les SIX chiffres, FORME GR20 (tache 558). Informatifs uniquement.
          if (_chiffres.aQuelqueChoseAMontrer) ...[
            const SizedBox(height: AppTheme.spacingSm),
            const Divider(height: 1),
            const SizedBox(height: AppTheme.spacingSm),
            // Les SIX chiffres, FORME GR20 (tache 558), sortis dans leur
            // propre fichier a la tache 762 (plafond ECR-15). Informatifs
            // uniquement : l'[IgnorePointer] leur interdit de voler un geste
            // a la carte.
            IgnorePointer(child: _chiffresAvec(primaryColor)),
          ],

          // LE BOUTON DE BASCULE, ET IL DIT OU IL MENE (tache 762).
          //
          // HORS DE L'[IgnorePointer] — il doit recevoir les appuis — et APRES
          // les chiffres, parce qu'il parle d'eux.
          //
          // LA BARRE RESTE TACTILE DANS SON ENSEMBLE, et c'est voulu : ce
          // raccourci existe depuis la tache 747, il est verifie par ses
          // gardes, et la recette 753 l'a trouve bon (« la bascule et ses
          // quatre comportements » etait vert). AUCUN DOUBLE DECLENCHEMENT :
          // Flutter interroge les enfants avant le parent, donc un appui sur ce
          // bouton est consomme par lui. Ce que le bouton ajoute n'est pas
          // l'action, c'est le MOT qui la nomme — et une cible franche pour qui
          // ne devine pas qu'une barre de chiffres est tactile.
          if (basculeLabel != null && onBasculer != null) ...[
            const SizedBox(height: AppTheme.spacingXs),
            Align(
              alignment: Alignment.centerRight,
              // [AppButton] ET NON UN `TextButton` BRUT : la garde ECR-19
              // (`aucun_bouton_brut_645_test.dart`) a refuse le bouton brut,
              // a raison — il porterait sa propre taille de cible, son propre
              // contraste et son propre etat, soit une decision d'interface
              // prise a part et une correction d'accessibilite a refaire.
              child: AppButton(
                label: basculeLabel!,
                icon: StepwaysIcons.inverser,
                variant: AppButtonVariant.text,
                tone: primaryColor,
                iconSize: 18,
                onPressed: onBasculer,
              ),
            ),
          ],

          // Ligne d'explication (LOT D) : ce qui démarrera avec la randonnée.
          // Hors [IgnorePointer] — elle peut porter un bouton d'action.
          if (footer != null) ...[
            const SizedBox(height: AppTheme.spacingSm),
            footer!,
          ],
        ],
      ),
    );
  }
}
