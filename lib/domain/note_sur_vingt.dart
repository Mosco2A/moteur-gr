/// LA NOTE SUR VINGT D'UNE JOURNEE : SA PLACE PARMI LES ETAPES OFFICIELLES DU
/// MONDE, et non un rapport a un plafond.
library;

/// LA JAUGE SUR LES RANGS, FIGEE LE 19/10/2026 (tache 860).
///
/// CE QU'ELLE DIT, EN UNE PHRASE : 15 sur 20 = plus dur que les trois quarts
/// des etapes officielles publiees. 20 sur 20 = plus dur que les 106.
///
/// POURQUOI UN RANG ET PAS UNE MAGNITUDE, ET C'EST LE COEUR DU LOT. La jauge
/// precedente etait un rapport au plafond : elle repondait a « quelle fraction
/// du pire cette journee represente-t-elle ». Elle rendait 9,85 pour Calenzana
/// - l'Ortu di u Piobbu, 11,5 km et 1 453 m de montee d'un seul tenant, la plus
/// dure etape du GR20 — un chiffre que personne ne pouvait croire. La raison
/// n'etait pas la magnitude mesuree, qui est juste : c'est que la question
/// posee par un client n'est PAS « quelle fraction du pire » mais « est-ce dur,
/// pour une etape ». La reponse a cette question est un RANG. La meme journee
/// sort a 15,55 sur la jauge des rangs, et ce qui a change n'est pas la mesure,
/// c'est la question.
///
/// ELLE NE LIT QUE L'INDICE, ET AUCUN RANG N'EST RECALCULE A L'EXECUTION. Les
/// bornes ci-dessous sont des CONSTANTES datees. C'est une exigence, pas une
/// optimisation : un rang calcule a la volee sur un corpus vivant deplacerait
/// les notes deja vues par des clients chaque fois qu'un sentier est publie. La
/// note d'une journee ne doit bouger que si la LOI change, jamais si le
/// catalogue grandit.
///
/// LE CORPUS DE CALAGE : [etapesDuCorpus] ETAPES OFFICIELLES PUBLIEES, relevees
/// le [dateDuCalage], toutes sourcees. Composition exacte :
///
///   GR34 Bretagne, decoupage traileasy.com                28 etapes
///   GR70 Stevenson, decoupage chamina                     13 etapes
///   Pennine Way, decoupage trailsplits                    16 etapes
///   Etapes plates et longues, source par ligne             3 etapes
///   Alta Via 1 Dolomites                                  11 etapes
///   Walker's Haute Route                                  13 etapes
///   Candidats au plafond mondial, fiabilite par ligne     22 lignes
///
/// LES 32 JOURNEES DU GR20 ONT ETE RETIREES DU CORPUS, et c'est une correction
/// qu'Athena a faite sur elle-meme : un sentier ne peut pas servir de reference
/// a lui-meme, sinon la note mesure la place du GR20 dans le GR20. Quatre
/// lignes de milieu de gamme sans source ont ete retirees aussi.
///
/// LES DEUX ANCRES DE CHRISTOPHE SONT EXACTES, PAR CONSTRUCTION :
///   - six kilometres de plat valent ZERO ([indiceDuZero], indice 6,000) ;
///   - l'etape la plus dure d'un sentier balise vaut VINGT ([indiceDuVingt],
///     indice 87,485 : Griesalp - Hohturli - Kandersteg sur la Via Alpina 1
///     suisse, 29,6 km et 2 715 m de montee).
///
/// AU-DESSUS DE VINGT, C'EST VINGT. Christophe, verbatim : « Evidemment que 2
/// ou 3 etapes groupee sortent a plus que la plus grosse etape du monde. Et au
/// dessus de 20, cest 20 ». Une journee qui cumule plusieurs etapes depasse
/// MECANIQUEMENT la plus dure etape seule du monde : ce n'est pas une anomalie,
/// c'est ce que fait un marcheur qui groupe. La note s'ecrete, et c'est
/// precisement pour cela que les deux faits qui l'accompagnent — la plus grosse
/// montee continue et le kilometrage — ne sont pas decoratifs : eux ne
/// s'ecretent pas et continuent de distinguer deux journees ecretees.
///
/// CE QU'ON PERD, ET IL FAUT LE SAVOIR : la note n'est plus proportionnelle a
/// l'effort. 18 sur 20 vaut un indice de 50,1 et 9 sur 20 un indice de 32,9,
/// donc 18 ne vaut pas deux fois 9 mais 1,53 fois. Entre deux paliers la jauge
/// reste LINEAIRE EN INDICE, donc proportionnelle a l'interieur d'un decile.
/// Un decile entier d'etapes officielles (indice 6 a 18,2) se partage deux
/// points de note : c'est une perte de RESOLUTION en bas, pas un mensonge, et
/// sa cause est dans le corpus — aucune etape relevee ne tombe entre les
/// indices 6,0 et 10,5, parce que le zero de Christophe est sous le plancher du
/// monde reel.
///
/// FRAGILITE MESUREE : retirer tout le bloc GR34, soit 26 % du corpus, ne
/// deplace la note de l'etape 1 du GR20 que de 0,60 point (15,55 vers 14,95).
/// Un rang ne bouge que si la composition change AUTOUR du point mesure.
abstract final class NoteSurVingt {
  /// La date du relevé du corpus de calage. Elle fait partie de la loi.
  static const String dateDuCalage = '19/10/2026';

