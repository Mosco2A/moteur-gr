import 'package:flutter/services.dart';

/// Limiteur de longueur qui PREVIENT quand il tronque.
///
/// FIX-1 (rapport personas cycle4, finding m1) : sur la fiche morpho, taper
/// « 1280 » dans le champ Taille donnait « 128 » — resultat correct, mais
/// l'utilisateur n'etait PAS averti que sa saisie avait ete amputee. Une
/// modification silencieuse de la saisie est un mensonge, au meme titre qu'un
/// clamp silencieux.
///
/// Ce formateur garde la BARRIERE PHYSIQUE (le champ ne depasse jamais
/// [maxLength], garde-fou LOT 1 #4 contre « 8000 cm ») et ajoute l'information
/// manquante : [onLimitReached] est appele des qu'une frappe est refusee, pour
/// que l'ecran affiche un message borne.
///
/// Le callback n'est PAS appele quand la valeur etait deja trop longue avant la
/// frappe (ex. texte injecte par le code) et n'a pas ete rallongee : seule une
/// tentative de depassement de l'utilisateur declenche le message.
class NotifyingLengthLimitingTextInputFormatter extends TextInputFormatter {
  NotifyingLengthLimitingTextInputFormatter(
    this.maxLength, {
    required this.onLimitReached,
  }) : assert(maxLength > 0);

  /// Nombre maximum de caracteres autorises dans le champ.
  final int maxLength;

  /// Appele quand une frappe est refusee parce que la limite est atteinte.
  final void Function() onLimitReached;

  late final LengthLimitingTextInputFormatter _delegate =
      LengthLimitingTextInputFormatter(maxLength);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final result = _delegate.formatEditUpdate(oldValue, newValue);
    // Tronque = la saisie proposee etait plus longue que ce qui ressort, ET
    // l'utilisateur essayait bien d'ajouter du texte (sinon c'est une simple
    // correction / suppression, rien a signaler).
    if (newValue.text.length > result.text.length &&
        newValue.text.length > oldValue.text.length) {
      onLimitReached();
    }
    return result;
  }
}
