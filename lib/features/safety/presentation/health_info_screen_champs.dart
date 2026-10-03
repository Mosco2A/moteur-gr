/// Les champs de la fiche : titres de section, listes fermees,
/// date de naissance et cartes photographiees.
///
/// Morceau de `health_info_screen.dart` (lot 645-06, vague 2) : meme
/// bibliotheque, donc aucune visibilite, aucun identifiant et
/// aucun site d appel ne changent.
part of 'health_info_screen.dart';

/// Un titre de section de la fiche, avec la RAISON de sa place.
///
/// L'explication n'est pas un ornement : elle dit au randonneur pourquoi ce bloc
/// est la ou il est, donc pourquoi il vaut la peine d'etre rempli. « Un
/// secouriste lit d'abord qui vous etes » fait remplir le nom ; un champ « Nom »
/// tout seul se saute.
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    super.key,
    required this.icon,
    required this.title,
    required this.explanation,
  });

  /// Chemin d'une icone Stepways ([StepwaysIcons]), et non un [IconData].
  ///
  /// FUSION 633 : le lot 632 a bascule les widgets partages de l'application
  /// sur le jeu de Christophe ([StepIcon], trace SVG), pendant que le lot 630
  /// reecrivait cet ecran contre l'ancien type. Ce titre de section suit le
  /// reste de l'application, sinon la fiche de sante serait le seul ecran
  /// reste en icones Material.
  final String icon;
  final String title;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StepIcon(icon, size: 20, color: colors.primary),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            explanation,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withAlpha(170),
            ),
          ),
        ],
      ),
    );
  }
}

/// LE GROUPE SANGUIN — LISTE FERMEE DE HUIT + « JE NE SAIS PAS » (tache 630).
///
/// Christophe, le 29/09 : huit groupes existent, la saisie libre n'a aucune
/// raison d'etre sur une fiche d'urgence. Un groupe mal saisi y est PIRE qu'un
/// champ vide, parce qu'un secouriste s'y fie.
///
/// LA VALEUR HERITEE NON RECONNUE EST MONTREE, PAS EFFACEE. Une fiche remplie
/// avant que la validation existe peut porter n'importe quoi. Le randonneur voit
/// ce qu'il avait ecrit et choisit — la consigne 630 est explicite : « les fiches
/// deja saisies ne perdent RIEN ».
class _ChampGroupeSanguin extends StatelessWidget {
  const _ChampGroupeSanguin({
    super.key,
    required this.valeur,
    required this.valeurHeritee,
    required this.onChanged,
  });

  final String? valeur;
  final String valeurHeritee;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          initialValue: valeur,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: t.health.field.bloodType,
            prefixIcon: StepIcon(
              StepwaysIcons.ficheMedicale,
              color: colors.primary,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusInput),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusInput),
              borderSide: BorderSide(color: colors.onSurface.withAlpha(60)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusInput),
              borderSide: BorderSide(color: colors.primary, width: 2),
            ),
          ),
          hint: Text(t.health.hint.bloodType),
          items: [
            for (final v in kBloodTypeChoices)
              DropdownMenuItem<String>(
                value: v,
                child: Text(
                  v == kBloodTypeUnknown ? t.health.bloodTypeUnknown : v,
                ),
              ),
          ],
          onChanged: onChanged,
        ),
        if (valeurHeritee.isNotEmpty) ...[
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            key: const ValueKey('health-blood-type-legacy'),
            t.health.bloodTypeLegacy(valeur: valeurHeritee),
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.rougeUrgence,
            ),
          ),
        ],
      ],
    );
  }
}

/// Le don d'organes — liste fermee de trois valeurs (tache 630).
class _ChampDonOrganes extends StatelessWidget {
  const _ChampDonOrganes({
    super.key,
    required this.valeur,
    required this.onChanged,
  });

  final String? valeur;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    String libelle(String v) => switch (v) {
      kOrganDonorYes => t.health.organDonor.yes,
      kOrganDonorNo => t.health.organDonor.no,
      _ => t.health.organDonor.unknown,
    };
    return DropdownButtonFormField<String>(
      initialValue: valeur,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: t.health.field.organDonor,
        prefixIcon: StepIcon(StepwaysIcons.pouce, color: colors.primary),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          borderSide: BorderSide(color: colors.onSurface.withAlpha(60)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
      ),
      hint: Text(t.health.hint.organDonor),
      items: [
        for (final v in kOrganDonorChoices)
          DropdownMenuItem<String>(value: v, child: Text(libelle(v))),
      ],
      onChanged: onChanged,
    );
  }
}

