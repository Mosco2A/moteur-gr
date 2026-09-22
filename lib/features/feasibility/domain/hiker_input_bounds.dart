/// Bornes metier de la saisie randonneur — SOURCE DE VERITE UNIQUE.
///
/// FIX-1 (rapport personas cycle4, finding B1) : le poids corporel etait borne
/// avec un message clair sur la fiche morpho, et TOTALEMENT LIBRE sur
/// le bandeau « Materiel & Sac » (l'app affichait « Poids du sac : Infinity kg »).
/// La meme donnee doit porter la meme regle partout : ces constantes sont donc
/// sorties de l'ecran morpho pour etre partagees par TOUS les points de saisie
/// (fiche morpho, bandeau du sac, injection depuis le profil).
///
/// Ancrees sur BP_faisabilite_entrainement.md (profils randonneur) + mandat
/// LOT 1 (retour Chris #4). Elles servent A LA FOIS a la validation (submit),
/// aux garde-fous des providers et aux messages d'erreur bornes.
///
/// PRINCIPE POSE PAR CHRIS LE 22/09 (decisions #100327 puis #100328). IL PRIME
/// SUR TOUT LE RESTE ET S'APPLIQUE PARTOUT DANS L'APPLICATION :
/// UNE BORNE DE SAISIE ATTRAPE UNE FAUTE DE FRAPPE. Elle ne decide pas qui a le
/// droit d'exister ni qui a le droit de randonner. Elle n'ecarte QUE
/// l'impossible.
///
/// Les bornes precedentes (8-100 ans, 100-250 cm, 30-150 kg) jugeaient des
/// morphologies humaines REELLES : une personne de petite taille par
/// achondroplasie, ou un randonneur de 160 kg, ne pouvaient simplement pas
/// creer leur fiche. Ce n'etait pas un garde-fou, c'etait une exclusion a la
/// porte d'entree — et elle frappait exactement les randonneurs pour qui le
/// dispositif de charge du sac a le plus de valeur.
///
/// Les valeurs ci-dessous sont donc calees sur des REPERES D'USAGE, et non sur
/// des limites theoriques de l'espece :
///  - 120 ans : le record humain documente est de 122 ans ;
///  - 255 cm : le plus grand homme vivant mesure 251 cm — l'ancienne borne de
///    250 le ratait d'un centimetre ;
///  - 200 kg : au-dela on ne marche plus un sentier ; en dessous des gens
///    marchent vraiment, notamment ceux qui s'y mettent pour perdre du poids.
///
/// Toute modification de ces six constantes doit repercuter les messages
/// `hikerProfile.errorAge` / `errorHeight` / `errorWeight` des 5 fichiers
/// `assets/i18n/*.i18n.json`, qui citent les bornes en toutes lettres.
library;

/// Age minimum accepte (annees). L'application s'adresse a des adultes.
const int kAgeMin = 18;

/// Age maximum accepte (annees). Record humain documente : 122 ans.
const int kAgeMax = 120;

/// Taille minimum acceptee (cm).
const int kHeightMinCm = 60;

/// Taille maximum acceptee (cm). Plus grand homme vivant : 251 cm.
const int kHeightMaxCm = 255;

/// Poids corporel minimum accepte (kg). Voir [isValidBodyWeightKg].
const int kWeightMinKg = 25;

/// Poids corporel maximum accepte (kg). Voir [isValidBodyWeightKg].
const int kWeightMaxKg = 200;

/// Vrai si [kg] est un poids corporel ACCEPTABLE (fini et dans les bornes).
///
/// Le test `isFinite` est essentiel : `double.tryParse('Infinity')` rend
/// `double.infinity`, qui passait tous les anciens garde-fous « > 0 » et
/// remontait jusqu'a l'affichage (finding B1). NaN est rejete pour la meme
/// raison.
bool isValidBodyWeightKg(double kg) =>
    kg.isFinite && kg >= kWeightMinKg && kg <= kWeightMaxKg;

