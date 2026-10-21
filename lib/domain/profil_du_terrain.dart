/// LE PROFIL D'UN SENTIER : la suite des morceaux de terrain sur lesquels
/// l'indice s'integre, prise sur LA trace et sur rien d'autre.
library;

import 'dart:math' as math;

/// UN MORCEAU DE TERRAIN : une longueur, un denivele, un point kilometrique.
///
/// C'est l'unite sur laquelle le facteur de pente s'applique. Un morceau
/// mesure environ cent quarante metres sur le GR20 (sept points de trace), et
/// cette taille n'est pas choisie ici : c'est celle de l'echantillonnage qui
/// produit le denivele AFFICHE du sentier ([ProfilDuTerrain.depuisLaTrace]).
class SegmentDeProfil {
  /// Construit un morceau de terrain mesure.
  const SegmentDeProfil({
    required this.pkDebutM,
    required this.longueurM,
    required this.deniveleM,
  });

  /// Point kilometrique du debut du morceau, en metres depuis la tete de
  /// sentier.
  final double pkDebutM;

  /// Longueur du morceau sur la CARTE, en metres (distance cumulee de la
  /// trace).
  final double longueurM;

  /// Variation d'altitude du morceau, en metres : positive en montee, negative
  /// en descente.
  final double deniveleM;

  /// Point kilometrique de la fin du morceau, en metres.
  double get pkFinM => pkDebutM + longueurM;

  /// La pente du morceau, en fraction (0,10 = 10 %).
  double get pente => deniveleM / longueurM;

  /// LA LONGUEUR REELLEMENT PARCOURUE, en metres : l'hypotenuse, pas la base.
  ///
  /// POURQUOI CE N'EST PAS UN RAFFINEMENT. Le cout mesure par Minetti est un
  /// cout par metre de TAPIS INCLINE, donc par metre reellement parcouru. Sur
  /// le GR20 l'ecart entre les deux longueurs vaut 2,6 % de l'indice total :
  /// 395,3 points contre 385,5. Prendre la longueur de la carte
  /// sous-facturerait
  /// tout le sentier, et d'autant plus qu'il est raide.
  double get longueurDeTrajetM =>
      math.sqrt(longueurM * longueurM + deniveleM * deniveleM);

  /// VRAI quand ce morceau monte. Un morceau parfaitement plat ne monte pas.
  bool get monte => deniveleM > 0;

  /// Ce meme morceau, reduit a la fraction [part] de sa longueur.
  ///
  /// LA PENTE NE BOUGE PAS : longueur et denivele sont reduits ensemble. C'est
  /// ce qui rend le socle mesure EXACTEMENT additif ou qu'on coupe — couper un
  /// morceau en deux rend deux morceaux de meme pente dont les couts
  /// s'additionnent au cout du tout, a la precision de la machine pres.
  SegmentDeProfil fraction({required double depuisM, required double part}) =>
      SegmentDeProfil(
        pkDebutM: depuisM,
        longueurM: longueurM * part,
        deniveleM: deniveleM * part,
      );
}

/// LE PROFIL ENTIER D'UN SENTIER, LU SUR SA TRACE (tache 858).
///
/// POURQUOI L'INDICE A BESOIN DE CA ET PAS DE TROIS CHIFFRES. Un indice de
/// terrain adosse a l'energie est une INTEGRALE sur le profil : il ne se deduit
/// pas de (distance, D+, D-), parce que mille metres de montee a 10 % et mille
/// metres a 30 % n'ont ni la meme longueur ni le meme cout. C'est la difference
/// de fond avec le kilometre-effort de la tache 852, qui ne lisait que les
/// trois totaux — et qui pour cette raison cotait presque pareil la journee qui
/// grimpe 1 454 m et celle qui les descend.
///
/// LE PROFIL NE DEPEND QUE DU SENTIER. Aucun poids de sac, aucune allure,
/// aucune propriete du marcheur n'entre ici, et c'est la premiere des deux
/// couches : l'indice decrit le TERRAIN et il est le meme pour tout le monde.
class ProfilDuTerrain {
  /// Construit un profil depuis ses morceaux (ordonnes par point
  /// kilometrique).
  const ProfilDuTerrain(this.segments);

  /// Aucun profil disponible pour ce sentier.
  static const ProfilDuTerrain vide = ProfilDuTerrain(<SegmentDeProfil>[]);

  /// LA FENETRE DE LISSAGE DU PROFIL : SEPT POINTS.
  ///
  /// Elle n'est pas choisie ici. C'est celle de `tool/mesurer_les_etapes.py`,
  /// qui produit le denivele ANNONCE de chaque etape, et elle est calibree sur
  /// un chiffre publie independant : la trace du Mare a Mare Centre rend
  /// 4 263 m de montee quand le topoguide de ce sentier publie 4 274 m
  /// (memoire #101703). Un profil brut rendrait 15 237 m sur le GR20 au lieu
  /// de 11 602 : c'est le bruit du modele d'altitude, pas de la montagne.
  static const int fenetreDeLissage = 7;

  /// UN POINT SUR SEPT APRES LISSAGE — le meme pas que le denivele affiche.
  ///
  /// Garder les 9 128 points du GR20 apres lissage recomptererait le bruit que
  /// le lissage vient d'enlever. Ce pas est celui de la mesure publiee : c'est
  /// ce qui fait que l'indice et le denivele annonce decrivent LE MEME terrain.
  static const int pasDEchantillonnage = 7;

