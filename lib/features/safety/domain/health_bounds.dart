/// Bornes et controles de la FICHE D'URGENCE — donnees VITALES (SOS).
///
/// FIX-1 (rapport personas cycle4, finding M6) : l'ecran `/health` portait un
/// `Form` avec une `_formKey`... jamais validee (`_save()` n'appelait PAS
/// `validate()`). Le formulaire etait DECORATIF : « XYZ123!! » passait pour un
/// groupe sanguin et le champ allergies avalait 2000 caracteres. Or ces champs
/// sont ceux qu'un secouriste lit en urgence : une donnee fausse y est pire
/// qu'une donnee absente.
///
/// ---------------------------------------------------------------------------
/// TACHE 630 — LE GROUPE SANGUIN N'EST PLUS UNE SAISIE LIBRE
/// ---------------------------------------------------------------------------
///
/// Christophe, le 29/09 (DEM-260929-1135) : il n'existe que HUIT groupes, la
/// saisie libre n'a donc aucune raison d'exister sur une fiche d'urgence.
///
/// SOURCE, Etablissement francais du sang, « Tout savoir sur les groupes
/// sanguins » : la combinaison du systeme ABO (A, B, AB, O) et du systeme Rhesus
/// (D+ / D-) donne HUIT groupes sanguins — A+, A-, B+, B-, AB+, AB-, O+, O-.
/// <https://dondesang.efs.sante.fr/articles/tout-savoir-sur-les-groupes-sanguins>
///
/// LA LISTE FERMEE PORTE UNE NEUVIEME VALEUR, ET CE N'EST PAS UN CONFORT :
/// [kBloodTypeUnknown]. Beaucoup de gens ne connaissent pas leur groupe. Sans
/// cette valeur, ils laissent le champ vide — et « vide » ne se distingue plus
/// de « pas encore rempli ». « Je ne sais pas » est une REPONSE : elle dit au
/// secouriste qu'il ne trouvera pas l'information ailleurs dans le telephone,
/// et elle lui epargne de la chercher.
///
/// UNE VALEUR HERITEE NON RECONNUE N'EST JAMAIS EFFACEE EN SILENCE : voir
/// [valeurListeGroupeSanguin], qui rend `null`, et l'ecran qui affiche alors la
/// valeur d'origine au randonneur pour qu'il choisisse. La consigne de la tache
/// 630 est explicite — « les fiches deja saisies ne perdent RIEN ».
library;

/// Groupes sanguins valides (systeme ABO + Rhesus), forme canonique.
///
/// SOURCE : Etablissement francais du sang (voir l'en-tete du fichier).
/// L'ORDRE N'EST PAS ALPHABETIQUE ET C'EST VOULU : il suit le systeme ABO puis
/// le Rhesus, comme la carte de groupe sanguin elle-meme. Un randonneur qui
/// cherche « A+ » dans une liste le trouve en premier, pas au milieu.
const List<String> kBloodTypesOrdonnes = [
  'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', //
];

/// Groupes sanguins valides, en ensemble (appartenance).
const Set<String> kBloodTypes = {
  'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', //
};

/// LA NEUVIEME VALEUR DE LA LISTE FERMEE : « je ne sais pas ».
///
/// Elle est STOCKEE, comme les huit autres. Un champ vide dit « je n'ai pas
/// rempli » ; cette valeur dit « j'ai rempli, et la reponse est que je
/// l'ignore ». Les deux ne s'affichent pas pareil a un secouriste.
const String kBloodTypeUnknown = 'inconnu';

/// LES NEUF VALEURS QUE LA LISTE PROPOSE, DANS L'ORDRE DE L'ECRAN.
const List<String> kBloodTypeChoices = [
  ...kBloodTypesOrdonnes,
  kBloodTypeUnknown,
];

/// DON D'ORGANES — LISTE FERMEE DE TROIS VALEURS (tache 630).
///
/// SOURCE : c'est un champ de la fiche medicale du telephone. Apple, « Configurer
/// votre fiche medicale » : « Votre decision de faire don d'organes est
/// accessible aux autres dans votre fiche medicale »
/// <https://support.apple.com/fr-fr/105072>.
///
/// POURQUOI TROIS VALEURS ET PAS UNE CASE A COCHER. En France le consentement au
/// don est PRESUME : une case non cochee ne veut donc pas dire « refus », elle ne
/// veut rien dire du tout. Trois valeurs distinctes disent trois choses
/// differentes — et le champ vide en dit une quatrieme : « pas renseigne ».
const String kOrganDonorYes = 'donneur';

/// Don d'organes : opposition exprimee.
const String kOrganDonorNo = 'oppose';

/// Don d'organes : la personne n'a pas fait de choix, et le dit.
const String kOrganDonorUnknown = 'inconnu';

/// Les trois valeurs proposees, dans l'ordre de l'ecran.
const List<String> kOrganDonorChoices = [
  kOrganDonorYes,
  kOrganDonorNo,
  kOrganDonorUnknown,
];

