/// L effort d une etape, son verdict, le score du circuit et les
/// conseils de programme.
///
/// Bibliotheque de la formule de faisabilite (lot 645-06b), re-exportee par
/// `feasibility_formula.dart` : les appelants n'importent que cette racine.
library;

import 'feasibility_types.dart';

/// Geometrie d'une etape — DONNEE BRUTE, sans unite d'energie.
///
/// L'energie n'est PAS un attribut de l'etape : elle depend du bareme
/// ([FeasibilityScale]). Mettre `effortKm` ici, comme le faisait la V1, revenait
/// a graver l'unite dans la donnee et rendait toute comparaison AVANT/APRES
/// impossible.
class StageEffort {
  const StageEffort({
    required this.index,
    required this.name,
    required this.distanceKm,
    required this.elevationGainM,
    this.elevationLossM = 0,
  });

  /// Index 0-based de l'etape dans la sequence.
  final int index;

  /// Nom de l'etape (affichage).
  final String name;

  /// Distance de l'etape (km).
  final double distanceKm;

  /// Denivele positif de l'etape (m).
  final int elevationGainM;

  /// Denivele NEGATIF de l'etape (m). N'entre PAS dans le score (#1-d, #M05) :
  /// il sert au classement des etapes de l'alerte descente du dispositif poids
  /// (#4-l), qui n'invente aucun seuil.
  final int elevationLossM;
}

/// Verdict d'une etape : son energie, son score, sa couleur, son facteur
/// dominant.
class StageVerdict {
  const StageVerdict({
    required this.stage,
    required this.energyKm,
    required this.capacityKm,
    required this.score,
    required this.verdict,
    required this.distanceShare,
    required this.elevationShare,
    required this.altitudeShare,
    required this.heatShare,
  });

  /// L'etape evaluee (geometrie brute).
  final StageEffort stage;

  /// Energie de l'etape dans le bareme applique (km-energie).
  final double energyKm;

  /// Capacite du jour appliquee a cette etape (km-energie).
  final double capacityKm;

  /// score = energie_etape / capacite_jour (>= 0).
  final double score;

  /// Verdict tricolore de l'etape.
  final FeasibilityVerdict verdict;

  /// DECOMPOSITION EXACTE DU SCORE en quatre parts additives (#2-l).
  ///
  /// distance + denivele + chaleur + altitude = score, a l'exactitude machine
  /// pres. Demonstration : score = E/(B·ka·kh) avec E = d + g/u et B la base ;
  /// la part distance vaut d/B, la part denivele (g/u)/B, la part chaleur
  /// E/B·(1/kh − 1), la part altitude E/B·(1/(ka·kh) − 1/kh). Leur somme se
  /// telescope exactement en E/(B·ka·kh).
  final double distanceShare;

  /// Part du denivele positif dans le score (voir [distanceShare]).
  final double elevationShare;

  /// Part de l'altitude dans le score (voir [distanceShare]).
  final double altitudeShare;

  /// Part de la chaleur dans le score (voir [distanceShare]).
  final double heatShare;

  /// Vrai si l'etape depasse le plafond (orange ou rouge -> « au-dessus »).
  bool get isOverCapacity => verdict != FeasibilityVerdict.green;

  /// Facteur DOMINANT de l'etape : la plus grosse des quatre parts (#2-l).
  LimitingFactor get dominantFactor {
    var best = LimitingFactor.distance;
    var bestShare = distanceShare;
    if (elevationShare > bestShare) {
      best = LimitingFactor.elevation;
      bestShare = elevationShare;
    }
    if (altitudeShare > bestShare) {
      best = LimitingFactor.altitude;
      bestShare = altitudeShare;
    }
    if (heatShare > bestShare) {
      best = LimitingFactor.heat;
      bestShare = heatShare;
    }
    return best;
  }
}

/// SCORE DE CIRCUIT (#2-m a #2-t).
///
/// Chaque contrainte est normalisee par son PROPRE seuil publie et vaut 1,0 a
/// sa limite ; le score du circuit est la contrainte qui mord. Aucun poids
/// n'est choisi, donc aucun poids n'est a justifier.
class CircuitScore {
  const CircuitScore({
    required this.worstStage,
    required this.averageLoad,
    required this.rest,
    required this.habitGap,
    required this.monotony,
    required this.monotonyWindowStartDay,
    required this.monotonyWindowEndDay,
    required this.totalDays,
    required this.score,
    required this.dominant,
    required this.verdict,
  });

  /// C1 — le score de la pire etape (#2-n).
  final double worstStage;

