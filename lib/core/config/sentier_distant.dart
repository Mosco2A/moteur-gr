import '../models/trail_manifest.dart';
import 'trail_config.dart';

/// D UNE ENTREE DE MANIFESTE A UN SENTIER AFFICHABLE — ET L ORDRE DES SOURCES.
///
/// C est ici que se decide la question de fond de la tache 605, et la reponse
/// n est PAS « distant ou compile » mais « distant PUIS compile, dans cet
/// ordre » :
///
///  1. LE DISTANT EST LA SOURCE DE VERITE. Sur un identifiant commun, toute
///     donnee que le manifeste declare GAGNE sur la valeur compilee. C est ce
///     qui permet de corriger une altitude, un denivele ou un prix faux sans
///     passer par le magasin.
///
///  2. LE COMPILE APPORTE CE QUE LE DISTANT NE PEUT PAS PORTER. Les chemins
///     d ASSETS (trace GPX, dossier de seed, fiches conseils) designent des
///     fichiers embarques dans le binaire : un manifeste ne peut pas les
///     inventer. Quand le sentier existe aussi en compile, on les reprend de
///     lui. Ce n est pas une exception a la regle 1 — c est la meme regle : le
///     distant gagne sur ce qu il DIT, et il ne dit rien des assets.
///
///  3. L IDENTIFIANT EST LA CLE, ET IL N Y A QU UN SEUL SENTIER PAR
///     IDENTIFIANT. Un sentier present des deux cotes n est pas deux sentiers :
///     c est le meme, fusionne. C est le point 4 du mandat de la tache 605.
///
/// UNE ENTREE PEUT N ETRE PAS AFFICHABLE, ET ON LE DIT PLUTOT QUE DE MONTRER
/// UNE CARTE VIDE. Une entree sans fiche ET sans equivalent compile ne porte
/// que du versionnement : ni nom, ni region, ni distance. [versSentier] rend
/// alors `null`, et l appelant l ecarte en le JOURNALISANT — un sentier
/// silencieusement absent est indiagnosticable, c est la lecon de la tache 604.
extension EntreeManifesteEnSentier on TrailManifestEntry {
  /// Vrai si l entree est DESTINEE au catalogue (`status == 'active'`).
  ///
  /// `draft` et `archived` sont des etats de publication cote serveur :
  /// Christophe peut preparer un sentier ou en retirer un SANS republier
  /// l application.
  bool get estActive => status == 'active';

  /// Construit le sentier affichable, ou `null` si l entree ne decrit rien.
  ///
  /// [compile] est l equivalent du catalogue embarque quand il existe.
  TrailConfig? versSentier({TrailConfig? compile}) {
    final f = fiche;

    // Pas de fiche : l entree ne fait que VERSIONNER un sentier deja connu du
    // binaire. Sans equivalent compile, elle ne decrit rien d affichable.
    if (f == null) return compile;

    return TrailConfig(
      id: trailId,
      // --- Ce que le distant DIT : il gagne, sans condition ---
      name: f.name,
      displayName: f.displayName,
      tagline: f.tagline,
      totalStages: f.totalStages,
      totalDistanceKm: f.totalDistanceKm,
      totalElevationGain: f.totalElevationGain,
      region: f.region,
      country: f.country,
      // --- Ce que le distant PEUT dire, avec repli sur le compile ---
      primaryColorValue: f.primaryColorValue ??
          compile?.primaryColorValue ??
          _couleurPrimaireParDefaut,
      secondaryColorValue: f.secondaryColorValue ??
          compile?.secondaryColorValue ??
          _couleurSecondaireParDefaut,
      directions: f.directions ?? compile?.directions ?? const ['NS', 'SN'],
      availableDurations: f.availableDurations ??
          compile?.availableDurations ??
          const [7, 9, 12, 14, 16],
      defaultDuration: f.defaultDuration ?? compile?.defaultDuration ?? 14,
      // LE PRIX : `null` cote distant ne veut PAS dire « gratuit ». Il veut
      // dire « je ne me prononce pas », et l on retombe alors sur le compile,
      // puis sur la regle du modele (une etape par etape). Confondre les deux
      // offrirait un sentier payant a tout le monde sur un simple oubli de
      // champ dans le manifeste.
      priceStages: f.priceStages ?? compile?.priceStages,
      emergencyNumbers: f.emergencyNumbers
              ?.map((n) =>
                  TrailEmergencyNumber(name: n.name, phone: n.phone))
              .toList() ??
          compile?.emergencyNumbers ??
          const [],
      privacyPolicyUrl: f.privacyPolicyUrl ?? compile?.privacyPolicyUrl,
      // --- Ce que SEUL le compile peut porter : des fichiers embarques ---
      //
      // LIMITE ASSUMEE ET MESUREE (tache 605). `gpxAssetPath` est lu par
      // `gpx_track_provider.dart` via `rootBundle.loadString` : pour un sentier
      // connu du SEUL distant il n existe aucun asset, et la chaine vide est la
      // seule valeur honnete. Le sentier est alors AU CATALOGUE et ses donnees
      // (etapes, points d interet, points de trace) descendent bien en base par
      // le fichier de donnees ; c est la lecture de la trace DEPUIS LES ASSETS
      // qui n a pas de source. Brancher la carte sur les `trail_gpx_points`
      // deja telecharges est un chantier distinct, hors de ce lot, et il est
      // nomme comme tel plutot que masque par un chemin d asset invente.
      gpxAssetPath: compile?.gpxAssetPath ?? '',
      seedAssetsBase: compile?.seedAssetsBase,
      accommodationsAssetPath: compile?.accommodationsAssetPath,
      tipAssetPaths: compile?.tipAssetPaths ?? const [],
      firebaseProjectId: compile?.firebaseProjectId,
      offlineFirst: compile?.offlineFirst ?? true,
      hasPremium: compile?.hasPremium ?? false,
    );
  }
}

/// Couleurs de repli quand ni le distant ni le compile ne se prononcent.
///
/// Neutres et volontairement pas « de marque » : un sentier neuf s affiche
/// correctement meme si Christophe n a pas choisi sa palette.
const int _couleurPrimaireParDefaut = 0xFF2E7D32;
const int _couleurSecondaireParDefaut = 0xFF1565C0;
