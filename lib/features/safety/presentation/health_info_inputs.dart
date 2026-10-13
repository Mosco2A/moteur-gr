/// Le champ de texte de la fiche, les lignes de contact, et la ligne de
/// contact en cours d edition avec ses controleurs.
///
/// Bibliotheque de l'ecran `health_info_screen.dart` (lot 645-06b).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../domain/health_bounds.dart';
import '../../../core/branding/stepways_icons.dart';

/// Un champ de texte de la fiche, dans la grammaire visuelle de l'ecran.
///
/// REMPLACE L ANCIENNE METHODE `_buildField` (ECR-28) : un sous-widget nomme se
/// reconstruit independamment, une methode privee de l'ecran non. Le controleur
/// est CREE ET LIBERE par l'ecran ; ce widget ne fait que s'y brancher, donc
/// aucun etat ne change de main.
class HealthTextField extends StatelessWidget {
  const HealthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.champKey,
    this.maxLines = 1,
    this.maxLength,
    this.showCounter = true,
    this.textCapitalization = TextCapitalization.none,
    this.keyboardType,
    this.validator,
  });

  /// Le controleur du champ, possede par l'ecran.
  final TextEditingController controller;

  /// Le libelle flottant du champ.
  final String label;

  /// L'exemple affiche quand le champ est vide.
  final String hint;

  /// L'icone posee en tete du champ.
  final String icon;

  /// La cle posee sur le TextFormField lui-meme, comme avant l'extraction :
  /// c'est elle que les tests cherchent pour saisir du texte.
  final Key? champKey;

  /// Le nombre de lignes du champ.
  final int maxLines;

  /// La limite de saisie, quand il y en a une.
  final int? maxLength;

  /// Le compteur est VISIBLE par defaut sur les champs bornes.
  final bool showCounter;

  /// La capitalisation automatique du clavier.
  final TextCapitalization textCapitalization;

  /// Le type de clavier a presenter.
  final TextInputType? keyboardType;

  /// La validation du champ, jouee par le Form de l'ecran.
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return TextFormField(
      key: champKey,
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      keyboardType: keyboardType,
      validator: validator,
      style: TextStyle(color: colors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        // Compteur VISIBLE par defaut sur les champs bornes : la limite doit se
        // voir, une coupe muette serait le meme mensonge qu'un clamp muet.
        counterText: showCounter ? null : '',
        errorMaxLines: 3,
        hintStyle: TextStyle(
          color: colors.onSurface.withAlpha(90),
          fontSize: 13,
        ),
        prefixIcon: StepIcon(icon, color: colors.primary),
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
    );
  }
}

/// Les lignes de contact a prevenir, avec leur bouton de retrait.
///
/// L'ETAT RESTE CHEZ L'ECRAN : la liste [contacts] et ses controleurs sont
/// crees, remplis et liberes par l'ecran ; le retrait passe par [onRemove].
class ContactLinesEditor extends StatelessWidget {
  const ContactLinesEditor({
    super.key,
    required this.contacts,
    required this.onRemove,
  });

  /// Les lignes de contact saisies, possedees par l'ecran.
  final List<ContactLineDraft> contacts;

  /// Retire la ligne d'indice donne.
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < contacts.length; i++)
          _LigneDeContact(
            key: ValueKey('health-contact-$i'),
            ligne: contacts[i],
            index: i,
            onRemove: onRemove,
          ),
      ],
    );
  }
}

/// Une ligne de contact : son nom, son numero, et le bouton qui la retire.
class _LigneDeContact extends StatelessWidget {
  const _LigneDeContact({
    required this.ligne,
    required this.index,
    required this.onRemove,
    super.key,
  });

  /// Les deux controleurs de la ligne, possedes par l'ecran.
  final ContactLineDraft ligne;

  /// L'indice de la ligne, qui nomme ses cles de test.
  final int index;

  /// Retire cette ligne.
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: HealthTextField(
                  champKey: ValueKey('health-contact-name-$index'),
                  controller: ligne.nomCtrl,
                  label: t.health.contacts.name,
                  hint: t.health.contacts.nameHint,
                  icon: StepwaysIcons.myAccount,
                  maxLength: kEmergencyContactNameMaxLength,
                  showCounter: false,
                  textCapitalization: TextCapitalization.words,
                  // UN NOM SANS NUMERO NE SERT A RIEN : le secouriste lit un
                  // prenom et n'a personne a appeler. On refuse
                  // l'enregistrement plutot que d'enregistrer une promesse
                  // vide.
                  validator: (_) =>
                      ligne.estVide || ligne.nomCtrl.text.trim().isNotEmpty
                      ? null
                      : t.health.contacts.errorName,
                ),
              ),
              IconButton(
                key: ValueKey('health-contact-remove-$index'),
                tooltip: t.health.contacts.remove,
                icon: const StepIcon(StepwaysIcons.croix),
                onPressed: () => onRemove(index),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          HealthTextField(
            champKey: ValueKey('health-contact-phone-$index'),
            controller: ligne.telCtrl,
            label: t.health.contacts.phone,
            hint: t.health.contacts.phoneHint,
            icon: StepwaysIcons.telephone,
            maxLength: kEmergencyContactPhoneMaxLength,
            showCounter: false,
            keyboardType: TextInputType.phone,
            validator: (_) =>
                ligne.estVide || ligne.telCtrl.text.trim().isNotEmpty
                ? null
                : t.health.contacts.errorPhone,
          ),
        ],
      ),
    );
  }
}

/// UNE LIGNE DE CONTACT EN COURS D'EDITION.
///
/// Les controleurs vivent ici et pas dans une liste parallele : une liste de
/// controleurs indexee a cote d'une liste de contacts se desynchronise des le
/// premier retrait au milieu, et le randonneur voit le telephone d'un proche
/// passer sous le nom d'un autre. Sur une fiche d'urgence, ce n'est pas un
/// defaut cosmetique.
class ContactLineDraft {
  /// Une ligne pre-remplie par [nom] et [telephone] (vides par defaut).
  ContactLineDraft({String nom = '', String telephone = ''})
    : nomCtrl = TextEditingController(text: nom),
      telCtrl = TextEditingController(text: telephone);

  /// Controleur du nom du contact.
  final TextEditingController nomCtrl;

  /// Controleur du telephone du contact.
  final TextEditingController telCtrl;

  /// Vrai quand ni le nom ni le telephone ne sont remplis.
  bool get estVide =>
      nomCtrl.text.trim().isEmpty && telCtrl.text.trim().isEmpty;

  /// Libere les deux controleurs.
  void dispose() {
    nomCtrl.dispose();
    telCtrl.dispose();
  }
}
