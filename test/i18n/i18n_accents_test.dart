import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// GATE i18n - ACCENTS ET ENCODAGE DES TRADUCTIONS.
///
/// Correctif L2-2 du plan de mise en conformite StepWays cycle4.
/// AVANT cette gate, AUCUN test du depot ne regardait le CONTENU des
/// traductions : 446 chaines avaient perdu leurs accents sans qu aucune
/// suite ne bronche.
///
/// DEUX TESTS, DEUX ROLES DIFFERENTS.
///
/// 1. MOJIBAKE - actif en permanence. Il attrape une chaine dont l encodage
///    a ete casse (UTF-8 relu en latin-1). C est le filet qui protege les
///    corrections elles-memes : si un correctif casse un octet, il tombe.
///
/// 2. ACCENTS - dictionnaire EXPLICITE de formes fautives, langue par
///    langue. Pas d heuristique floue : une forme est fautive parce qu elle
///    est NOMMEE dans le dictionnaire, jamais parce qu un algorithme la
///    trouve suspecte. Le message d echec nomme le FICHIER, la CLE et la
///    CHAINE - pas un compteur : un compteur ne se corrige pas.
///
/// L ANGLAIS EST VOLONTAIREMENT EXCLU du test ACCENTS : il ne porte aucun
/// accent, l y soumettre ne produirait que du bruit. Il reste couvert par le
/// test MOJIBAKE.
///
/// FAUX POSITIFS NOMMES, ET POURQUOI :
///  - allemand Grosse, Grosser, grosse : le ss a la place de l eszett est
///    une convention typographique admise (c est la regle en Suisse). Les
///    corriger serait un CHOIX EDITORIAL et non une mise en conformite.
///    Arbitrage a rendre par Christophe.
///  - allemand Hohe et Hohes : adjectif (Hohe Prioritaet) et non le nom
///    Hoehe. Warme, Starke, Grate, Wahl, Plane, schon, konnte, getauscht,
///    Erlasse, Busse : memes homographes legitimes.
///  - espagnol esta, este, que, solo : formes correctes sans accent dans ce
///    fichier. Ne jamais les accentuer automatiquement.
///  - italien e : conjonction dans 73 des 79 occurrences du fichier. Les 6
///    cas du verbe ont ete corriges nominativement par le correctif L2-18.
///
/// Le dictionnaire de ce fichier est le MEME que celui qui a servi aux
/// correctifs L2-3 a L2-18 : la gate verifie ce que les correctifs ont fait.

/// Langues soumises au controle des accents. L anglais n y est pas.
const List<String> languesAvecAccents = <String>['fr', 'de', 'es', 'it'];

/// Toutes les langues du depot : le controle d encodage les prend toutes.
const List<String> toutesLesLangues = <String>['fr', 'de', 'es', 'it', 'en'];

