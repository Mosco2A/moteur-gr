/// Le haut et le bas du formulaire de la fiche.
///
/// Morceau de `health_info_screen.dart` (lot 645-06, vague 2) : meme
/// bibliotheque, donc aucune visibilite, aucun identifiant et
/// aucun site d appel ne changent.
part of 'health_info_screen.dart';

/// Le HAUT du formulaire : le bandeau de confiance, ce qui se dit avant
/// la saisie, qui vous etes et qui prevenir.
///
/// L'ETAT RESTE CHEZ L'ECRAN : controleurs, liste de contacts et
/// mutations arrivent en parametres nommes.
class _HealthFormTop extends StatelessWidget {
  const _HealthFormTop({
    required this.fullNameController,
    required this.addressController,
    required this.birthDate,
    required this.onChoisirDate,
    required this.onEffacerDate,
    required this.contacts,
    required this.onRemoveContact,
    required this.onAddContact,
  });

  /// Le nom complet, possede par l'ecran.
  final TextEditingController fullNameController;

  /// L'adresse, possedee par l'ecran.
  final TextEditingController addressController;

  /// La date de naissance, au format ISO.
  final String birthDate;

  /// Ouvre le choix de la date.
  final VoidCallback onChoisirDate;

  /// Retire la date saisie.
  final VoidCallback onEffacerDate;

  /// Les lignes de contact, possedees par l'ecran.
  final List<_LigneContact> contacts;

  /// Retire la ligne d'indice donne.
  final void Function(int index) onRemoveContact;

  /// Ajoute une ligne vide.
  final VoidCallback onAddContact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        const _HealthSafetyBanner(),
        const SizedBox(height: AppTheme.spacingMd),
        _HealthIntro(onManageConsent: () => context.push('/consent')),
        const SizedBox(height: AppTheme.spacingLg),
        _HealthIdentitySection(
          fullNameController: fullNameController,
          addressController: addressController,
          birthDate: birthDate,
          onChoisirDate: onChoisirDate,
          onEffacerDate: onEffacerDate,
        ),
        const SizedBox(height: AppTheme.spacingLg),
        _HealthContactsSection(
          contacts: contacts,
          onRemoveContact: onRemoveContact,
          onAddContact: onAddContact,
        ),
        const SizedBox(height: AppTheme.spacingLg),
      ],
    );
  }
}

/// Le BAS du formulaire : ce qui est vital, l administratif, puis les
/// deux gestes de fin.
///
/// L'ETAT RESTE CHEZ L'ECRAN : controleurs, valeurs et mutations
/// arrivent en parametres nommes.
class _HealthFormBottom extends StatelessWidget {
  const _HealthFormBottom({
    required this.allergiesController,
    required this.treatmentsController,
    required this.conditionsController,
    required this.bloodType,
    required this.bloodTypeHerite,
    required this.onBloodTypeChanged,
    required this.organDonor,
    required this.onOrganDonorChanged,
    required this.doctorController,
    required this.insuranceController,
    required this.carteVitale,
    required this.carteMutuelle,
    required this.onPrendreCarte,
    required this.onRetirerCarte,
    required this.isSaving,
    required this.isDeleting,
    required this.hasContent,
    required this.onSave,
    required this.onDelete,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        _HealthMedicalSection(
          allergiesController: allergiesController,
          treatmentsController: treatmentsController,
          conditionsController: conditionsController,
          bloodType: bloodType,
          bloodTypeHerite: bloodTypeHerite,
          onBloodTypeChanged: onBloodTypeChanged,
          organDonor: organDonor,
          onOrganDonorChanged: onOrganDonorChanged,
        ),
        const SizedBox(height: AppTheme.spacingLg),
        _HealthCardsSection(
          doctorController: doctorController,
          insuranceController: insuranceController,
          carteVitale: carteVitale,
          carteMutuelle: carteMutuelle,
          onPrendreCarte: onPrendreCarte,
          onRetirerCarte: onRetirerCarte,
        ),
        _HealthActions(
          isSaving: isSaving,
          isDeleting: isDeleting,
          hasContent: hasContent,
          onSave: onSave,
          onDelete: onDelete,
        ),
      ],
    );
  }
}
