/// Les blocs du HAUT de la fiche.
///
/// Morceau de `health_info_screen.dart` (lot 645-06, vague 2) : meme
/// bibliotheque, donc aucune visibilite, aucun identifiant et
/// aucun site d appel ne changent.
part of 'health_info_screen.dart';

/// Le bandeau de confiance en tete de la fiche (message de confiance, RF-2).
class _HealthSafetyBanner extends StatelessWidget {
  const _HealthSafetyBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.primary.withAlpha(30),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: colors.primary.withAlpha(80)),
      ),
      child: Row(
        children: [
          StepIcon(StepwaysIcons.cadenas, color: colors.primary, size: 20),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              t.health.privacyBanner,
              style: theme.textTheme.bodySmall?.copyWith(color: colors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ce qui se dit AVANT la saisie : le prix de la promesse, le rappel de
/// consentement, la carte du telephone et le mode d emploi.
class _HealthIntro extends StatelessWidget {
  const _HealthIntro({required this.onManageConsent});

  /// Ouvre la gestion du consentement.
  final VoidCallback onManageConsent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // LE PRIX DE LA PROMESSE, DIT ICI ET MAINTENANT (tache
        // 612). Le bandeau du dessus promet que la fiche ne quitte
        // pas le telephone ; celui-ci dit ce que cette promesse
        // coute. Christophe l'a assume en majuscules : changer de
        // telephone, c'est ressaisir son groupe sanguin, ses
        // allergies, ses traitements. Ce prix doit etre lu AU
        // MOMENT OU LA FICHE SE REMPLIT, pas decouvert le jour du
        // changement d'appareil — et il est place AVANT les champs
        // pour la meme raison que les conseils du LOT Q.
        const _LocalOnlyPrice(),
        const SizedBox(height: AppTheme.spacingMd),
        // E57 (L6/H1) : rappel de FINALITE + lien vers la gestion du
        // consentement (art. 9 RGPD). Forme SOUPLE (reco ARBITRAGES
        // H1-a) : aucun envoi n'a lieu (local-only), on rappelle
        // l'usage « te secourir » et on offre l'acces a l'ecran
        // Confidentialite (finalite healthData) — pas de mur avant
        // saisie. Textes Slang.
        _ConsentReminder(onManage: onManageConsent),
        const SizedBox(height: AppTheme.spacingMd),
        // LA RECOPIE DANS LA FICHE DU TELEPHONE — ETAPE, PLUS
        // CONSEIL (tache 630). C'est le SEUL chemin qui montre
        // quelque chose a un secouriste sur iPhone. Elle est donc
        // au-dessus des champs, pas noyee dans une liste.
        const _PhoneCardStep(),
        const SizedBox(height: AppTheme.spacingMd),
        // CONSEILS D'USAGE TERRAIN + ACCUSE DE LECTURE (tache 568,
        // LOT Q). Decision de Chris du 26/09, verbatim : « on ne
        // demarre pas un trek sans avoir rempli sa fiche medicale
        // ET LU LES CONSEILS pour qu'elle soit applicable sur le
        // sentier ». Les conseils sont donc AVANT les champs : on
        // apprend a s'en servir, puis on la remplit — et non
        // l'inverse, d'autant que l'enregistrement depile l'ecran.
        const _UsageAdvice(),
      ],
    );
  }
}

/// Section [1] : qui vous etes.
class _HealthIdentitySection extends StatelessWidget {
  const _HealthIdentitySection({
    required this.fullNameController,
    required this.addressController,
    required this.birthDate,
    required this.onChoisirDate,
    required this.onEffacerDate,
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ============================================ [1] QUI
        _SectionTitle(
          key: const ValueKey('health-section-identity'),
          icon: StepwaysIcons.monCompte,
          title: t.health.section.identity,
          explanation: t.health.section.identityWhy,
        ),
        _ChampTexte(
          champKey: const ValueKey('health-full-name-field'),
          controller: fullNameController,
          label: t.health.field.fullName,
          hint: t.health.hint.fullName,
          icon: StepwaysIcons.monCompte,
          maxLines: 1,
          maxLength: kHealthNameMaxLength,
          showCounter: false,
          textCapitalization: TextCapitalization.words,
        ),
        const SizedBox(height: AppTheme.spacingBase),
        _ChampDateNaissance(
          key: const ValueKey('health-birth-date-field'),
          valeurIso: birthDate,
          onChoisir: onChoisirDate,
          onEffacer: onEffacerDate,
        ),
        const SizedBox(height: AppTheme.spacingBase),
        _ChampTexte(
          champKey: const ValueKey('health-address-field'),
          controller: addressController,
          label: t.health.field.address,
          hint: t.health.hint.address,
          icon: StepwaysIcons.ville,
          maxLines: 2,
          maxLength: kHealthAddressMaxLength,
        ),
      ],
    );
  }
}

/// Section [2] : qui prevenir.
class _HealthContactsSection extends StatelessWidget {
  const _HealthContactsSection({
    required this.contacts,
    required this.onRemoveContact,
    required this.onAddContact,
  });

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
        // =================================== [2] QUI PREVENIR
        _SectionTitle(
          key: const ValueKey('health-section-contacts'),
          icon: StepwaysIcons.telephone,
          title: t.health.section.contacts,
          explanation: t.health.section.contactsWhy,
        ),
        _LignesDeContact(contacts: contacts, onRemove: onRemoveContact),
        if (contacts.length < kMaxPersonalEmergencyContacts)
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              key: const ValueKey('health-add-contact'),
              variant: AppButtonVariant.text,
              icon: StepwaysIcons.plus,
              iconSize: 18,
              label: t.health.contacts.add,
              isFullWidth: false,
              onPressed: () => onAddContact(),
            ),
          ),
      ],
    );
  }
}