/// Formes fautives par langue : mot fautif -> forme attendue.
const Map<String, Map<String, String>> formesFautives =
    <String, Map<String, String>>{
  'fr': <String, String>{
    'acces': 'accès',
    'adapte': 'adapté',
    'adhesif': 'adhésif',
    'ajoute': 'ajouté',
    'alleger': 'alléger',
    'allegez': 'allégez',
    'apparaitra': 'apparaîtra',
    'base': 'basé',
    'batons': 'bâtons',
    'biodegradable': 'biodégradable',
    'brassiere': 'brassière',
    'cable': 'câble',
    'calecons': 'caleçons',
    'categorie': 'catégorie',
    'cle': 'clé',
    'coches': 'cochés',
    'condense': 'condensé',
    'consecutifs': 'consécutifs',
    'cuillere': 'cuillère',
    'debloquer': 'débloquer',
    'definitivement': 'définitivement',
    'dejections': 'déjections',
    'depart': 'départ',
    'dernieres': 'dernières',
    'desactive': 'désactivé',
    'desinfectant': 'désinfectant',
    'detectees': 'détectées',
    'diarrheique': 'diarrhéique',
    'ecart': 'écart',
    'elastique': 'élastique',
    'elastoplaste': 'Élastoplaste',
    'electrolytes': 'électrolytes',
    'electronique': 'électronique',
    'eloignes': 'éloignés',
    'eloignez': 'éloignez',
    'energetique': 'énergétique',
    'entrainement': 'entraînement',
    'equilibre': 'équilibré',
    'equipements': 'équipements',
    'etanches': 'étanches',
    'ete': 'été',
    'etes': 'êtes',
    'etre': 'être',
    'experience': 'expérience',
    'faisabilite': 'faisabilité',
    'felicitations': 'félicitations',
    'guetres': 'guêtres',
    'hygiene': 'hygiène',
    'ibuprofene': 'ibuprofène',
    'ideal': 'idéal',
    'ignores': 'ignorés',
    'impermeable': 'imperméable',
    'importee': 'importée',
    'integral': 'intégral',
    'leger': 'léger',
    'legere': 'légère',
    'legers': 'légers',
    'levres': 'lèvres',
    'lyophilise': 'lyophilisé',
    'meme': 'même',
    'meteo': 'météo',
    'periodiques': 'périodiques',
    'personnalise': 'personnalisé',
    'portees': 'portées',
    'portes': 'portés',
    'prepares': 'préparés',
    'pret': 'prêt',
    'quantite': 'quantité',
    'rechaud': 'réchaud',
    'reduire': 'réduire',
    'refuse': 'refusé',
    'renforcee': 'renforcée',
    'reserve': 'réserve',
    'seances': 'séances',
    'seches': 'sèches',
    'steriles': 'stériles',
    'superieur': 'supérieur',
    'superieure': 'supérieure',
    'supplementaire': 'supplémentaire',
    'supprime': 'supprimé',
    'telecharger': 'télécharger',
    'telephone': 'téléphone',
    'termine': 'terminé',
    'transportee': 'transportée',
    'verifier': 'vérifier',
    'verifies': 'vérifiés',
    'verifiez': 'vérifiez',
    'vetement': 'vêtement',
    'vetements': 'vêtements',
  },
  'de': <String, String>{
    'andern': 'ändern',
    'arztliche': 'ärztliche',
    'ausgewaehlter': 'ausgewählter',
    'ausruestung': 'ausrüstung',
    'ausrustung': 'ausrüstung',
    'benotigt': 'benötigt',
    'bestatige': 'bestätige',
    'bestatigen': 'bestätigen',
    'bestatigt': 'bestätigt',
    'bestatigung': 'bestätigung',
    'durchgefuhrt': 'durchgeführt',
    'endgultig': 'endgültig',
    'ernaehrung': 'ernährung',
    'ersatzschnursenkel': 'ersatzschnürsenkel',
    'erwage': 'erwäge',
    'frueh': 'früh',
    'fruhjahrsmatsch': 'frühjahrsmatsch',
    'fruhling': 'frühling',
    'fuellen': 'füllen',
    'fuer': 'für',
    'fuge': 'füge',
    'fugen': 'fügen',
    'fullen': 'füllen',
    'fur': 'für',
    'furs': 'fürs',
    'gegenuber': 'gegenüber',
    'gelande': 'gelände',
    'gelandetechnik': 'geländetechnik',
    'gelandezustand': 'geländezustand',
    'geloscht': 'gelöscht',
    'gepruft': 'geprüft',
    'gerat': 'gerät',
    'geschatzt': 'geschätzt',
    'geschatztes': 'geschätztes',
    'gluckwunsch': 'glückwunsch',
    'grun': 'grün',
    'hinzufugen': 'hinzufügen',
    'hinzugefugt': 'hinzugefügt',
    'hoehe': 'höhe',
    'hoehenunterschied': 'höhenunterschied',
    'hohengewohnung': 'höhengewöhnung',
    'hohenmeter': 'höhenmeter',
    'hohenprofil': 'höhenprofil',
    'hohenunterschied': 'höhenunterschied',
    'horen': 'hören',
    'hutten': 'hütten',
    'huttenleben': 'hüttenleben',
    'huttenschlafsack': 'hüttenschlafsack',
    'intimtucher': 'intimtücher',
    'konnektivitat': 'konnektivität',
    'korper': 'körper',
    'korperdaten': 'körperdaten',
    'korpergewicht': 'körpergewicht',
    'korpergewichts': 'körpergewichts',
    'kraefte': 'kräfte',
    'kuehle': 'kühle',
    'landercode': 'ländercode',
    'lauft': 'läuft',
    'loffel': 'löffel',
    'loschen': 'löschen',
    'manner': 'männer',
    'mannlich': 'männlich',
    'mochten': 'möchten',
    'moglich': 'möglich',
    'mullbeutel': 'müllbeutel',
    'mutze': 'mütze',
    'nachsten': 'nächsten',
    'ohrstopsel': 'ohrstöpsel',
    'packsacke': 'packsäcke',
    'pflichtausrustung': 'pflichtausrüstung',
    'prioritaet': 'priorität',
    'pruefen': 'prüfen',
    'prufen': 'prüfen',
    'regelmaessige': 'regelmässige',
    'regenhulle': 'regenhülle',
    'reisefuehrer': 'reiseführer',
    'schlusselziel': 'schlüsselziel',
    'schnursenkel': 'schnürsenkel',
    'sehenswuerdigkeiten': 'sehenswürdigkeiten',
    'sicherheitsgrunden': 'sicherheitsgründen',
    'tagebucheintraege': 'tagebucheinträge',
    'tagliche': 'tägliche',
    'taglicher': 'täglicher',
    'trockenfruchte': 'trockenfrüchte',
    'uber': 'über',
    'ubergewicht': 'übergewicht',
    'uberprufen': 'überprüfen',
    'ungeklarten': 'ungeklärten',
    'ungultige': 'ungültige',
    'ungultiger': 'ungültiger',
    'ungultiges': 'ungültiges',
    'unterkuenfte': 'unterkünfte',
    'unterwasche': 'unterwäsche',
    'verfuegbar': 'verfügbar',
    'verfugbar': 'verfügbar',
    'verfugbare': 'verfügbare',
    'vergrossern': 'vergrössern',
    'veroffentlicht': 'veröffentlicht',
    'verschlusselten': 'verschlüsselten',
    'verstarkter': 'verstärkter',
    'waehle': 'wähle',
    'waehlen': 'wählen',
    'wahlen': 'wählen',
    'wanderstocke': 'wanderstöcke',
    'zahnburste': 'zahnbürste',
    'zuruck': 'zurück',
    'zuruckgelegt': 'zurückgelegt',
    'zuruckgelegte': 'zurückgelegte',
    'zurueckgelegt': 'zurückgelegt',
    'zusatzliches': 'zusätzliches',
  },
  'es': <String, String>{
    'altimetrico': 'altimétrico',
    'anade': 'añade',
    'anadido': 'añadido',
    'anadir': 'añadir',
    'anos': 'años',
    'antihistaminico': 'antihistamínico',
    'aparecera': 'aparecerá',
    'articulo': 'artículo',
    'articulos': 'artículos',
    'aun': 'aún',
    'autonomia': 'autonomía',
    'banador': 'bañador',
    'bateria': 'batería',
    'botiquin': 'botiquín',
    'boton': 'botón',
    'calidos': 'cálidos',
    'categoria': 'categoría',
    'centimetros': 'centímetros',
    'clasificacion': 'clasificación',
    'codigo': 'código',
    'condicion': 'condición',
    'conexion': 'conexión',
    'contribucion': 'contribución',
    'dia': 'día',
    'dias': 'días',
    'dificil': 'difícil',
    'duracion': 'duración',
    'elastica': 'elástica',
    'electronica': 'electrónica',
    'eliminara': 'eliminará',
    'energetica': 'energética',
    'estadisticas': 'estadísticas',
    'esteriles': 'estériles',
    'exito': 'éxito',
    'facil': 'fácil',
    'generico': 'genérico',
    'guardara': 'guardará',
    'guia': 'guía',
    'guias': 'guías',
    'habito': 'hábito',
    'habra': 'habrá',
    'higienico': 'higiénico',
    'indice': 'índice',
    'intentalo': 'inténtalo',
    'interes': 'interés',
    'intimas': 'íntimas',
    'jabon': 'jabón',
    'lesion': 'lesión',
    'llegara': 'llegará',
    'mas': 'más',
    'max': 'máx',
    'maximo': 'máximo',
    'medica': 'médica',
    'minimo': 'mínimo',
    'modulo': 'módulo',
    'ningun': 'ningún',
    'numero': 'número',
    'nutricion': 'nutrición',
    'observacion': 'observación',
    'otono': 'otoño',
    'pais': 'país',
    'pantalon': 'pantalón',
    'posicion': 'posición',
    'practicas': 'prácticas',
    'preparacion': 'preparación',
    'preparate': 'prepárate',
    'progresion': 'progresión',
    'propondra': 'propondrá',
    'proteccion': 'protección',
    'proxima': 'próxima',
    'proximos': 'próximos',
    'publicara': 'publicará',
    'racion': 'ración',
    'recuperacion': 'recuperación',
    'revisara': 'revisará',
    'revision': 'revisión',
    'sabana': 'sábana',
    'sanguineo': 'sanguíneo',
    'seleccion': 'selección',
    'senalado': 'señalado',
    'senalamiento': 'señalamiento',
    'senalar': 'señalar',
    'siguenos': 'síguenos',
    'sincronizacion': 'sincronización',
    'tecnica': 'técnica',
    'tecnicos': 'técnicos',
    'telefono': 'teléfono',
    'termica': 'térmica',
    'titulo': 'título',
    'todavia': 'todavía',
    'ubicacion': 'ubicación',
    'ultimas': 'últimas',
    'unete': 'únete',
    'vacia': 'vacía',
    'valida': 'válida',
    'validacion': 'validación',
    'valido': 'válido',
  },
  'it': <String, String>{
    'arrivera': 'arriverà',
    'cio': 'ciò',
    'connettivita': 'connettività',
    'difficolta': 'difficoltà',
    'eta': 'età',
    'fattibilita': 'fattibilità',
    'gia': 'già',
    'ne': 'né',
    'obesita': 'obesità',
    'piu': 'più',
    'priorita': 'priorità',
    'quantita': 'quantità',
    'sara': 'sarà',
    'tecnicita': 'tecnicità',
    'velocita': 'velocità',
    'verra': 'verrà',
  },
};

