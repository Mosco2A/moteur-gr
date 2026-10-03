/// Les blocs du BAS de la fiche, et ses deux gestes de fin.
///
/// Morceau de `health_info_screen.dart` (lot 645-06, vague 2) : meme
/// bibliotheque, donc aucune visibilite, aucun identifiant et
/// aucun site d appel ne changent.
part of 'health_info_screen.dart';

/// Section [3] : ce qui est vital.
class _HealthMedicalSection extends StatelessWidget {
  const _HealthMedicalSection({
    required this.allergiesController,
    required this.treatmentsController,
    required this.conditionsController,
    required this.bloodType,
    required this.bloodTypeHerite,
    required this.onBloodTypeChanged,
    required this.organDonor,
    required this.onOrganDonorChanged,
  });

  /// Les allergies, possedees par l'ecran.
  final TextEditingController allergiesController;

  /// Les traitements, possedes par l'ecran.
  final TextEditingController treatmentsController;

  /// Les antecedents, possedes par l'ecran.
  final TextEditingController conditionsController;

  /// Le groupe sanguin retenu.
  final String? bloodType;

  /// Le groupe sanguin herite d'une saisie libre.
  final String bloodTypeHerite;

  /// Le randonneur a choisi son groupe sanguin.
  final ValueChanged<String?> onBloodTypeChanged;

  /// La reponse au don d organes.
  final String? organDonor;

  /// Le randonneur a repondu au don d organes.
  final ValueChanged<String?> onOrganDonorChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ========================================== [3] VITAL
        _SectionTitle(
          key: const ValueKey('health-section-vital'),
          icon: StepwaysIcons.secours,
          title: t.health.section.vital,
          explanation: t.health.section.vitalWhy,
        ),
        // Texte libre medical : longueur BORNEE et VISIBLE
        // (compteur), plus de champ sans fond (2000 caracteres
        // illisibles en urgence).
        _ChampTexte(
          controller: allergiesController,
          label: t.health.field.allergies,
          hint: t.health.hint.allergies,
          icon: StepwaysIcons.danger,
          maxLines: 3,
          maxLength: kHealthFreeTextMaxLength,
        ),
        const SizedBox(height: AppTheme.spacingBase),
        _ChampTexte(
          controller: treatmentsController,
          label: t.health.field.treatments,
          hint: t.health.hint.treatments,
          icon: StepwaysIcons.ficheMedicale,
          maxLines: 3,
          maxLength: kHealthFreeTextMaxLength,
        ),
        const SizedBox(height: AppTheme.spacingBase),
        _ChampTexte(
          champKey: const ValueKey('health-conditions-field'),
          controller: conditionsController,
          label: t.health.field.conditions,
          hint: t.health.hint.conditions,
          icon: StepwaysIcons.historique,
          maxLines: 3,
          maxLength: kHealthFreeTextMaxLength,
        ),
        const SizedBox(height: AppTheme.spacingBase),
        _HealthBloodAndDonor(
          bloodType: bloodType,
          bloodTypeHerite: bloodTypeHerite,
          onBloodTypeChanged: onBloodTypeChanged,
          organDonor: organDonor,
          onOrganDonorChanged: onOrganDonorChanged,
        ),
      ],
    );
  }
}

/// Section [4] : l administratif.
class _HealthCardsSection extends StatelessWidget {
  const _HealthCardsSection({
    required this.doctorController,
    required this.insuranceController,
    required this.carteVitale,
    required this.carteMutuelle,
    required this.onPrendreCarte,
    required this.onRetirerCarte,
  });

  /// Le medecin traitant, possede par l'ecran.
  final TextEditingController doctorController;

  /// L'assurance, possedee par l'ecran.
  final TextEditingController insuranceController;

  /// Le nom du fichier de la carte vitale.
  final String carteVitale;

  /// Le nom du fichier de la mutuelle.
  final String carteMutuelle;

  /// Photographie la carte nommee.
  final void Function(String nom, ImageSource src) onPrendreCarte;