  /// C2 — (Σ energie) ÷ (jours de marche × capacite du jour) (#2-o).
  ///
  /// AFFICHEE, JAMAIS DECISIVE — et ce n'est pas un choix de confort, c'est une
  /// demonstration. C2 est une MOYENNE et C1 le MAXIMUM de la meme serie
  /// normalisee par le meme plafond : `C2 <= C1` par construction, toujours.
  /// `max(C1 ; C2 ; C3)` valait donc identiquement `max(C1 ; C3)` ; C2 a ete
  /// sortie du maximum pour que l'ecriture soit honnete, sans que la sortie du
  /// moteur change d'un chiffre.
  ///
  /// ELLE RESTE CALCULEE PARCE QU'ELLE INFORME REELLEMENT : un trek a maximum
  /// 1,05 et moyenne 0,50 a UNE journee dure ; un trek a maximum 1,05 et
  /// moyenne 1,00 est dur TOUS LES JOURS. Aucune autre grandeur du modele ne
  /// porte cette distinction.
  final double averageLoad;

  /// C3 — monotonie ÷ 2,0 (#2-p). `null` quand elle N'EST PAS CALCULABLE : sur
  /// un sentier d'UNE etape, l'ecart-type d'une seule charge vaut zero et la
  /// monotonie diverge. Une contrainte non calculable est DECLAREE non
  /// applicable, elle n'est jamais remplacee par un chiffre (#10-e).
  ///
  /// AFFICHEE ET CONSEILLEE, JAMAIS DECISIVE depuis GO-61 (22/09). Elle rejoint
  /// C2 et C4 dans les grandeurs informatives : le seuil de 2,0 est une
  /// EXTRAPOLATION declaree (#M08, athletes en entrainement), et la regle du
  /// projet est que ce qui n'est pas source s'affiche mais ne decide pas. Voir
  /// [score] pour la demonstration complete.
  final double? rest;

  /// C4 — charge journaliere du trek ÷ charge journaliere deja realisee
  /// (#2-q). AFFICHE, JAMAIS DECISIF (#S16-b Impellizzeri 2020 : aucune preuve
  /// causale). `null` si aucune habitude chiffree n'est connue.
  final double? habitGap;

  /// Monotonie de Foster brute (moyenne ÷ ecart-type de population) de la PIRE
  /// fenetre. `null` si non calculable.
  final double? monotony;

  /// Premier jour (1-based) de la fenetre de monotonie retenue, `null` si non
  /// calculable.
  final int? monotonyWindowStartDay;

  /// Dernier jour (1-based) de la fenetre de monotonie retenue.
  final int? monotonyWindowEndDay;

  /// Nombre TOTAL de jours du programme (marche + repos) : c'est lui qui dit si
  /// la fenetre retenue couvre le trek entier ou seulement une de ses semaines.
  final int totalDays;

  /// S_circuit = C1, LA PIRE ETAPE, ET ELLE SEULE (GO-61 du 22/09).
  ///
  /// C2, C3 et C4 sont TOUTES EN INFORMATION. Le chemin jusque-la, en deux
  /// temps : C2 est sortie du maximum parce qu'une moyenne ne peut pas depasser
  /// le maximum de la meme serie (elle ne decidait donc jamais) ; C3 en est
  /// sortie a son tour parce qu'elle etait la SEULE contrainte EXTRAPOLEE du
  /// modele (#M08 : seuil de Foster etabli sur des athletes EN ENTRAINEMENT,
  /// transfere a l'itinerance) et la seule a laquelle on avait laisse le droit
  /// de mettre au rouge — en contradiction avec la regle du projet, ce qui
  /// n'est pas source s'affiche mais ne decide pas.
  ///
  /// CE QUI A EMPORTE LA DECISION, MESURE SUR LE PRODUIT REEL : 24 cellules sur
  /// 24 au rouge par le seul fait qu'aucun jour de repos n'etait pose, DONT un
  /// profil confirme dont la pire etape est a 0,68 — vert franc. Et un defaut
  /// mathematique par-dessus : la monotonie vaut moyenne ÷ ecart-type, donc
  /// PLUS LES ETAPES SONT REGULIERES PLUS ELLE GRIMPE ; un randonneur qui
  /// enchaine sept jours bien calibres etait puni PARCE QUE son itineraire
  /// etait regulier.
  ///
  /// CONTREPARTIE ASSUMEE, ET ELLE EST REELLE : plus aucun mecanisme ne rend un
  /// circuit plus severe que sa pire etape. ARB-004 (#2-s) n'a plus rien pour
  /// le porter, et l'exemple des dix-sept jours d'affilee est DIT a l'ecran
  /// (constat de duree) et non JUGE. C'est le prix de n'inventer aucun chiffre
  /// sur un sujet de securite en montagne : aucune source publiee ne chiffre la
  /// fatigue cumulee en randonnee itinerante (trou #M15).
  final double score;

  /// La contrainte qui porte [score].
  ///
  /// VAUT DESORMAIS TOUJOURS [worstStage] : depuis GO-61, S_circuit = C1 et
  /// aucune autre contrainte n'entre dans le maximum. Le champ est CONSERVE
  /// parce qu'il rend la propriete VERIFIABLE — la campagne et les tests
  /// verrouillent « la dominante ne peut etre que C1 », ce qui casserait au
  /// premier recablage d'une contrainte informative dans le verdict.
  final CircuitConstraint dominant;

