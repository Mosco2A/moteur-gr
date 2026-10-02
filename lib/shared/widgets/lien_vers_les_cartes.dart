/// Tout lieu physique ouvre les cartes du telephone : une adresse et un point
/// GPS cliquables partout, et non un bouton reinvente par ecran.
library;

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/branding/stepways_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../i18n/translations.g.dart';

/// UN LIEU, UNE ADRESSE, UN POINT QUI OUVRE LES CARTES DU TELEPHONE (tache 641).
///
/// DEMANDE DE CHRISTOPHE DU 30/09 10:23, verbatim : « hebergement il doit avoir
/// une adresse et un point GPS qui link sur Maps », et la generalisation dans le
/// meme retour : « appliquer la meme regle a tout lieu physique (ravitaillement,
/// point d eau, depart/arrivee, transport) : une adresse + un point GPS cliquable
/// partout ou il y a un lieu ». D ou un widget PARTAGE et non un bouton par ecran :
/// une regle qui vaut partout se code une fois.
///
/// LA REGLE QUI GOUVERNE CE FICHIER : PAS DE LIEN MORT. Un lieu sans coordonnees
/// utilisables n affiche AUCUN lien — pas un lien grise, pas un lien qui ouvre une
/// carte du milieu de l ocean. C est le critere de recette du bug 15 : « lieu sans
/// GPS = pas de lien mort, lieu avec GPS = intent Maps ».
///
/// CE QUE « SANS GPS » VEUT DIRE, ET POURQUOI C EST PLUS FIN QUE `null`. Les
/// colonnes `lat`/`lng` de la base ne sont PAS nullables : un lieu sans
/// coordonnees connues y arrive a `0,0` — le point nul de l Atlantique, au large
/// du Ghana. Tester la nullite ne suffit donc pas ; [aUnPoint] teste la validite
/// REELLE des coordonnees, zero compris.
class LieuCliquable {
  const LieuCliquable({required this.nom, this.adresse, this.lat, this.lng});

  /// Nom du lieu, tel qu il sera passe a l application de cartes comme etiquette.
  final String nom;

  /// Adresse postale, si elle est connue.
  final String? adresse;

  /// Latitude, si elle est connue.
  final double? lat;

  /// Longitude, si elle est connue.
  final double? lng;

  /// VRAI SI CE LIEU A UN POINT UTILISABLE.
  ///
  /// `0,0` EST REFUSE, ET CE N EST PAS DU ZELE. C est la valeur qu une colonne non
  /// nullable prend quand la donnee manque, et c est un point reel au large de
  /// l Afrique : un lien vers lui n est pas un lien vide, c est un lien FAUX, qui
  /// enverrait un randonneur consulter une carte de haute mer. Aucun sentier de
  /// randonnee ne passe par la, et si un jour l un y passait, le tort d avoir
  /// exclu un point serait infiniment moindre que celui d en inventer un.
  bool get aUnPoint {
    final latitude = lat;
    final longitude = lng;
    if (latitude == null || longitude == null) return false;
    if (latitude.isNaN || longitude.isNaN) return false;
    if (latitude.abs() > 90 || longitude.abs() > 180) return false;
    if (latitude == 0 && longitude == 0) return false;
    return true;
  }

  /// Vrai si l adresse est renseignee et n est pas un aveu d ignorance.
  ///
  /// LE CONTENU PUBLIE DIT « a completer » QUAND IL NE SAIT PAS, et c est
  /// delibere (regle d honnetete du contenu, tache 641) : une information
  /// introuvable est marquee, pas inventee. Mais ce marqueur est destine a
  /// l editeur, pas au randonneur : l afficher comme une adresse serait remplacer
  /// un vide par du bruit.
  bool get aUneAdresse {
    final valeur = adresse?.trim();
    if (valeur == null || valeur.isEmpty) return false;
    return !_aveuDIgnorance.hasMatch(valeur);
  }

  /// Adresse affichable, ou `null`.
  String? get adresseAffichable => aUneAdresse ? adresse!.trim() : null;

  static final RegExp _aveuDIgnorance = RegExp(
    r'^\s*(a completer|à compléter|to be completed)\s*$',
    caseSensitive: false,
  );

  /// Vrai si ce lieu peut mener quelque part.
  bool get estAtteignable => aUnPoint || aUneAdresse;
}

