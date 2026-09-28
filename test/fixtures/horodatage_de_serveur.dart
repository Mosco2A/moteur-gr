/// DES INSTANTS DE SERVEUR LISIBLES DANS UN TEST (StepWays tache 610).
///
/// POURQUOI CE FICHIER EXISTE, ET CE QU IL NE FAIT PAS. La bascule du compteur
/// vers l horodatage a remplace des `rev: 1`, `rev: 2` par des dates dans une
/// vingtaine de fichiers de test. Deux facons de le faire :
///
///  * ecrire `HorodatageServeur.annonceParLeServeur('2026-09-01T12:00:00.000Z')!`
///    a chaque fois — exact, mais illisible, et la RELATION D ORDRE entre deux
///    instants, qui est ce que les tests verifient reellement, se perd dans le
///    bruit des chiffres ;
///  * nommer les instants par leur ECART, ce que fait ce fichier.
///
/// CE FICHIER NE CONTOURNE AUCUNE GARDE. Il n existe aucun raccourci ici pour
/// fabriquer un horodatage depuis l horloge de l appareil : [instantDeServeur] et
/// [aJPlus] passent par [HorodatageServeur.annonceParLeServeur], donc par LA
/// LECTURE d une valeur annoncee — exactement le chemin de production. Un test qui
/// voudrait verifier l interdiction de l horloge locale n aurait ici aucun moyen de
/// la contourner, et c est voulu.
library;

import 'package:moteur_gr/core/data/revision_de_donnee.dart';

/// L instant de reference des tests : 1er septembre 2026, midi UTC.
///
/// Un instant FIXE et dans le passe, jamais `DateTime.now()` : un test dont le
/// resultat depend du jour ou il tourne finit par mentir un matin.
const String isoDeReference = '2026-09-01T12:00:00.000Z';

/// L instant de reference des tests.
HorodatageServeur get instantDeReference => instantDeServeur(isoDeReference);

/// L instant annonce par un serveur pour l ecriture ISO 8601 [iso].
HorodatageServeur instantDeServeur(String iso) =>
    HorodatageServeur.annonceParLeServeur(iso)!;

/// L instant de reference decale de [jours] jours (et [minutes] minutes).
///
/// C est la forme a privilegier : `aJPlus(0)` et `aJPlus(1)` disent « deux
/// publications successives » sans imposer de lire deux dates completes, et
/// `aJPlus(200)` dit « bien au-dela de la fenetre de retention » sans qu on ait a
/// recompter.
HorodatageServeur aJPlus(int jours, {int minutes = 0}) {
  final base = DateTime.parse(isoDeReference);
  return instantDeServeur(
    base.add(Duration(days: jours, minutes: minutes)).toUtc().toIso8601String(),
  );
}