/// La valeur a selectionner pour ce qui est sur le disque, ou `null`.
String? valeurListeDonOrganes(String raw) {
  final nettoye = raw.trim().toLowerCase();
  if (nettoye.isEmpty) return null;
  return kOrganDonorChoices.contains(nettoye) ? nettoye : null;
}

/// Longueur max du champ groupe sanguin (« AB+ » = 3 caracteres).
///
/// CONSERVE ALORS QUE LA SAISIE EST DEVENUE UNE LISTE : la borne protege encore
/// la donnee qui vient du DISQUE (une fiche ecrite par une version precedente),
/// pas seulement celle qui vient du clavier.
const int kBloodTypeMaxLength = 3;

/// Longueur max des champs de texte libre medicaux (allergies, traitements,
/// antecedents).
///
/// Assez pour une liste reelle de traitements, assez court pour rester lisible
/// d'un coup d'oeil sur l'ecran d'urgence.
const int kHealthFreeTextMaxLength = 200;

/// Longueur max des champs de contact (medecin, numero d'assurance).
const int kHealthContactMaxLength = 100;

/// Longueur max du nom et prenom du randonneur (tache 630).
///
/// C'est la PREMIERE ligne que lit un secouriste : elle doit tenir sur une
/// ligne, y compris dans une notification d'ecran verrouille.
const int kHealthNameMaxLength = 80;

/// Longueur max de l'adresse (tache 630).
const int kHealthAddressMaxLength = 160;

/// NOMBRE MAXIMUM DE CONTACTS A PREVENIR SAISIS PAR LE RANDONNEUR (tache 630).
///
/// Ce n'est pas une limite technique, c'est une limite d'URGENCE : un secouriste
/// qui voit douze numeros n'en appelle aucun. Trois tiennent sur un ecran
/// verrouille et se lisent en un coup d'oeil. Les numeros de secours (112,
/// secours regionaux du sentier) ne comptent PAS dedans : ils sont ajoutes par
/// l'application, pas par le randonneur.
const int kMaxPersonalEmergencyContacts = 3;

/// Longueur max du nom d'un contact a prevenir.
const int kEmergencyContactNameMaxLength = 60;

/// Longueur max d'un numero de telephone de contact a prevenir.
///
/// Un numero international au format E.164 fait au plus 15 chiffres ; on laisse
/// la place aux espaces, aux points et a l'indicatif ecrit « +33 (0)6 ... ».
const int kEmergencyContactPhoneMaxLength = 30;

/// Forme canonique d'un groupe sanguin saisi : majuscules, sans espaces.
String normalizeBloodType(String raw) =>
    raw.replaceAll(RegExp(r'\s+'), '').toUpperCase();

/// Vrai si [raw] est un groupe sanguin reconnu (casse et espaces ignores).
///
/// La chaine vide est geree par l'appelant : le champ reste OPTIONNEL (vide =
/// non renseigne), c'est une valeur INVENTEE qui est refusee. « Je ne sais pas »
/// n'est PAS un groupe sanguin : il est reconnu par [valeurListeGroupeSanguin],
/// pas ici.
bool isValidBloodType(String raw) => kBloodTypes.contains(normalizeBloodType(raw));

/// LA VALEUR A SELECTIONNER DANS LA LISTE FERMEE POUR CE QUI EST SUR LE DISQUE.
///
/// Rend :
///  * `null` si [raw] est vide — rien n'est selectionne, le champ est vierge ;
///  * `null` AUSSI si [raw] ne correspond a rien de connu — et c'est le point
///    qui compte : l'ecran affiche alors la valeur d'origine au randonneur et
///    lui demande de choisir. RIEN N'EST EFFACE EN SILENCE (consigne 630 :
///    « les fiches deja saisies ne perdent RIEN ») ;
///  * [kBloodTypeUnknown] si la fiche porte deja « je ne sais pas » ;
///  * le groupe canonique sinon (« a+ » sur le disque -> « A+ » a l'ecran).
String? valeurListeGroupeSanguin(String raw) {
  final nettoye = raw.trim();
  if (nettoye.isEmpty) return null;
  if (nettoye.toLowerCase() == kBloodTypeUnknown) return kBloodTypeUnknown;
  final canonique = normalizeBloodType(nettoye);
  return kBloodTypes.contains(canonique) ? canonique : null;
}

/// Vrai si ce qui est sur le disque n'est NI vide NI une valeur de la liste.
///
/// C'est le cas d'une fiche remplie avant que la validation existe (FIX-1) ou
/// avant que la liste soit fermee (tache 630). L'ecran s'en sert pour AVERTIR au
/// lieu d'effacer.
bool estGroupeSanguinHerite(String raw) =>
    raw.trim().isNotEmpty && valeurListeGroupeSanguin(raw) == null;
