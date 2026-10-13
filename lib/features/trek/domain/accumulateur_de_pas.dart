/// L'ACCUMULATEUR DE PAS (lot 671-02) : une classe pure, sans Flutter ni
/// greffon, qui transforme les valeurs BRUTES du podometre en un nombre de pas
/// depuis le debut de la session, et qui ne recule jamais.
///
/// LE FAIT MATERIEL DONT TOUT DECOULE : le compteur de pas du telephone compte
/// depuis le DERNIER REDEMARRAGE DE L'APPAREIL, pas depuis le debut de la
/// randonnee. Il livre ses evenements PAR PAQUETS, depuis une file du systeme,
/// pendant que le reste de l'application dort : un trou de livraison n'est
/// pas un arret, et un bond de plusieurs centaines de pas n'est pas une
/// anomalie.
library;

/// Ce que le podometre permet au lot 671-03 : estimer la position entre deux
/// points GPS, ou non, et pourquoi. Vocabulaire FERME, ecrit tel quel dans la
/// ligne de compteurs du journal de mesure (`podometre=`).
enum EstimateReadiness {
  /// Le podometre est autorise et son flux n'a pas failli.
  possible('possible'),

  /// L'autorisation d'activite physique est refusee.
  permissionRefused('autorisation_refusee'),

  /// Le telephone n'a pas de compteur de pas.
  podometerUnavailable('podometre_indisponible'),

  /// Le flux du podometre a leve une erreur.
  streamError('flux_en_erreur');

  const EstimateReadiness(this.word);

  /// Le mot ecrit au journal et dans les preferences.
  final String word;

  /// L'etat nomme [word] ; nul pour tout mot inconnu ou absent.
  static EstimateReadiness? fromWord(String? word) {
    for (final readiness in values) {
      if (readiness.word == word) return readiness;
    }
    return null;
  }

  /// L'etat qu'une erreur du flux revele. Le greffon du podometre signale un
  /// telephone sans capteur par un message « not available » ; toute autre
  /// erreur est une panne du flux.
  static EstimateReadiness forError(Object error) =>
      error.toString().toLowerCase().contains('not available')
      ? podometerUnavailable
      : streamError;
}

/// Le total de pas consolide d'une session.
class StepAccumulator {
  /// Une session neuve : aucun pas, origine prise au premier evenement.
  StepAccumulator();

  /// Une session REPRISE apres une fermeture de l'application : le total
  /// persiste est garde, et [lastRaw] (la derniere valeur brute vue) sert
  /// d'origine. Les pas faits application fermee sont donc comptes, puisque
  /// le capteur, lui, n'a pas cesse de compter.
  StepAccumulator.resumed({required int total, required int? lastRaw})
    : _banked = total,
      _lastRaw = lastRaw,
      _resumed = true;

  int _banked = 0;
  int? _lastRaw;
  bool _resumed = false;
  bool _failed = false;

  /// LE TOTAL CONSOLIDE depuis le debut de la session ; NUL sans aucun
  /// evenement ou apres une erreur du flux. Un nul se raconte, un zero
  /// mentirait en affirmant que le randonneur n'a pas bouge.
  int? get total => _failed || (_lastRaw == null && !_resumed) ? null : _banked;

  /// Les pas gardes, meme apres une erreur : ce qui est persiste.
  int get banked => _banked;

  /// La derniere valeur brute vue, origine du prochain evenement.
  int? get lastRaw => _lastRaw;

  /// Vrai apres une erreur du flux.
  bool get failed => _failed;

  /// Ajoute une valeur BRUTE du capteur.
  ///
  /// Le premier evenement donne l'origine et n'ajoute aucun pas. Un bond,
  /// meme de plusieurs centaines de pas, est compte tel quel. UNE VALEUR QUI
  /// RECULE SIGNIFIE UN REDEMARRAGE DU TELEPHONE : les pas deja comptes sont
  /// gardes, une nouvelle origine est prise a la valeur courante, et le
  /// compte repart de la. Le total ne diminue jamais.
  void add(int raw) {
    final last = _lastRaw;
    if (last != null && raw >= last) _banked += raw - last;
    _lastRaw = raw;
  }

  /// Note une erreur du flux : le total devient nul, les pas gardes restent.
  void fail() => _failed = true;
}
