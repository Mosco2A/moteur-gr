/// MOTEUR DE FAISABILITE V2 (StepWays) — spec finale
/// `data/apport_stepways/SPEC_FINALE_faisabilite_et_poids.md` (#SW-FINAL),
/// qui PRIME sur tout autre document. Arbitrages tranches par Chris le
/// 22/09/2026 (#100303 a #100320), synthese #100332.
///
/// Moteur PUR (zero dependance Flutter), entierement testable a l'unite. Il
/// croise l'ENERGIE de chaque etape a la CAPACITE journaliere du randonneur et
/// rend un verdict FEU TRICOLORE par etape, un SCORE DE CIRCUIT, et des
/// conseils de programme.
///
/// CE QUI CHANGE PAR RAPPORT A LA V1, ET POURQUOI.
///
///  1. L'UNITE (#1-a, #2-a). La V1 convertissait 100 m de D+ en 1 km de plat.
///     La mesure de Minetti 2002 (cout metabolique de la marche en pente, en
///     joules par kilo et par metre) donne 42 m, contre-verifiee par deux voies
///     convergentes (39-42). Les plafonds sont RE-DERIVES sur les memes reperes
///     BP, ils ne sont pas re-choisis : 25,1 / 38,7 / 55,6 / 65,7 au lieu de
///     21 / 29 / 39 / 45.
///
///  2. AUCUN TERME DE MASSE (#1-b, #3-d). Ni le sac, ni le poids du corps
///     n'entrent dans le score. Ce n'est pas un trou, c'est une propriete
///     assumee : le cout d'une etape vaut pente x distance x masse, la capacite
///     est deduite d'une performance geometrique passee du MEME corps, la masse
///     se simplifie exactement. Le meme homme a 65 ou 95 kg obtient le meme
///     verdict au chiffre pres. Le poids a sa place ailleurs, dans le dispositif
///     de charge ([BodyWeightReference]).
///
///  3. LE PLANCHER DEMONTRE (#2-g). On ne dit jamais a quelqu'un qu'il ne peut
///     pas faire ce qu'il a deja demontre faire : la capacite de base est le
///     MAXIMUM entre le plafond de son niveau et sa meilleure journee reelle.
///     L'ORDRE COMPTE (#2-e) : le plancher s'applique a la BASE, les conditions
///     ENSUITE — l'ordre inverse effacerait silencieusement l'altitude et la
///     chaleur pour tout randonneur dont le maximum demontre depasse son cran.
///
///  4. LES CONDITIONS (#2-h, #2-i, #2-j). Altitude (MOVE 2026) et chaleur
///     (Linsell 2020) multiplient la capacite. Printemps et automne : AUCUNE
///     source, donc neutres, et on le dit. Hiver : AUCUN coefficient, le verdict
///     est DECLARE NON VALIDE (les cotations du Club Alpin Suisse ne valent que
///     par bon temps et terrain sec).
///
///  5. LE SCORE DE CIRCUIT (#2-m a #2-t). On ne pondere rien : chaque contrainte
///     est normalisee par son propre seuil publie — elle vaut 1,0 a sa limite —
///     et le score est la contrainte qui mord. Aucun poids a choisir.
///
/// CE QUI N'EST PAS DANS LE MOTEUR, ET POURQUOI (trous declares, non combles) :
/// pas de terme de descente (#1-d, #M05 : aucun coefficient energetique publie —
/// l'alerte est portee par le dispositif poids) ; pas de terme de terrain
/// (#M02/#M03 : la conversion cotation -> facteur n'est pas publiee) ; pas de
/// coefficient de fatigue cumulative par jour (#M06).
///
/// RANGEMENT (lot 645-06b, regle 12 : pas de `part` hors code genere). Ce
/// fichier est la PORTE de la formule : il re-exporte les cinq bibliotheques
/// qui la composent, et les appelants n'importent que lui.
///   - `feasibility_types.dart` : les vocabulaires (niveau, verdict...) ;
///   - `feasibility_scale.dart` : le bareme, les seuils et les conditions ;
///   - `feasibility_stages.dart` : l'etape, son verdict, le circuit, les
///     conseils ;
///   - `feasibility_assessment.dart` : le bilan rendu au randonneur ;
///   - `feasibility_engine.dart` : la formule elle-meme.
/// Les regles de programme (`feasibility_program_rules.dart`) n'y sont PAS :
/// elles ne servent qu'a la formule.
library;

export 'feasibility_assessment.dart';
export 'feasibility_engine.dart';
export 'feasibility_scale.dart';
export 'feasibility_stages.dart';
export 'feasibility_types.dart';
