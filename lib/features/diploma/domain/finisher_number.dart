/// Numero de finisher du diplome (CORRECTIF L5-7, arbitrage ARB-3).
///
/// POURQUOI IL EST FABRIQUE ICI ET NON RECOPIE. Le numero de finisher du
/// journal de reference est un LITTERAL EN DUR : le meme numero pour tous
/// les utilisateurs, a chaque session, sans compteur, sans sequence, sans
/// persistance et sans serveur — un decor de demonstration jamais termine.
/// Le greffer n'aurait rien apporte : il n'y avait rien a greffer.
///
/// CE QUE CELUI-CI GARANTIT, ET CE QU'IL NE GARANTIT PAS. Il est LISIBLE,
/// HORODATE et STABLE : la meme randonnee rend toujours le meme numero, y
/// compris apres redemarrage de l'app, parce qu'il est DERIVE de la session
/// et non tire d'un compteur qu'une reinstallation remettrait a zero. Il
/// n'est PAS unique a l'echelle mondiale, et il ne peut pas l'etre sans
/// serveur : deux randonneurs peuvent tomber sur le meme suffixe. C'est
/// l'option par defaut de l'arbitrage, renversable d'un mot.
library;

/// Construit le numero de finisher d'une session.
///
/// Forme : `SW-AAAAMMJJ-XXXX`, ou la date est celle de la FIN de randonnee
/// et `XXXX` un suffixe hexadecimal derive de l'identifiant de session.
String buildFinisherNumber({
  required String sessionId,
  required DateTime finishedAt,
}) {
  String two(int v) => v.toString().padLeft(2, '0');
  final date = '${finishedAt.year}${two(finishedAt.month)}'
      '${two(finishedAt.day)}';
  return 'SW-$date-${_shortHash(sessionId)}';
}

/// Suffixe de 4 caracteres hexadecimaux, stable pour une meme entree.
///
/// FNV-1a 32 bits replie sur 16 bits : un simple total de codes de
/// caracteres donnerait le meme suffixe a deux identifiants permutes, ce
/// qui se verrait sur des identifiants de session voisins.
String _shortHash(String input) {
  var hash = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    // Multiplication par le nombre premier FNV, bornee a 32 bits.
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  final folded = ((hash >> 16) ^ hash) & 0xFFFF;
  return folded.toRadixString(16).toUpperCase().padLeft(4, '0');
}