/// OUVRE UN LIEU DANS L APPLICATION DE CARTES DU TELEPHONE.
///
/// TROIS ADRESSES, ET LE CHOIX N EST PAS COSMETIQUE.
///
///  * iOS — `maps://?q=<nom>&ll=<lat>,<lng>` : le schema de Plans. C est
///    l application de cartes GARANTIE presente sur un iPhone ; viser Google Maps
///    y echouerait chez qui ne l a pas installe.
///  * Android — `geo:<lat>,<lng>?q=<lat>,<lng>(<nom>)` : l intention geo
///    STANDARD. Elle laisse le systeme proposer Google Maps, ou l application de
///    cartes que le randonneur a choisie — ce qui est mieux que de lui imposer
///    la notre.
///  * Ailleurs, et en dernier recours partout — `https://www.google.com/maps/...`
///    Une URL web s ouvre TOUJOURS, ne serait-ce que dans un navigateur.
///
/// LE REPLI EN CHAINE EST LE POINT. Un schema natif peut echouer pour une raison
/// qu on ne controle pas : aucune application declaree pour `geo:`, canal de
/// plateforme absent (c est le cas dans les tests de widget), utilisateur qui a
/// desinstalle Plans. On essaie donc le natif, PUIS le web — plutot que de rendre
/// « impossible d ouvrir » alors qu un navigateur aurait suffi.
///
/// L ADRESSE PRIME SUR LE POINT QUAND ELLE EXISTE, et c est le cas pour la moitie
/// des gites du Mare a Mare. Leurs coordonnees publiees sont celles du CENTRE DU
/// VILLAGE, pas de la porte du gite : c est dit dans la donnee. Une recherche
/// d adresse chez Google ou Apple tombe sur la bonne porte ; un point tombe au
/// milieu du village. Quand les deux existent on donne les deux au systeme —
/// l etiquette de recherche ET le point — et il fait au mieux.
class OuvreurDeCartes {
  const OuvreurDeCartes();

  /// Ouvre [lieu]. Rend `false` si rien n a pu etre ouvert — JAMAIS d exception.
  ///
  /// La lecon est celle de la tache 579 : `canLaunchUrl` et `launchUrl` LEVENT des
  /// que le canal de plateforme n est pas la. Une exception qui traverse l ecran
  /// saute le message d echec, et le bouton ne produit RIEN — ni carte, ni
  /// explication.
  Future<bool> ouvrir(LieuCliquable lieu) async {
    for (final uri in adressesPour(lieu)) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          return true;
        }
      } on Object {
        // On passe a l adresse suivante : un schema non gere n est pas un echec
        // du geste, c est un echec de CE schema.
        continue;
      }
    }
    return false;
  }

  /// Les adresses a essayer, dans l ordre. Publique parce qu elle est TESTEE
  /// SEULE : c est la seule partie de ce fichier qu un test de widget peut
  /// verifier sans canal de plateforme.
  static List<Uri> adressesPour(LieuCliquable lieu) {
    final etiquette = Uri.encodeComponent(lieu.adresseAffichable ?? lieu.nom);
    final adresses = <Uri>[];

    if (lieu.aUnPoint) {
      final point = '${lieu.lat},${lieu.lng}';
      if (!kIsWeb && Platform.isIOS) {
        adresses.add(Uri.parse('maps://?q=$etiquette&ll=$point'));
      } else if (!kIsWeb && Platform.isAndroid) {
        adresses.add(Uri.parse('geo:$point?q=$point($etiquette)'));
      }
      // LA REQUETE WEB PART SUR L ADRESSE QUAND ELLE EXISTE, SUR LE POINT SINON.
      //
      // CE N EST PAS UNE PREFERENCE, C EST CE QUE DIT LA DONNEE. Les coordonnees
      // publiees de la moitie des gites du Mare a Mare sont celles du CENTRE DU
      // VILLAGE — le contenu le dit explicitement — pas de la porte du gite. Une
      // recherche d adresse tombe sur la porte ; un point tombe au milieu du
      // village, a cinq minutes de marche pres, de nuit, avec un sac. Les schemas
      // natifs ci-dessus emportent DEJA les deux (etiquette et point) et c est
      // l application de cartes qui arbitre ; ici il faut choisir, et on choisit
      // ce que l humain a ecrit.
      adresses.add(
        Uri.parse(
          'https://www.google.com/maps/search/?api=1&query='
          '${lieu.aUneAdresse ? etiquette : point}',
        ),
      );
    } else if (lieu.aUneAdresse) {
      // PAS DE POINT, MAIS UNE ADRESSE : on la fait chercher. C est la difference
      // entre « je ne sais pas ou c est » et « je sais l ecrire mais pas la
      // pointer », et la seconde merite un lien.
      if (!kIsWeb && Platform.isIOS) {
        adresses.add(Uri.parse('maps://?q=$etiquette'));
      }
      adresses.add(
        Uri.parse('https://www.google.com/maps/search/?api=1&query=$etiquette'),
      );
    }

    return adresses;
  }
}

