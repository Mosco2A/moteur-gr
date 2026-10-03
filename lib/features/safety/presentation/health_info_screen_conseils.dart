/// Ce qui se dit autour de la fiche : le prix de la promesse,
/// la carte du telephone, le mode d emploi et le consentement.
///
/// Morceau de `health_info_screen.dart` (lot 645-06, vague 2) : meme
/// bibliotheque, donc aucune visibilite, aucun identifiant et
/// aucun site d appel ne changent.
part of 'health_info_screen.dart';

/// LA RECOPIE DANS LA FICHE D'URGENCE DU TELEPHONE — UNE ETAPE (tache 630).
///
/// POURQUOI CE BLOC EXISTE, ET POURQUOI IL EST EN HAUT. La mesure du 29/09
/// (documentation Apple et Google) a etabli que SUR IPHONE aucune application
/// tierce ne peut montrer une fiche complete sans deverrouillage : ce que les
/// premiers intervenants atteignent est la fiche du SYSTEME, et Apple n'offre
/// aucune API pour y ecrire. Sur Android notre notification y arrive, mais le
/// randonneur peut masquer les notifications sensibles de son ecran verrouille.
///
/// LA RECOPIE EST DONC LE SEUL CHEMIN QUI MARCHE PARTOUT. Elle etait une ligne
/// de conseil parmi quatre depuis la tache 568 ; elle devient un geste avec un
/// etat, rappele tant qu'il n'est pas fait.
class _PhoneCardStep extends ConsumerWidget {
  const _PhoneCardStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final fait = ref
        .watch(healthPrepareStepsProvider)
        .contains(HealthPrepStep.phoneCardCopied);
    return Container(
      key: const ValueKey('health-phone-card-step'),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: fait
            ? colors.primary.withAlpha(16)
            : AppTheme.rougeUrgence.withAlpha(20),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(
          color: fait
              ? colors.primary.withAlpha(60)
              : AppTheme.rougeUrgence.withAlpha(110),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StepIcon(
                fait ? StepwaysIcons.cochePleine : StepwaysIcons.cadenas,
                size: 20,
                color: fait ? colors.primary : AppTheme.rougeUrgence,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  t.health.phoneCard.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: fait ? colors.primary : AppTheme.rougeUrgence,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingXs),
          Text(
            t.health.phoneCard.why,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurface.withAlpha(215),
            ),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // LE GESTE EST REVOCABLE : on peut avoir efface la fiche du telephone,
          // ou en avoir change. Le randonneur doit pouvoir retrouver son rappel.
          CheckboxListTile(
            key: const ValueKey('health-phone-card-done'),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: fait,
            title: Text(t.health.phoneCard.done),
            onChanged: (v) => ref
                .read(healthPrepareStepsProvider.notifier)
                .setPhoneCardCopied(v ?? false),
          ),
        ],
      ),
    );
  }
}

