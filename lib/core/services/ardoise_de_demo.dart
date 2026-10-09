/// CE QU'UNE DEMO ECRIT N'ATTEINT PAS LE TELEPHONE : IL VA SUR UNE ARDOISE
/// (tache 760).
///
/// ---------------------------------------------------------------------------
/// POURQUOI UNE ARDOISE, ET PAS UN SIMPLE REFUS D'ECRIRE
/// ---------------------------------------------------------------------------
///
/// Enregistrer sa fiche pendant une demo appelle d'abord
/// `noterUneModificationDesDonnees` (qui fait monter un compteur de revision)
/// PUIS `grant` (qui pose la decision de consentement). Ignorer les deux
/// purement et simplement laisserait `needsPrompt` repondre « il faut
/// redemander » en boucle : la case a cocher se decocherait toute seule d'un
/// ecran a l'autre, et la demonstration aurait l'air cassee.
///
/// L'ardoise rend donc la demo COHERENTE AVEC ELLE-MEME — la decision est
/// prise, elle tient le temps de la demo — sans qu'un octet descende dans les
/// preferences du randonneur.
///
/// ---------------------------------------------------------------------------
/// POURQUOI UN NUMERO DE DEMO, ET PAS UN ECOUTEUR DE PROVIDER
/// ---------------------------------------------------------------------------
///
/// L'ardoise doit etre VIDE au debut de chaque demo, sinon la deuxieme demo
/// repart avec les decisions de la premiere. Le service qui la porte n'est,
/// lui, jamais reconstruit : il tient un flux diffuse que l'ordonnanceur de
/// synchronisation ecoute, et le recreer le fermerait sous les pieds de ses
/// abonnes.
///
/// UN ECOUTEUR SUR `enDemoProvider` NE SUFFIT PAS, et c'est une garde de ce lot
/// qui l'a montre : Riverpod ne recalcule pas un provider dont la dependance a
/// retrouve sa valeur precedente. Entrer, sortir, puis rentrer rend `true`
/// apres `true` : la chaine reste dormante et l'ardoise de la demo precedente
/// est resservie telle quelle.
///
/// Comparer un entier qui ne redescend jamais ([generationDeDemoProvider]) ne
/// depend, lui, d'aucune propagation : si le numero a change, l'ardoise est
/// perimee, point.
library;

/// Une ardoise de demo : des valeurs tenues EN MEMOIRE, jetees des que la demo
/// change de numero.
///
/// Elle ne connait ni Riverpod ni les preferences : on lui passe de quoi LIRE
/// le numero de la demo en cours, et elle se perime toute seule.
class ArdoiseDeDemo {
  /// [generation] rend le numero de la demo en cours. `null` = pas de demo du
  /// tout : l'ardoise reste alors vide et inoffensive.
  ArdoiseDeDemo({int Function()? generation}) : _generation = generation;

  final int Function()? _generation;

  final Map<String, Object> _valeurs = <String, Object>{};

  /// Le numero de demo auquel le contenu actuel correspond.
  int _numeroVu = 0;

  /// LE CONTENU, PERIME D'OFFICE QUAND LA DEMO A CHANGE.
  Map<String, Object> get _courant {
    final numero = _generation?.call() ?? 0;
    if (numero != _numeroVu) {
      _numeroVu = numero;
      _valeurs.clear();
    }
    return _valeurs;
  }

  /// La valeur texte posee sous [cle] pendant cette demo, ou `null`.
  String? texte(String cle) {
    final v = _courant[cle];
    return v is String ? v : null;
  }

  /// La valeur entiere posee sous [cle] pendant cette demo, ou `null`.
  int? entier(String cle) {
    final v = _courant[cle];
    return v is int ? v : null;
  }

  /// Pose [valeur] sous [cle] pour la duree de cette demo.
  void poser(String cle, Object valeur) => _courant[cle] = valeur;
}