  /// Retire la carte nommee.
  final void Function(String nom) onRetirerCarte;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ================================== [4] ADMINISTRATIF
        _SectionTitle(
          key: const ValueKey('health-section-admin'),
          icon: StepwaysIcons.questionnaire,
          title: t.health.section.admin,
          explanation: t.health.section.adminWhy,
        ),
        _ChampTexte(
          controller: doctorController,
          label: t.health.field.doctor,
          hint: t.health.hint.doctor,
          icon: StepwaysIcons.secours,
          maxLines: 2,
          maxLength: kHealthContactMaxLength,
        ),
        const SizedBox(height: AppTheme.spacingBase),
        _ChampTexte(
          controller: insuranceController,
          label: t.health.field.insurance,
          hint: t.health.hint.insurance,
          icon: StepwaysIcons.bouclier,
          maxLines: 2,
          maxLength: kHealthContactMaxLength,
        ),
        const SizedBox(height: AppTheme.spacingBase),
        _CarteTile(
          key: const ValueKey('health-carte-vitale'),
          titre: t.health.cards.vitale,
          nomFichier: carteVitale,
          onPrendre: (src) =>
              onPrendreCarte(HealthInfoFile.nomCarteVitale, src),
          onRetirer: () => onRetirerCarte(HealthInfoFile.nomCarteVitale),
        ),
        const SizedBox(height: AppTheme.spacingBase),
        _CarteTile(
          key: const ValueKey('health-carte-mutuelle'),
          titre: t.health.cards.mutuelle,
          nomFichier: carteMutuelle,
          onPrendre: (src) =>
              onPrendreCarte(HealthInfoFile.nomCarteMutuelle, src),
          onRetirer: () => onRetirerCarte(HealthInfoFile.nomCarteMutuelle),
        ),
      ],
    );
  }
}

/// Les deux gestes de fin de fiche : enregistrer, et effacer.
class _HealthActions extends StatelessWidget {
  const _HealthActions({
    required this.isSaving,
    required this.isDeleting,
    required this.hasContent,
    required this.onSave,
    required this.onDelete,
  });

  /// Vrai pendant un enregistrement.
  final bool isSaving;

  /// Vrai pendant un effacement.
  final bool isDeleting;

  /// Vrai quand la fiche contient quelque chose.
  final bool hasContent;

  /// Enregistre la fiche.
  final VoidCallback onSave;

  /// Efface la fiche, apres confirmation.
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: AppTheme.spacingXl),
        // SW-SKIN-L3e : ElevatedButton.icon -> AppButton primary.
        // isLoading porte l'etat _isSaving (AppButton affiche son
        // spinner et desactive l'action, cf. grammaire unifiee) ;
        // minHeight 52 conserve la cible du CTA pleine largeur.
        // key/Semantics(button+label) preserves au-dessus.
        Semantics(
          button: true,
          label: t.health.a11y.saveButton,
          child: AppButton(
            isLoading: isSaving,
            minHeight: 52,
            icon: StepwaysIcons.enregistrer,
            label: t.health.save,
            onPressed: isSaving ? null : onSave,
          ),
        ),
        // E57 (L6) : bouton « Effacer ma fiche » — branche sur le
        // delete() DEJA present. Visible uniquement si la fiche
        // contient quelque chose (rien a effacer sinon). Action
        // DEFINITIVE annoncee aux lecteurs d'ecran, confirmation
        // obligatoire (rouge).
        if (hasContent) ...[
          const SizedBox(height: AppTheme.spacingBase),
          Semantics(
            button: true,
            label: t.health.delete.a11yButton,
            child: AppButton(
              variant: AppButtonVariant.outline,
              tone: AppTheme.rougeUrgence,
              isLoading: isDeleting,
              minHeight: 52,
              icon: StepwaysIcons.corbeille,
              label: t.health.delete.button,
              onPressed: isDeleting ? null : onDelete,
            ),
          ),
        ],
        const SizedBox(height: AppTheme.spacingBase),
        Text(
          t.health.emergencyHint,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall?.copyWith(
            color: colors.onSurface.withAlpha(140),
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

/// Les deux champs a LISTE FERMEE de la fiche : groupe sanguin et don
/// d organes.
///
/// Separes du reste de la section parce qu'ils ne se saisissent pas : on y
/// choisit dans une liste, et c'est precisement ce qui rend une valeur
/// inventee impossible.
class _HealthBloodAndDonor extends StatelessWidget {
  const _HealthBloodAndDonor({
    required this.bloodType,
    required this.bloodTypeHerite,
    required this.onBloodTypeChanged,
    required this.organDonor,
    required this.onOrganDonorChanged,
  });

  /// Le groupe sanguin retenu.
  final String? bloodType;

  /// Le groupe sanguin herite d'une saisie libre.
  final String bloodTypeHerite;

  /// Le randonneur a choisi son groupe sanguin.
  final ValueChanged<String?> onBloodTypeChanged;

  /// La reponse au don d organes.
  final String? organDonor;

  /// Le randonneur a repondu au don d organes.
  final ValueChanged<String?> onOrganDonorChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // GROUPE SANGUIN : LISTE FERMEE (tache 630). La saisie
        // libre a disparu — une valeur inventee n'est plus
        // seulement refusee, elle est IMPOSSIBLE.
        _ChampGroupeSanguin(
          key: const ValueKey('health-blood-type-field'),
          valeur: bloodType,
          valeurHeritee: bloodTypeHerite,
          onChanged: onBloodTypeChanged,
        ),
        const SizedBox(height: AppTheme.spacingBase),
        _ChampDonOrganes(
          key: const ValueKey('health-organ-donor-field'),
          valeur: organDonor,
          onChanged: onOrganDonorChanged,
        ),
      ],
    );
  }
}
