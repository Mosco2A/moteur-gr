/// TRI ALPHABETIQUE D'UNE LISTE DE LIBELLES AFFICHES (tache 634, DEM-260929-1124).
///
/// LE DEFAUT QU'IL CORRIGE. Le selecteur de pays de la fiche du randonneur
/// affichait les 246 pays dans l'ordre du paquet `country_picker`, c'est-a-dire
/// dans l'ordre alphabetique de leurs noms ANGLAIS, alors que les libelles
/// AFFICHES sont traduits. En francais, la liste s'ouvrait donc sur
/// « Afghanistan, Iles Aland, Albanie, Algerie, Samoa americaines... » : un
/// ordre qui parait aleatoire. Retour de Christophe du 29/09 11:24, verbatim :
/// « l'ordre des pays n'est pas alphabetique ».
///
/// CE QUE FAIT CE FICHIER. Il donne le comparateur a poser sur TOUTE liste de
/// libelles montres au randonneur — pays aujourd'hui, n'importe quelle autre
/// liste demain. La regle est simple : on trie sur CE QUI EST AFFICHE, dans la
/// langue courante, jamais sur une clef technique ni sur une autre langue.
///
/// POURQUOI PAS `String.compareTo` TOUT SEUL. Il compare des unites de code
/// UTF-16. « Egypte » (E accent aigu, U+00C9) y passe APRES « Zimbabwe »
/// (Z, U+005A), et « autriche » avant « Allemagne ». Les accents et la casse
/// enverraient donc des pays a des endroits ou personne ne les cherche.
///
/// LA REGLE RETENUE. On construit une CLEF DE TRI en repliant les signes
/// diacritiques sur leur lettre de base et en passant en minuscules :
/// « Egypte » se trie a la lettre E, « Allemagne » avant « Autriche »,
/// « Osterreich » (O trema) avant « Pakistan » en allemand. Le libelle d'origine
/// sert de depart en cas d'egalite, pour que le tri soit TOTAL et donc STABLE
/// d'un appel a l'autre — deux pays de meme clef ne changent jamais de place.
///
/// CE QUE CE FICHIER N'EST PAS. Ce n'est pas une collation Unicode complete
/// (ICU/CLDR) : le danois qui classe « Aa » en fin d'alphabet, ou l'espagnol
/// d'avant 1994 qui traitait « ch » comme une lettre, ne sont pas rendus. Dart
/// n'embarque aucun collateur, et la seule facon d'en avoir un serait de
/// dependre de la plateforme — donc de rendre le tri intestable et different sur
/// iPhone et sur Android. Pour une liste de pays lue dans cinq langues
/// europeennes, le repliement des diacritiques donne l'ordre que le randonneur
/// attend, et il le donne de maniere identique partout.
library;

/// Repliement des signes diacritiques sur leur lettre de base.
///
/// Couvre le latin etendu utilise par les noms de pays dans les cinq langues de
/// l'application (francais, anglais, allemand, espagnol, italien) : c'est la ou
/// vivent les « Egypte », « Osterreich », « Espana », « Turkiye », « Cote
/// d'Ivoire ». Les lettres qui se lisent comme DEUX lettres sont depliees
/// (l'eszett allemand « ss », les ligatures « ae » et « oe », l'eth et le thorn
/// islandais) : c'est ainsi que les dictionnaires des langues concernees les
/// classent.
const Map<String, String> _replisDiacritiques = {
  'à': 'a',
  'á': 'a',
  'â': 'a',
  'ã': 'a',
  'ä': 'a',
  'å': 'a',
  'ā': 'a',
  'ă': 'a',
  'ą': 'a',
  'ǎ': 'a',
  'æ': 'ae',
  'ç': 'c',
  'ć': 'c',
  'č': 'c',
  'ĉ': 'c',
  'ċ': 'c',
  'ď': 'd',
  'đ': 'd',
  'ð': 'd',
  'è': 'e',
  'é': 'e',
  'ê': 'e',
  'ë': 'e',
  'ē': 'e',
  'ĕ': 'e',
  'ė': 'e',
  'ę': 'e',
  'ě': 'e',
  'ĝ': 'g',
  'ğ': 'g',
  'ġ': 'g',
  'ģ': 'g',
  'ĥ': 'h',
  'ħ': 'h',
  'ì': 'i',
  'í': 'i',
  'î': 'i',
  'ï': 'i',
  'ī': 'i',
  'ĭ': 'i',
  'į': 'i',
  'ı': 'i',
  'ĵ': 'j',
  'ķ': 'k',
  'ĺ': 'l',
  'ļ': 'l',
  'ľ': 'l',
  'ł': 'l',
  'ñ': 'n',
  'ń': 'n',
  'ņ': 'n',
  'ň': 'n',
  'ò': 'o',
  'ó': 'o',
  'ô': 'o',
  'õ': 'o',
  'ö': 'o',
  'ø': 'o',
  'ō': 'o',
  'ŏ': 'o',
  'ő': 'o',
  'œ': 'oe',
  'ŕ': 'r',
  'ŗ': 'r',
  'ř': 'r',
  'ś': 's',
  'ŝ': 's',
  'ş': 's',
  'š': 's',
  'ș': 's',
  'ß': 'ss',
  'ţ': 't',
  'ť': 't',
  'ŧ': 't',
  'ț': 't',
  'þ': 'th',
  'ù': 'u',
  'ú': 'u',
  'û': 'u',
  'ü': 'u',
  'ū': 'u',
  'ŭ': 'u',
  'ů': 'u',
  'ű': 'u',
  'ų': 'u',
  'ŵ': 'w',
  'ý': 'y',
  'ÿ': 'y',
  'ŷ': 'y',
  'ź': 'z',
  'ż': 'z',
  'ž': 'z',
};

/// LA CLEF SUR LAQUELLE ON TRIE : le libelle sans accents, en minuscules.
///
/// Passe en minuscules D'ABORD (« Ö » devient « ö », que la table connait), puis
/// replie lettre a lettre. Un caractere inconnu de la table est recopie tel
/// quel : un libelle en alphabet non latin n'est ni perdu ni deforme, il se
/// range simplement apres les libelles latins.
String clefDeTriLocalisee(String libelle) {
  final minuscules = libelle.toLowerCase();
  final tampon = StringBuffer();
  for (final caractere in minuscules.split('')) {
    tampon.write(_replisDiacritiques[caractere] ?? caractere);
  }
  return tampon.toString();
}

/// COMPARATEUR ALPHABETIQUE POUR DES LIBELLES AFFICHES AU RANDONNEUR.
///
/// A poser sur `List.sort` partout ou une liste montree est construite dans un
/// ordre qui n'est pas celui de la langue courante.
///
/// Le depart en cas d'egalite de clef se fait sur le libelle d'origine : sans
/// lui, deux libelles qui ne different que par un accent auraient un ordre
/// dependant de l'implementation du tri, et la liste bougerait d'un affichage a
/// l'autre.
int comparerLibellesLocalises(String a, String b) {
  final ordre = clefDeTriLocalisee(a).compareTo(clefDeTriLocalisee(b));
  return ordre != 0 ? ordre : a.compareTo(b);
}