/// LE PRIX DE LA PROMESSE « CETTE FICHE NE QUITTE PAS CE TELEPHONE » (tache 612).
///
/// POURQUOI CE BLOC EXISTE. La decision de Christophe du 28/09 10:42 supprime
/// toute sauvegarde distante de la fiche medicale. Elle a un prix, et il l'a
/// assume en majuscules : changer de telephone, c'est ressaisir son groupe
/// sanguin, ses allergies, ses traitements. Un prix qu'on decouvre le jour ou on
/// change d'appareil est une mauvaise surprise ; un prix qu'on lit en remplissant
/// est un choix. Il est donc dit ICI, et avant les champs.
///
/// IL NE SE CONFOND PAS AVEC LE BANDEAU DE CONFIANCE AU-DESSUS. Celui-la dit ce
/// que nous ne faisons pas ; celui-ci dit ce que cela coute au randonneur. Les
/// deux ensemble font une promesse tenable — l'un sans l'autre fait une promesse
/// qui se retourne.
class _LocalOnlyPrice extends StatelessWidget {
  const _LocalOnlyPrice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      key: const ValueKey('health-local-only-price'),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer.withAlpha(90),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: colors.onSurface.withAlpha(45)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StepIcon(
            StepwaysIcons.effacerTelephone,
            size: 20,
            color: colors.onSurface.withAlpha(180),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.health.localOnlyPriceTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppTheme.spacingXs),
                Text(
                  t.health.localOnlyPrice,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withAlpha(215),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// CONSEILS D'USAGE TERRAIN de la fiche medicale + ACCUSE DE LECTURE (tache 568,
/// LOT Q — decision de Chris du 26/09 10:29).
///
/// CE QUE CHRIS A DEMANDE, verbatim : « on ne demarre pas un trek sans avoir
/// rempli sa fiche medicale et lu les conseils pour qu'elle soit applicable sur
/// le sentier ». « Applicable sur le sentier » est la cle : une fiche parfaite
/// que personne ne sait ou trouver ni comment montrer ne sert a rien le jour de
/// l'accident.
///
/// LES QUATRE CHOSES QUE CES CONSEILS DISENT, et pourquoi chacune :
///  1. OU LA TROUVER QUAND ON EST A TERRE — le blesse n'ouvre pas son telephone
///     lui-meme ; ses compagnons doivent savoir ou aller AVANT le depart.
///  2. COMMENT LA MONTRER AUX SECOURS — tendre l'ecran, dans l'ordre des
///     informations dont un secouriste a besoin.
///  3. POURQUOI LA RECOPIER DANS LA FICHE MEDICALE DU TELEPHONE — elle s'affiche
///     ECRAN VERROUILLE, sans code : c'est le seul chemin qui fonctionne quand
///     le secouriste ne connait pas cette application (la cle
///     `sos.medicalId.hint` le disait deja, sans que personne ne l'explique).
///     TACHE 630 : ce conseil a maintenant SON PROPRE BLOC, au-dessus, avec un
///     etat — parce que la mesure a montre que c'est le seul chemin qui marche
///     sur iPhone. Il reste ici pour que la liste des quatre gestes du terrain
///     demeure complete.
///  4. QU'UN PAPIER NE TOMBE JAMAIS EN PANNE DE BATTERIE — le telephone est le
///     maillon faible de tout ce dispositif ; l'admettre est plus utile que le
///     cacher.
///
/// ACCUSE DE LECTURE, PAS TEXTE DISPONIBLE : afficher un texte ne prouve pas
/// qu'il a ete lu. Le geste est explicite et IRREVOCABLE (on ne « delit » pas un
/// conseil), il est persiste par [healthPrepareStepsProvider] et il entre dans la
/// porte de demarrage du trek. Une fois fait, l'invitation devient une
/// confirmation — pas une case qu'on peut decocher par megarde.
class _UsageAdvice extends ConsumerWidget {
  const _UsageAdvice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final a = t.health.advice;
    final lu = ref
        .watch(healthPrepareStepsProvider)
        .contains(HealthPrepStep.adviceRead);

    return Container(
      key: const ValueKey('health-usage-advice'),
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.primary.withAlpha(16),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: colors.primary.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StepIcon(StepwaysIcons.journal, size: 20, color: colors.primary),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  a.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.spacingSm),
          // Les quatre conseils, dans l'ordre de l'urgence reelle : d'abord ou
          // elle est, ensuite comment la montrer, puis les deux filets (fiche du
          // telephone, papier).
          _AdviceLine(icon: StepwaysIcons.repere, text: a.whereToFind),
          _AdviceLine(icon: StepwaysIcons.pouce, text: a.showToRescue),
          _AdviceLine(icon: StepwaysIcons.bouclier, text: a.phoneCard),
          _AdviceLine(icon: StepwaysIcons.cgu, text: a.paper),
          const SizedBox(height: AppTheme.spacingSm),
          if (lu)
            Row(
              children: [
                StepIcon(
                  StepwaysIcons.cochePleine,
                  size: 20,
                  color: colors.primary,
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Expanded(
                  child: Text(
                    a.ackDone,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            )
          else
            Semantics(
              button: true,
              label: a.ackButton,
              child: AppButton(
                key: const ValueKey('health-advice-ack'),
                variant: AppButtonVariant.outline,
                icon: StepwaysIcons.coche,
                label: a.ackButton,
                onPressed: () => ref
                    .read(healthPrepareStepsProvider.notifier)
                    .markAdviceRead(),
              ),
            ),
        ],
      ),
    );
  }
}

/// Une ligne de conseil : puce iconique + texte (jamais de texte en dur).
class _AdviceLine extends StatelessWidget {
  const _AdviceLine({required this.icon, required this.text});

  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: StepIcon(
              icon,
              size: 18,
              color: theme.colorScheme.onSurface.withAlpha(150),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(215),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Rappel de FINALITE + lien vers la gestion du consentement sante (E57/H1).
///
/// Forme souple (ARBITRAGES H1-a) : rappelle que ces infos servent a secourir et
/// restent sur le telephone, et offre un acces a l'ecran Confidentialite
/// (finalite healthData). Ne bloque PAS la saisie (local-only, pas de
/// « traitement » au sens strict). Textes Slang (5 langues).
class _ConsentReminder extends StatelessWidget {
  const _ConsentReminder({required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withAlpha(60),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              StepIcon(
                StepwaysIcons.info,
                size: 18,
                color: colors.onSurface.withAlpha(160),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  t.health.consent.purpose,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.onSurface.withAlpha(200),
                  ),
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              key: const ValueKey('health-consent-manage'),
              variant: AppButtonVariant.text,
              icon: StepwaysIcons.bouclier,
              iconSize: 18,
              label: t.health.consent.manage,
              isFullWidth: false,
              onPressed: onManage,
            ),
          ),
        ],
      ),
    );
  }
}