/// La date de naissance : un selecteur, jamais un clavier.
///
/// UN CLAVIER LAISSERAIT ECRIRE « 32/13/1850 » et il faudrait le refuser apres
/// coup, en cinq langues, avec cinq formats de date differents. Le selecteur du
/// systeme est deja localise et ne peut rendre qu'une date valide.
class _ChampDateNaissance extends StatelessWidget {
  const _ChampDateNaissance({
    super.key,
    required this.valeurIso,
    required this.onChoisir,
    required this.onEffacer,
  });

  final String valeurIso;
  final VoidCallback onChoisir;
  final VoidCallback onEffacer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final date = DateTime.tryParse(valeurIso);
    // AFFICHAGE LOCALISE, STOCKAGE NEUTRE : `formatCompactDate` rend la date
    // dans la convention de la langue active (03/04 n'est pas la meme date des
    // deux cotes de la Manche).
    final affichee = date == null
        ? ''
        : MaterialLocalizations.of(context).formatCompactDate(date);
    return InkWell(
      onTap: onChoisir,
      borderRadius: BorderRadius.circular(AppTheme.radiusInput),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: t.health.field.birthDate,
          hintText: t.health.hint.birthDate,
          prefixIcon: StepIcon(StepwaysIcons.age, color: colors.primary),
          suffixIcon: affichee.isEmpty
              ? null
              : IconButton(
                  key: const ValueKey('health-birth-date-clear'),
                  icon: const StepIcon(StepwaysIcons.croix),
                  tooltip: t.health.field.birthDateClear,
                  onPressed: onEffacer,
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusInput),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusInput),
            borderSide: BorderSide(color: colors.onSurface.withAlpha(60)),
          ),
        ),
        child: Text(
          affichee.isEmpty ? t.health.hint.birthDate : affichee,
          style: TextStyle(
            color: affichee.isEmpty
                ? colors.onSurface.withAlpha(90)
                : colors.onSurface,
          ),
        ),
      ),
    );
  }
}

/// UNE PHOTO DE CARTE — VITALE OU MUTUELLE (tache 630).
///
/// Demande de Christophe le 29/09 : « photo des 2 », « tout reste sur le tel ».
/// L'image vit dans le MEME dossier protege que la fiche ; cette tuile ne fait
/// que la montrer, la remplacer ou la retirer.
///
/// L'APERCU EST PETIT, ET C'EST DELIBERE : une carte d'assurance maladie affichee
/// en grand sur un ecran qu'on tend a un inconnu n'a pas besoin d'etre lisible de
/// loin. On appuie pour l'agrandir quand on en a besoin.
class _CarteTile extends StatelessWidget {
  const _CarteTile({
    super.key,
    required this.titre,
    required this.nomFichier,
    required this.onPrendre,
    required this.onRetirer,
  });

  final String titre;
  final String nomFichier;
  final ValueChanged<ImageSource> onPrendre;
  final VoidCallback onRetirer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final aUnePhoto = nomFichier.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: colors.onSurface.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StepIcon(
                aUnePhoto ? StepwaysIcons.portefeuille : StepwaysIcons.photo,
                size: 20,
                color: colors.primary,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  titre,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (aUnePhoto)
                IconButton(
                  key: ValueKey('$nomFichier-remove'),
                  icon: const StepIcon(StepwaysIcons.corbeille),
                  tooltip: t.health.cards.remove,
                  onPressed: onRetirer,
                ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            aUnePhoto ? t.health.cards.stored : t.health.cards.explain,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withAlpha(170),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // `Wrap` ET PAS `Row`, ET C'EST UNE MESURE, PAS UNE PRECAUTION. Une
          // `Row` de ces deux boutons deborde de 279 pixels sur un ecran de
          // 360 px — c'est-a-dire sur la moitie des telephones vendus. Et la
          // longueur des deux libelles change dans chacune des cinq langues :
          // « Prendre en photo » fait 16 caracteres, « Foto neu aufnehmen » en
          // fait 18. Aucune largeur fixe ne tient cinq langues ; un retour a la
          // ligne, si.
          Wrap(
            spacing: AppTheme.spacingSm,
            children: [
              AppButton(
                variant: AppButtonVariant.text,
                icon: StepwaysIcons.photo,
                iconSize: 18,
                label: aUnePhoto ? t.health.cards.retake : t.health.cards.take,
                isFullWidth: false,
                onPressed: () => onPrendre(ImageSource.camera),
              ),
              AppButton(
                variant: AppButtonVariant.text,
                icon: StepwaysIcons.photo,
                iconSize: 18,
                label: t.health.cards.pick,
                isFullWidth: false,
                onPressed: () => onPrendre(ImageSource.gallery),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
