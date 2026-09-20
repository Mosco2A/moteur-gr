/// Bornes metier de la saisie randonneur — SOURCE DE VERITE UNIQUE.
///
/// FIX-1 (rapport personas cycle4, finding B1) : le poids corporel etait borne
/// 30-150 kg avec un message clair sur la fiche morpho, et TOTALEMENT LIBRE sur
/// le bandeau « Materiel & Sac » (l'app affichait « Poids du sac : Infinity kg »).
/// La meme donnee doit porter la meme regle partout : ces constantes sont donc
/// sorties de l'ecran morpho pour etre partagees par TOUS les points de saisie
/// (fiche morpho, bandeau du sac, injection depuis le profil).
///
/// Ancrees sur BP_faisabilite_entrainement.md (profils randonneur) + mandat
/// LOT 1 (retour Chris #4). Elles servent A LA FOIS a la validation (submit),
/// aux garde-fous des providers et aux messages d'erreur bornes.
library;

/// Age minimum accepte (annees).
const int kAgeMin = 8;

/// Age maximum accepte (annees).
const int kAgeMax = 100;

/// Taille minimum acceptee (cm).
const int kHeightMinCm = 100;

/// Taille maximum acceptee (cm).
const int kHeightMaxCm = 250;

/// Poids corporel minimum accepte (kg). Voir [isValidBodyWeightKg].
const int kWeightMinKg = 30;

/// Poids corporel maximum accepte (kg). Voir [isValidBodyWeightKg].
const int kWeightMaxKg = 150;

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
