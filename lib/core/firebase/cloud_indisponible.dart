/// Refus NOMME d'une operation qui exige le cloud, quand le cloud est absent
/// (596 C4).
///
/// POURQUOI UN TYPE DEDIE : quatre acces Firestore n'avaient AUCUNE garde de
/// disponibilite. Ils ne plantaient pas — seulement parce que Firebase etait
/// eteint partout et qu'aucun de ces chemins n'etait jamais emprunte. Le jour
/// ou l'on allume Firebase (c'est-a-dire le jour de ce meme correctif), ils
/// seraient devenus des plantages reels, avec une erreur native illisible.
///
/// Un refus type est rattrapable par l'appelant et se raconte a l'utilisateur ;
/// une `LateInitializationError` venue du SDK, non.
class CloudIndisponibleException implements Exception {
  const CloudIndisponibleException(this.operation);

  /// L'operation qui a ete refusee (pour le journal et le message).
  final String operation;

  @override
  String toString() =>
      'CloudIndisponibleException: « $operation » exige les services en ligne, '
      'qui ne sont pas configures sur cette installation (mode local).';
}