  /// Le nombre d'etapes officielles du corpus de calage.
  static const int etapesDuCorpus = 106;

  /// Le nom du plafond mondial du corpus, pour que la note se raconte.
  static const String etapeDuPlafond =
      'Griesalp - Hohturli - Kandersteg (Via Alpina 1, Suisse)';

  /// L'indice qui vaut ZERO : six kilometres de plat (ancre de Christophe).
  static const double indiceDuZero = 6.000;

  /// L'indice qui vaut VINGT : l'etape la plus dure du corpus.
  static const double indiceDuVingt = 87.485;

  /// La note la plus haute : au-dessus, c'est elle.
  static const double noteMaximale = 20.0;

  /// LES ONZE PALIERS DE LA JAUGE — un par decile du corpus, dates du
  /// [dateDuCalage]. Chaque entree est (indice, note) ; la jauge interpole
  /// LINEAIREMENT entre deux paliers consecutifs.
  ///
  /// Strictement croissante sur tout son domaine. Fidelite mesuree : au pire
  /// 0,89 point de note d'ecart au vrai percentile du corpus.
  static const List<(double, double)> paliers = <(double, double)>[
    (indiceDuZero, 0.0),
    (18.224, 2.0),
    (23.068, 4.0),
    (27.971, 6.0),
    (31.223, 8.0),
    (34.475, 10.0),
    (36.391, 12.0),
    (39.736, 14.0),
    (43.403, 16.0),
    (50.051, 18.0),
    (indiceDuVingt, noteMaximale),
  ];

  /// LA NOTE SUR VINGT D'UN INDICE DE TERRAIN.
  ///
  /// Zero en dessous de [indiceDuZero], [noteMaximale] au-dessus de
  /// [indiceDuVingt], interpolation lineaire entre les paliers.
  ///
  /// ELLE NE PREND QUE L'INDICE. Aucun contexte, aucun sentier, aucun
  /// catalogue, aucune date d'execution : deux journees de meme indice ont la
  /// meme note pour toujours.
  static double pourIndice(double indice) {
    if (indice <= indiceDuZero) return 0.0;
    if (indice >= indiceDuVingt) return noteMaximale;
    var (basIndice, basNote) = paliers.first;
    for (final (hautIndice, hautNote) in paliers.skip(1)) {
      if (indice <= hautIndice) {
        final part = (indice - basIndice) / (hautIndice - basIndice);
        return basNote + (hautNote - basNote) * part;
      }
      basIndice = hautIndice;
      basNote = hautNote;
    }
    return noteMaximale;
  }

  /// VRAI quand la note est ECRETEE, c'est-a-dire quand la journee est plus
  /// dure que la plus dure etape officielle connue.
  ///
  /// A afficher, parce qu'une note de 20 qui est un plafond ne dit pas la meme
  /// chose qu'une note de 20 qui tombe pile : la premiere cache un depassement
  /// dont seuls la montee continue et le kilometrage rendent compte.
  static bool estEcretee(double indice) => indice > indiceDuVingt;

  /// L'INDICE QU'IL FAUT POUR ATTEINDRE UNE NOTE — la jauge lue a l'envers.
  ///
  /// Sert a dire ce qu'une note VAUT en terrain (« 18 sur 20, c'est un indice
  /// de 50 »), donc a garder la note explicable. Hors domaine, elle rend les
  /// bornes.
  static double indicePourNote(double note) {
    if (note <= 0) return indiceDuZero;
    if (note >= noteMaximale) return indiceDuVingt;
    var (basIndice, basNote) = paliers.first;
    for (final (hautIndice, hautNote) in paliers.skip(1)) {
      if (note <= hautNote) {
        final part = (note - basNote) / (hautNote - basNote);
        return basIndice + (hautIndice - basIndice) * part;
      }
      basIndice = hautIndice;
      basNote = hautNote;
    }
    return indiceDuVingt;
  }
}