/// Mots qui RESSEMBLENT a une faute mais n en sont pas (cf. en-tete).
const Map<String, List<String>> nonFautes = <String, List<String>>{
  'fr': <String>[
    'arrive',
    'base',
    'certifie',
    'oriente',
    'repartir',
    'sec',
    'secs',
    'valide',
  ],
  'de': <String>[
    'busse',
    'erlasse',
    'fliesst',
    'getauscht',
    'grate',
    'grosse',
    'grossen',
    'grosser',
    'grosses',
    'hohe',
    'hohes',
    'konnte',
    'plane',
    'schliessen',
    'schon',
    'starke',
    'starker',
    'wahl',
    'warme',
  ],
  'es': <String>[
    'alta',
    'alto',
    'baja',
    'bajo',
    'completo',
    'esta',
    'estan',
    'estas',
    'este',
    'estos',
    'media',
    'medio',
    'que',
    'se',
    'solo',
  ],
  'it': <String>[
    'e',
  ],
};

/// Exception ciblee : un mot legitime sur UNE cle precise.
/// Clef du map : langue, barre verticale, cle i18n.
const Map<String, List<String>> exceptionsParCle = <String, List<String>>{
  'es|checklist.ui.infoValidateBody': <String>['valida'],
  'es|fireRisk.fwiSource': <String>['meteo'],
  'fr|fireRisk.fwiSource': <String>['meteo'],
};

