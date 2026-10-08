/// FACADE PUBLIQUE DE LA FEATURE `community` — LA SEULE PORTE D ENTREE.
///
/// ARB-645-05-b, DECISION B DE CHRISTOPHE (03/10/2026). Une feature ne lit une
/// autre feature QUE par sa facade. Ce fichier est cette porte pour
/// `community` : tout ce qu il re-exporte est public, et tout le reste de
/// `community` est prive. La garde
/// `test/structurel/couches_respectees_645_test.dart` est ce qui l empeche.
///
/// CE FICHIER NE CONTIENT QUE DES `export`. Le `show` porte la liste EXACTE
/// des symboles qu une autre feature utilise reellement.
///
/// OUVERTE AU LOT 671-04 (LES REVEILS FINS), POUR UN SEUL NOM : `map` lit
/// `WaypointType`, la liste FERMEE des types de repere, pour reconnaitre les
/// reperes de type `jonction` qui enrichissent les charnieres du trace — une
/// jonction declaree est un endroit ou l on se trompe de chemin. Le type se
/// lit ici plutot que d etre recopie en chaine : une seule verite.
library;

export 'data/waypoint_service.dart' show WaypointType;
