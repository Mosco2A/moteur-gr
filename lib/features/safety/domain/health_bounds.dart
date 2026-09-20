/// Bornes et controles de la FICHE SANTE — donnees VITALES (SOS).
///
/// FIX-1 (rapport personas cycle4, finding M6) : l'ecran `/health` portait un
/// `Form` avec une `_formKey`... jamais validee (`_save()` n'appelait PAS
/// `validate()`). Le formulaire etait DECORATIF : « XYZ123!! » passait pour un
/// groupe sanguin et le champ allergies avalait 2000 caracteres. Or ces champs
/// sont ceux qu'un secouriste lit en urgence : une donnee fausse y est pire
/// qu'une donnee absente.
library;

/// Groupes sanguins valides (systeme ABO + Rhesus), forme canonique.
const Set<String> kBloodTypes = {
  'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', //
};

/// Longueur max du champ groupe sanguin (« AB+ » = 3 caracteres).
const int kBloodTypeMaxLength = 3;

/// Longueur max des champs de texte libre medicaux (allergies, traitements).
///
/// Assez pour une liste reelle de traitements, assez court pour rester lisible
/// d'un coup d'oeil sur l'ecran d'urgence.
const int kHealthFreeTextMaxLength = 200;

/// Longueur max des champs de contact (medecin, numero d'assurance).
const int kHealthContactMaxLength = 100;

/// Forme canonique d'un groupe sanguin saisi : majuscules, sans espaces.
String normalizeBloodType(String raw) =>
    raw.replaceAll(RegExp(r'\s+'), '').toUpperCase();

/// Vrai si [raw] est un groupe sanguin reconnu (casse et espaces ignores).
///
/// La chaine vide est geree par l'appelant : le champ reste OPTIONNEL (vide =
/// non renseigne), c'est une valeur INVENTEE qui est refusee.
bool isValidBloodType(String raw) => kBloodTypes.contains(normalizeBloodType(raw));