/// Sequences qui trahissent un encodage casse.
const List<String> sequencesMojibake = <String>[
  'Ã\u009f',
  'Ã ',
  'Ã¡',
  'Ã¤',
  'Ã§',
  'Ã¨',
  'Ã©',
  'Ãª',
  'Ã­',
  'Ã±',
  'Ã³',
  'Ã¶',
  'Ãº',
  'Ã¼',
  'â\u0080\u0094',
  'â\u0080\u0099',
  'ï¿½',
  '\ufffd',
];

final RegExp _placeholders = RegExp(r'\{[^}]*\}|\$\{?\w+\}?');
final RegExp _mots = RegExp(r'[A-Za-zÀ-ɏ]+');

/// Parcourt un fichier i18n et appelle [visite] sur chaque couple cle/chaine.
void _parcourir(
  Map<String, dynamic> noeud,
  String prefixe,
  void Function(String cle, String valeur) visite,
) {
  noeud.forEach((String k, dynamic v) {
    final String cle = prefixe.isEmpty ? k : '$prefixe.$k';
    if (v is Map<String, dynamic>) {
      _parcourir(v, cle, visite);
    } else if (v is String) {
      visite(cle, v);
    }
  });
}

Map<String, dynamic> _charger(String langue) {
  final File fichier = File('assets/i18n/$langue.i18n.json');
  expect(
    fichier.existsSync(),
    isTrue,
    reason: 'assets/i18n/$langue.i18n.json doit exister',
  );
  return jsonDecode(fichier.readAsStringSync()) as Map<String, dynamic>;
}