/// Codes pays ISO 3166-1 alpha-2 officiellement attribues.
///
/// FIX-1 (finding m3) : le champ pays acceptait « ZZ » (code inexistant) sans
/// aucun controle. Liste figee ici (donnee de reference stable, hors reseau —
/// l'app reste utilisable hors-ligne).
const Set<String> kIsoCountryCodes = {
  'AD', 'AE', 'AF', 'AG', 'AI', 'AL', 'AM', 'AO', 'AQ', 'AR', 'AS', 'AT', //
  'AU', 'AW', 'AX', 'AZ', 'BA', 'BB', 'BD', 'BE', 'BF', 'BG', 'BH', 'BI',
  'BJ', 'BL', 'BM', 'BN', 'BO', 'BQ', 'BR', 'BS', 'BT', 'BV', 'BW', 'BY',
  'BZ', 'CA', 'CC', 'CD', 'CF', 'CG', 'CH', 'CI', 'CK', 'CL', 'CM', 'CN',
  'CO', 'CR', 'CU', 'CV', 'CW', 'CX', 'CY', 'CZ', 'DE', 'DJ', 'DK', 'DM',
  'DO', 'DZ', 'EC', 'EE', 'EG', 'EH', 'ER', 'ES', 'ET', 'FI', 'FJ', 'FK',
  'FM', 'FO', 'FR', 'GA', 'GB', 'GD', 'GE', 'GF', 'GG', 'GH', 'GI', 'GL',
  'GM', 'GN', 'GP', 'GQ', 'GR', 'GS', 'GT', 'GU', 'GW', 'GY', 'HK', 'HM',
  'HN', 'HR', 'HT', 'HU', 'ID', 'IE', 'IL', 'IM', 'IN', 'IO', 'IQ', 'IR',
  'IS', 'IT', 'JE', 'JM', 'JO', 'JP', 'KE', 'KG', 'KH', 'KI', 'KM', 'KN',
  'KP', 'KR', 'KW', 'KY', 'KZ', 'LA', 'LB', 'LC', 'LI', 'LK', 'LR', 'LS',
  'LT', 'LU', 'LV', 'LY', 'MA', 'MC', 'MD', 'ME', 'MF', 'MG', 'MH', 'MK',
  'ML', 'MM', 'MN', 'MO', 'MP', 'MQ', 'MR', 'MS', 'MT', 'MU', 'MV', 'MW',
  'MX', 'MY', 'MZ', 'NA', 'NC', 'NE', 'NF', 'NG', 'NI', 'NL', 'NO', 'NP',
  'NR', 'NU', 'NZ', 'OM', 'PA', 'PE', 'PF', 'PG', 'PH', 'PK', 'PL', 'PM',
  'PN', 'PR', 'PS', 'PT', 'PW', 'PY', 'QA', 'RE', 'RO', 'RS', 'RU', 'RW',
  'SA', 'SB', 'SC', 'SD', 'SE', 'SG', 'SH', 'SI', 'SJ', 'SK', 'SL', 'SM',
  'SN', 'SO', 'SR', 'SS', 'ST', 'SV', 'SX', 'SY', 'SZ', 'TC', 'TD', 'TF',
  'TG', 'TH', 'TJ', 'TK', 'TL', 'TM', 'TN', 'TO', 'TR', 'TT', 'TV', 'TW',
  'TZ', 'UA', 'UG', 'UM', 'US', 'UY', 'UZ', 'VA', 'VC', 'VE', 'VG', 'VI',
  'VN', 'VU', 'WF', 'WS', 'YE', 'YT', 'ZA', 'ZM', 'ZW',
};

/// Vrai si [code] est un code pays ISO 3166-1 alpha-2 attribue.
///
/// La casse est ignoree ; les espaces sont ignores. Le champ pays restant
/// OPTIONNEL, la chaine vide est geree par l'appelant (vide = non renseigne).
bool isValidIsoCountryCode(String code) =>
    kIsoCountryCodes.contains(code.trim().toUpperCase());
