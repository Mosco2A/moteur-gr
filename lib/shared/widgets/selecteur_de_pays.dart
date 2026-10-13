/// SELECTEUR DE PAYS TRIE DANS LA LANGUE DU RANDONNEUR (tache 634, DEM-1124).
///
/// POURQUOI CE FICHIER EXISTE AU LIEU D'UN REGLAGE DU PAQUET. Le selecteur
/// fourni par `country_picker` affiche des noms TRADUITS mais les range dans
/// l'ordre de sa propre table, qui est l'ordre alphabetique ANGLAIS
/// (`country_codes.dart` : Afghanistan, Aland Islands, Albania, Algeria...).
/// Mesure faite sur la version epinglee 2.0.28 : il n'y a AUCUN `sort()` dans
/// tout le paquet, et son `countryFilter` ne fait qu'un `contains` — il ne
/// definit pas l'ordre. Aucun parametre de l'API ne permet donc de reordonner
/// la liste. Le tri devait sortir du paquet ; la liste des pays, elle, y reste
/// (246 pays x 35 langues embarquees, zero reseau, aucun nom ecrit a la main).
///
/// CE QUE CE SELECTEUR GARANTIT.
///  * L'ordre suit le libelle AFFICHE, dans la langue courante — donc il change
///    avec la langue, ce qui est le comportement attendu et ce qui n'existait
///    pas ;
///  * accents et casse sont ranges la ou on les cherche (« Egypte » a la lettre
///    E, « Allemagne » avant « Autriche ») via [comparerLibellesLocalises] ;
///  * la recherche par nom est conservee (246 pays : sans elle, personne ne
///    defile jusqu'a « Nouvelle-Zelande ») et elle ignore aussi les accents, si
///    bien que « egypte » tape sans accent trouve « Egypte » ;
///  * le pays choisi est rendu par son CODE ISO : c'est lui qu'on enregistre,
///    le nom n'est qu'un affichage.
library;

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';

import '../../core/branding/stepways_icons.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/tri_alphabetique_localise.dart';
import '../../i18n/translations.g.dart';

/// LE NOM D'UN PAYS DANS LA LANGUE COURANTE.
///
/// Trois sources, dans cet ordre :
///  1. le nom traduit du delegue [CountryLocalizations] pose sur la
///     `MaterialApp` (« France », « Deutschland », « Italia »...) ;
///  2. le nom anglais embarque dans le paquet, si le delegue n'est pas monte
///     (cas d'un test qui pompe l'ecran sans `localizationsDelegates`) ;
///  3. le code brut, pour les cinq territoires que la liste ISO connait et que
///     le selecteur ne propose pas (`AQ`, `BV`, `PN`, `TF`, `UM`) : une fiche
///     enregistree du temps de la saisie libre peut en porter un, et il vaut
///     mieux afficher « AQ » que rien.
String nomPaysLocalise(BuildContext context, String code) {
  final traduit = CountryLocalizations.of(
    context,
  )?.countryName(countryCode: code);
  if (traduit != null && traduit.isNotEmpty) return traduit;
  return Country.tryParse(code)?.name ?? code;
}

/// LA LISTE DES PAYS, TRIEE SUR LE LIBELLE AFFICHE DANS LA LANGUE COURANTE.
///
/// Fonction separee du widget pour qu'un test puisse verifier l'ORDRE sans
/// pomper d'ecran, langue par langue.
List<Country> paysTriesPourAffichage(BuildContext context) {
  final pays = List<Country>.of(CountryService().getAll());
  // Le paquet embarque des doublons quand l'indicatif telephonique differe
  // (un meme pays y figure plusieurs fois) : on choisit un PAYS, pas un
  // numero, donc on n'en garde qu'un par code ISO.
  final vus = <String>{};
  pays.retainWhere((p) => vus.add(p.countryCode));
  pays.sort(
    (a, b) => comparerLibellesLocalises(
      nomPaysLocalise(context, a.countryCode),
      nomPaysLocalise(context, b.countryCode),
    ),
  );
  return pays;
}

/// Ouvre la feuille de choix d'un pays. [onSelect] recoit le pays retenu.
Future<void> ouvrirSelecteurDePays(
  BuildContext context, {
  required ValueChanged<Country> onSelect,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    showDragHandle: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppTheme.radiusCard),
      ),
    ),
    builder: (_) => FeuilleDePays(onSelect: onSelect),
  );
}

/// Le contenu de la feuille : un titre, une recherche, la liste triee.
class FeuilleDePays extends StatefulWidget {
  const FeuilleDePays({super.key, required this.onSelect});

  final ValueChanged<Country> onSelect;

  @override
  State<FeuilleDePays> createState() => _FeuilleDePaysState();
}

class _FeuilleDePaysState extends State<FeuilleDePays> {
  final _recherche = TextEditingController();
  String _filtre = '';

  @override
  void dispose() {
    _recherche.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final tp = t.hikerProfile;

    // Le tri se refait a chaque construction : c'est ce qui fait qu'un
    // changement de langue reordonne la liste sans aucun cache a invalider.
    final pays = paysTriesPourAffichage(context);
    final clefFiltre = clefDeTriLocalisee(_filtre.trim());
    final visibles = clefFiltre.isEmpty
        ? pays
        : pays
              .where(
                (p) => clefDeTriLocalisee(
                  nomPaysLocalise(context, p.countryCode),
                ).contains(clefFiltre),
              )
              .toList(growable: false);

    return SizedBox(
      // La feuille occupe les trois quarts de l'ecran : assez pour voir une
      // dizaine de pays, pas assez pour masquer d'ou l'on vient.
      height: MediaQuery.sizeOf(context).height * 0.75,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppTheme.spacingBase,
          0,
          AppTheme.spacingBase,
          0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              tp.countryPickerTitle,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingBase),
            TextField(
              key: const ValueKey('country-picker-search'),
              controller: _recherche,
              style: theme.textTheme.bodyLarge,
              onChanged: (v) => setState(() => _filtre = v),
              decoration: InputDecoration(
                hintText: tp.countrySearchHint,
                prefixIcon: StepIcon(
                  StepwaysIcons.recherche,
                  color: colors.primary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.spacingBase),
            Expanded(
              child: visibles.isEmpty
                  ? Center(
                      key: const ValueKey('country-picker-empty'),
                      child: Text(
                        tp.countryNoResult,
                        style: theme.textTheme.bodyMedium,
                      ),
                    )
                  : ListView.builder(
                      key: const ValueKey('country-picker-list'),
                      itemCount: visibles.length,
                      itemBuilder: (context, i) {
                        final p = visibles[i];
                        return ListTile(
                          key: ValueKey('country-picker-${p.countryCode}'),
                          leading: Text(
                            p.flagEmoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          title: Text(
                            nomPaysLocalise(context, p.countryCode),
                            style: theme.textTheme.bodyLarge,
                          ),
                          onTap: () {
                            widget.onSelect(p);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