  /// Verdict tricolore du circuit (memes seuils que les etapes).
  final FeasibilityVerdict verdict;

  /// Vrai si la contrainte repos n'a pas pu etre calculee (#10-e).
  bool get isRestApplicable => rest != null;

  /// Vrai si la fenetre de monotonie couvre le trek ENTIER (programme de 7 jours
  /// ou moins) — et non une semaine choisie parmi d'autres.
  bool get monotonyCoversWholeTrek =>
      monotonyWindowStartDay == 1 && monotonyWindowEndDay == totalDays;
}

/// Un conseil de programme (cle i18n + parametres nommes pour l'affichage).
///
/// Le moteur ne fabrique PAS de phrase : il produit une cle stable + les
/// nombres. L'UI compose le texte via Slang (accents FR garantis cote i18n).
class ProgramAdvice {
  const ProgramAdvice({required this.key, this.params = const {}});

  /// Cle i18n stable (`t.feasibility.formula.advice.*`).
  final String key;

  /// Parametres nommes injectes dans le texte i18n (ex. {days: 8}).
  final Map<String, Object> params;
}

/// LE CONSEIL DE DUREE, TROUVE PAR ESSAI REEL (tache 569, R1).
///
/// POURQUOI CETTE VALEUR ENTRE DANS LE MOTEUR AU LIEU D'EN SORTIR. Le nombre de
/// jours a conseiller ne peut pas etre calcule ici : il depend du MOTEUR DE
/// REPARTITION (`PlanningCalculator`), qui regroupe et coupe les etapes, et le
/// domaine de la formule ne connait pas les etapes du sentier — il ne voit que
/// des charges deja journalieres. Toute tentative de le deviner d'ici a produit
/// le defaut que Chris a vu : une formule de MOYENNE qui conseillait une valeur
/// dont le MAXIMUM — donc le verdict — etait rouge.
///
/// Le conseil est donc cherche a l'exterieur ([ProgramPlanSearch.firstNonRed]),
/// en construisant le vrai programme a chaque valeur du curseur et en le passant
/// a [FeasibilityFormula.evaluate], puis INJECTE ici. Les deux calculs ne peuvent
/// plus diverger : il n'y en a plus qu'un.
class ProgramDurationAdvice {
  const ProgramDurationAdvice({
    required this.walkingDays,
    required this.restDays,
  });

  /// AUCUNE DUREE N'EST CONSEILLABLE : la recherche a essaye toutes les valeurs
  /// du curseur et toutes sont rouges (une etape indivisible au-dessus du
  /// plafond, meme coupee en deux). L'application ne conseille alors RIEN et le
  /// dit franchement — mieux vaut avouer qu'il n'y a pas de solution de
  /// programme que d'en pointer une fausse.
  static const impossible = ProgramDurationAdvice(walkingDays: 0, restDays: 0);

  /// Jours de MARCHE du programme conseille.
  final int walkingDays;

  /// Jours de REPOS du programme conseille.
  final int restDays;

  /// LA DUREE DU PLAN — les jours de MARCHE, et eux seuls.
  ///
  /// DECISION DE CHRISTOPHE DU 30/09 12:37 (DEM-260930-1238), verbatim : « les
  /// jours de repos, ca ne presage que de l enchainement pas de la capacite a
  /// faire les etapes suivantes. On peut mettre en conseil de prendre n jours de
  /// repos c est tout. Si c est 7 jours c est 7 jours ».
  ///
  /// CE QUI SE PASSAIT, ET POURQUOI C'ETAIT FAUX POUR LUI. Le conseil s'ecrivait
  /// en jours TOTAUX, repos compris : le Mare a Mare Centre, sept etapes, etait
  /// donc annonce « en 9 jours ». Or le sentier fait SEPT jours — c'est ce que dit
  /// le topo, c'est ce que le randonneur a en tete, et lui annoncer autre chose
  /// lui donne l'impression qu'on lui refait son itineraire.
  ///
  /// LE REPOS N'A PAS DISPARU, IL A CHANGE DE STATUT : il reste CONSEILLE
  /// ([restDays], « nous conseillons n jours de repos »), il n'est plus COMPTE
  /// dans la duree du plan. C'est coherent avec ce que le moteur fait deja depuis
  /// GO-61 : le repos est affiche et conseille, il ne decide JAMAIS du verdict.
  int get planDays => walkingDays;

  /// Jours totaux, marche PLUS repos — valeur INFORMATIVE.
  ///
  /// Ce n'est PAS la duree du plan (voir [planDays]) : ne pas l'employer pour
  /// annoncer une duree ni pour regler le curseur.
  int get totalDays => walkingDays + restDays;

  /// Vrai quand une duree est reellement conseillee.
  bool get isViable => walkingDays > 0;
}