void main() {
  group('Gate i18n', () {
    test('aucun encodage casse dans les 5 fichiers de traduction', () {
      final List<String> trouvailles = <String>[];
      for (final String langue in toutesLesLangues) {
        _parcourir(_charger(langue), '', (String cle, String valeur) {
          for (final String sequence in sequencesMojibake) {
            if (valeur.contains(sequence)) {
              trouvailles.add(
                '$langue.i18n.json | $cle | sequence [$sequence] | $valeur',
              );
            }
          }
        });
      }
      expect(
        trouvailles,
        isEmpty,
        reason:
            'Encodage casse (UTF-8 relu en latin-1) dans ces chaines :\n'
            '${trouvailles.join('\n')}',
      );
    });

    test('aucune forme fautive d accent dans fr, de, es et it', () {
      final List<String> trouvailles = <String>[];
      for (final String langue in languesAvecAccents) {
        final Map<String, String> dictionnaire = formesFautives[langue]!;
        final List<String> exclus = nonFautes[langue] ?? const <String>[];
        _parcourir(_charger(langue), '', (String cle, String valeur) {
          final List<String> exceptions =
              exceptionsParCle['$langue|$cle'] ?? const <String>[];
          final String sansPlaceholder = valeur.replaceAll(_placeholders, ' ');
          for (final RegExpMatch m in _mots.allMatches(sansPlaceholder)) {
            final String mot = m.group(0)!.toLowerCase();
            if (exclus.contains(mot) || exceptions.contains(mot)) continue;
            final String? attendu = dictionnaire[mot];
            if (attendu != null) {
              trouvailles.add(
                '$langue.i18n.json | $cle | [$valeur] | '
                '[${m.group(0)}] doit s ecrire [$attendu]',
              );
            }
          }
        });
      }
      expect(
        trouvailles,
        isEmpty,
        reason:
            'Accents manquants - chaque ligne donne fichier, cle, chaine et '
            'le mot a corriger :\n${trouvailles.join('\n')}',
      );
    },
        skip: 'EN VEILLE - a activer par le correctif L2-19 du plan de conformite cycle4.');
  });
}