  /// Les morceaux de terrain, dans l'ordre de la trace.
  final List<SegmentDeProfil> segments;

  /// Vrai quand le sentier n'offre aucun profil (aucune trace altimetrisee).
  bool get estVide => segments.isEmpty;

  /// Longueur profilee, en metres.
  double get longueurM => segments.isEmpty ? 0.0 : segments.last.pkFinM;

  /// LE PROFIL D'UNE TRACE : lissage sur [fenetreDeLissage] points, puis un
  /// point sur [pasDEchantillonnage].
  ///
  /// [distancesM] est la distance cumulee de chaque point de la trace depuis la
  /// tete de sentier ; [altitudesM] son altitude. Les deux listes ont la meme
  /// longueur et sont dans l'ordre de la trace.
  ///
  /// CE QUE CETTE METHODE REPRODUIT, VOLONTAIREMENT A L'IDENTIQUE : la mesure
  /// de `tool/mesurer_les_etapes.py`. Sur la trace du GR20 elle rend 11 602 m
  /// de montee et 183,58 km, les deux chiffres que l'application AFFICHE deja.
  /// Un profil qui ne rendrait pas ces chiffres-la ferait vivre deux sentiers
  /// differents dans le meme ecran.
  ///
  /// LA QUEUE PLUS COURTE QUE LE PAS N'EST PAS PROFILEE, et c'est la convention
  /// de la mesure publiee : sur le GR20, les six derniers points de la trace,
  /// soit cent vingt metres sur cent quatre-vingt-trois kilometres.
  static ProfilDuTerrain depuisLaTrace({
    required List<double> distancesM,
    required List<double> altitudesM,
  }) {
    final n = math.min(distancesM.length, altitudesM.length);
    if (n < 2) return vide;
    final lisses = _lisser(altitudesM, n);
    final segments = <SegmentDeProfil>[];
    for (var i = 0; i + pasDEchantillonnage < n; i += pasDEchantillonnage) {
      final j = i + pasDEchantillonnage;
      final longueur = distancesM[j] - distancesM[i];
      if (longueur <= 0) continue;
      segments.add(
        SegmentDeProfil(
          pkDebutM: distancesM[i],
          longueurM: longueur,
          deniveleM: lisses[j] - lisses[i],
        ),
      );
    }
    return ProfilDuTerrain(List<SegmentDeProfil>.unmodifiable(segments));
  }

  /// LE MEME SENTIER, MARCHE DANS L'AUTRE SENS.
  ///
  /// L'ordre des morceaux s'inverse ET LA PENTE DE CHACUN CHANGE DE SIGNE : un
  /// sentier descendu n'est pas un sentier monte, et il ne suffit donc pas de
  /// retourner une liste. C'est l'ecart le plus parlant de tout ce lot — la
  /// premiere journee du GR20 vaut 50,0 de Calenzana vers l'Ortu di u Piobbu et
  /// 10,5 dans l'autre sens, pour le meme chemin. Les points kilometriques se
  /// comptent depuis l'autre bout.
  ProfilDuTerrain get aLEnvers {
    final total = longueurM;
    return ProfilDuTerrain(
      List<SegmentDeProfil>.unmodifiable(<SegmentDeProfil>[
        for (final segment in segments.reversed)
          SegmentDeProfil(
            pkDebutM: total - segment.pkFinM,
            longueurM: segment.longueurM,
            deniveleM: -segment.deniveleM,
          ),
      ]),
    );
  }

  /// LES MORCEAUX DE TERRAIN ENTRE DEUX POINTS KILOMETRIQUES, au prorata aux
  /// bords.
  ///
  /// Un morceau coupe par une borne est reduit a sa fraction utile, a PENTE
  /// INCHANGEE ([SegmentDeProfil.fraction]) : c'est ce qui donne a l'indice son
  /// additivite exacte hors montee. Une journee de marche est exactement cela —
  /// la tranche du profil entre deux couchages.
  List<SegmentDeProfil> tranche({
    required double pkDebutM,
    required double pkFinM,
  }) {
    final retenus = <SegmentDeProfil>[];
    for (final segment in segments) {
      final debut = math.max(segment.pkDebutM, pkDebutM);
      final fin = math.min(segment.pkFinM, pkFinM);
      if (fin <= debut) continue;
      final part = (fin - debut) / segment.longueurM;
      retenus.add(
        part >= 1.0 ? segment : segment.fraction(depuisM: debut, part: part),
      );
    }
    return List<SegmentDeProfil>.unmodifiable(retenus);
  }

  /// Moyenne glissante centree sur [fenetreDeLissage] points.
  static List<double> _lisser(List<double> altitudes, int n) {
    const demi = fenetreDeLissage ~/ 2;
    final lisses = List<double>.filled(n, 0.0);
    for (var i = 0; i < n; i++) {
      final debut = math.max(0, i - demi);
      final fin = math.min(n, i + demi + 1);
      var somme = 0.0;
      for (var k = debut; k < fin; k++) {
        somme += altitudes[k];
      }
      lisses[i] = somme / (fin - debut);
    }
    return lisses;
  }
}