/// L ouvreur de cartes, surchargeable en test.
final ouvreurDeCartesProvider = Provider<OuvreurDeCartes>(
  (ref) => const OuvreurDeCartes(),
);

/// L ADRESSE ET LE POINT D UN LIEU, TELS QUE LE RANDONNEUR LES VOIT.
///
/// UN SEUL WIDGET POUR TOUS LES LIEUX (hebergement, ravitaillement, point d eau,
/// arret de transport, depart et arrivee d etape), parce que Christophe a demande
/// une REGLE et pas une correction d ecran.
///
/// CE QU IL N AFFICHE PAS EST AUSSI IMPORTANT QUE CE QU IL AFFICHE. Lieu sans
/// adresse ni point : le widget rend un `SizedBox.shrink()` — pas un libelle vide,
/// pas un bouton inerte. C est la regle du bug 15, et c est aussi celle du bug 4 :
/// ce qui est cliquable et ce qui ne l est pas doivent se distinguer, donc un lien
/// qui ne mene nulle part ne doit pas AVOIR l air d un lien.
class LigneDeLieu extends ConsumerWidget {
  const LigneDeLieu({super.key, required this.lieu, this.compact = false});

  /// Le lieu a montrer.
  final LieuCliquable lieu;

  /// Forme resserree, pour une liste dense.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!lieu.estAtteignable) return const SizedBox.shrink();

    // LE `t` GLOBAL DE SLANG, PAS `Translations.of(context)`, ET C EST UNE
    // CONTRAINTE MESUREE. Ce widget est pose dans des ecrans dont les tests ne
    // montent PAS de `TranslationProvider` — la fiche d etape, par exemple.
    // `Translations.of(context)` y leve « Please wrap your app with
    // TranslationProvider » pendant le build, ce qui rend un ecran rouge en test
    // et un ecran NOIR en release. Le depot utilise deja les deux formes ; pour
    // un widget PARTAGE, seule celle qui ne depend d aucun ancetre est correcte.
    final adresse = lieu.adresseAffichable;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (adresse != null)
          Padding(
            padding: EdgeInsets.only(bottom: compact ? 2 : 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StepIcon(
                  StepwaysIcons.repere,
                  size: compact ? 14 : 16,
                  color: AppTheme.grisGranite,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    adresse,
                    key: const ValueKey('lieu-adresse'),
                    style:
                        (compact
                                ? Theme.of(context).textTheme.bodySmall
                                : Theme.of(context).textTheme.bodyMedium)
                            ?.copyWith(color: AppTheme.grisGranite),
                  ),
                ),
              ],
            ),
          ),
        if (lieu.aUnPoint || adresse != null)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey('lieu-ouvrir-cartes'),
              onPressed: () => _ouvrir(context, ref),
              icon: StepIcon(
                StepwaysIcons.carte,
                size: compact ? 16 : 18,
                color: AppTheme.actionStart,
              ),
              label: Text(
                t.lieu.ouvrirDansLesCartes,
                style: TextStyle(
                  color: AppTheme.actionStart,
                  fontWeight: FontWeight.w600,
                  fontSize: compact ? 13 : null,
                ),
              ),
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: compact ? 2 : 6,
                ),
                minimumSize: const Size(0, 36),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _ouvrir(BuildContext context, WidgetRef ref) async {
    final messager = ScaffoldMessenger.maybeOf(context);
    final ouvert = await ref.read(ouvreurDeCartesProvider).ouvrir(lieu);
    if (ouvert || messager == null) return;
    // L ECHEC SE DIT. Un geste qui ne produit rien et ne dit rien est pire qu un
    // bouton absent : le randonneur ne sait pas s il a mal appuye.
    messager.showSnackBar(SnackBar(content: Text(t.lieu.cartesIndisponibles)));
  }
}
