import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/utils/montant_en_euros.dart';

/// LE MONTANT S'ECRIT DANS LA LANGUE DU LECTEUR (tache 806).
///
/// Les valeurs de ce fichier sont MESUREES, pas supposees : elles ont ete lues
/// une premiere fois en faisant imprimer les unites de code de chaque rendu.
/// Deux d'entre elles ne se devinent pas, et c'est pour cela qu'on les nomme :
///
///  - l'espace qui precede le symbole en francais, allemand, italien et
///    espagnol est une ESPACE INSECABLE (U+00A0, 160), pas une espace
///    ordinaire. Les cinq fichiers de traduction ecrivaient une espace
///    ORDINAIRE : un prix pouvait donc se couper entre le nombre et le symbole
///    en bout de ligne. La table CLDR ne commet pas cette faute ;
///  - l'anglais place le symbole AVANT le nombre et sans espace, et il garde le
///    POINT decimal. C'est la seule des cinq langues dans ce cas.
///
/// CE QUE CE FICHIER VERIFIE AU FOND : que le separateur et la place du symbole
/// viennent de la LANGUE et non du code. Un `replaceAll('.', ',')` passerait le
/// cas francais et tomberait sur l'anglais ; c'est exactement ce que faisait
/// l'ecran de recharge avant cette tache.
const String insecable = ' ';

void main() {
  group('Le montant s ecrit dans la langue du lecteur (806)', () {
    test('francais : virgule, symbole apres, espace INSECABLE', () {
      expect(montantEnEuros(9.99, 'fr'), '9,99$insecable€');
      expect(montantEnEuros(19.99, 'fr'), '19,99$insecable€');
      expect(montantEnEuros(34.99, 'fr'), '34,99$insecable€');
    });

    test('anglais : point, symbole AVANT, sans espace', () {
      expect(montantEnEuros(9.99, 'en'), '€9.99');
      expect(montantEnEuros(19.99, 'en'), '€19.99');
    });

    test('allemand, italien et espagnol : virgule, symbole apres', () {
      for (final langue in <String>['de', 'it', 'es']) {
        expect(
          montantEnEuros(9.99, langue),
          '9,99$insecable€',
          reason: 'langue $langue',
        );
      }
    });

    test('un montant rond n affiche pas ses centimes', () {
      // La regle vient de l ecran d abonnement, ou 2,0 s ecrivait deja « 2 ».
      expect(montantEnEuros(2, 'fr'), '2$insecable€');
      expect(montantEnEuros(2, 'en'), '€2');
    });

    test('aucun rendu ne porte de POINT decimal hors anglais', () {
      // LE DEFAUT HISTORIQUE, EN UNE LIGNE : « 6.93 € » en francais.
      for (final langue in <String>['fr', 'de', 'it', 'es']) {
        expect(
          montantEnEuros(6.93, langue).contains('.'),
          isFalse,
          reason: 'langue $langue ne doit pas porter de point decimal',
        );
      }
    });
  });
}
