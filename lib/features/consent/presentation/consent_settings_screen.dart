import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/consent_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';
import '../providers/consent_ui_providers.dart';
import 'consent_purpose_tile.dart';

/// Ecran de gestion du consentement dans les REGLAGES (D4A-02, design #86166).
///
/// Permet de consulter, modifier et RETIRER chaque consentement a tout moment
/// (RGPD : retrait aussi simple que l'octroi). Chaque finalite est independante
/// (granularite) ; la finalite SANTE (art 9) est isolee dans une section
/// dediee avec avertissement renforce. Une banniere invite a revoir les choix
/// si la politique a evolue. Lien vers la politique de confidentialite
/// (D4D-01). a11y via [Semantics] (delegue a [ConsentPurposeTile]).
class ConsentSettingsScreen extends ConsumerWidget {
  const ConsentSettingsScreen({this.onOpenPrivacyPolicy, super.key});

  /// Ouvre la politique de confidentialite (injecte pour testabilite).
  final VoidCallback? onOpenPrivacyPolicy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = Translations.of(context);
    final theme = Theme.of(context);
    final statesAsync = ref.watch(consentStatesProvider);
    final reviewNeededAsync = ref.watch(consentPromptNeededProvider);
    final controller = ref.read(consentControllerProvider);

    const standardPurposes = <ConsentPurpose>[
      ConsentPurpose.locationNavigation,
      ConsentPurpose.socialSharing,
      ConsentPurpose.publicReporting,
    ];

    return Scaffold(
      // Ph5 (L6d) : AppHeader universel (reglages consentement — §4 standard).
      appBar: AppHeader(title: tr.consent.settingsTitle),
      body: SafeArea(
        child: statesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (states) => ListView(
            padding: const EdgeInsets.all(AppTheme.spacingBase),
            children: [
              // Banniere : la politique a evolue, revoir les choix.
              if (reviewNeededAsync.value == true)
                AppCard(
                  backgroundColor: theme.colorScheme.tertiaryContainer,
                  padding: EdgeInsets.zero,
                  child: ListTile(
                    leading: const Icon(Icons.update),
                    title: Text(tr.consent.reviewNeeded),
                  ),
                ),
              Text(
                tr.consent.settingsIntro,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // --- TOUT REFUSER (tache 580, Y1) ---
              //
              // LE REFUS DOIT ETRE AUSSI SIMPLE QUE L'ACCORD (RGPD art. 7-3),
              // et l'intro juste au-dessus le promet en toutes lettres. Il ne
              // l'etait pas : accorder tenait en un geste par finalite, refuser
              // en bloc n'existait nulle part. Le libelle
              // `consent.declineAll` etait pourtant traduit dans les cinq
              // langues depuis le LOT 4 — sur un ecran d'accueil du
              // consentement qu'AUCUNE route n'ouvre.
              //
              // POURQUOI EN HAUT, ET PAS EN BAS DE LA LISTE. Un refus global
              // range sous quatre bascules et une section sante se merite ;
              // « aussi simple » veut dire visible sans faire defiler.
              //
              // POURQUOI UNE CONFIRMATION, ET POURQUOI ELLE NE ROMPT PAS LA
              // SYMETRIE. Ce geste-la EFFACE : il emporte la morphologie
              // (age, taille, poids), donnee de sante de l'article 9. Le dire
              // AU MOMENT DU CHOIX vaut mieux qu'une petite ligne grise
              // au-dessus de quatre bascules — et le refus reste le chemin le
              // moins couteux de l'ecran : deux gestes, contre quatre bascules
              // pour refuser finalite par finalite et quatre pour accorder.
              // L'article 7-3 demande que le retrait soit AUSSI SIMPLE que
              // l'octroi ; il l'est, et il est en plus explique.
              Semantics(
                button: true,
                label: tr.consent.declineAll,
                child: AppButton(
                  variant: AppButtonVariant.outline,
                  icon: Icons.block,
                  label: tr.consent.declineAll,
                  onPressed: () => _confirmerRefusGlobal(context, controller),
                ),
              ),
              const SizedBox(height: AppTheme.spacingMd),

              // --- Finalites standard ---
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingMd,
                ),
                child: Column(
                  children: [
                    for (final purpose in standardPurposes) ...[
                      ConsentPurposeTile(
                        purpose: purpose,
                        granted: states[purpose]?.granted ?? false,
                        onChanged: (value) =>
                            controller.set(purpose, granted: value),
                      ),
                      _DecisionDate(state: states[purpose]),
                      if (purpose != standardPurposes.last)
                        const Divider(height: 1),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // --- Section SANTE isolee (art 9) ---
              AppCard(
                backgroundColor:
                    theme.colorScheme.errorContainer.withAlpha(40),
                padding: const EdgeInsets.all(AppTheme.spacingMd),
                child: Semantics(
                  container: true,
                  label: tr.consent.a11y.healthSection,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.favorite_outline,
                            size: 20,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(width: AppTheme.spacingSm),
                          Expanded(
                            child: Text(
                              tr.consent.purposes.healthData,
                              style: theme.textTheme.titleMedium,
                            ),
                          ),
                          Chip(
                            label: Text(tr.consent.healthBadge),
                            visualDensity: VisualDensity.compact,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppTheme.spacingSm),
                      Text(
                        tr.consent.healthWarning,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      // CE QUE LE CONSENTEMENT COUVRE (tache 562, K3). Ce texte
                      // existait dans les cinq langues depuis le LOT 4 et
                      // n'etait affiche nulle part : le randonneur ignorait que
                      // l'autorisation sante porte aussi sa morphologie.
                      Text(
                        tr.consent.healthDataMorphoNote,
                        style: theme.textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppTheme.spacingXs),
                      // CE QUE LE REFUS COUTE (tache 562, K3). La garde art. 9
                      // posee sur le backup de la fiche medicale refuse sans
                      // accord ; refuser en silence ne renseigne personne.
                      Text(
                        tr.consent.healthBackupNote,
                        style: theme.textTheme.bodySmall,
                      ),
                      ConsentPurposeTile(
                        purpose: ConsentPurpose.healthData,
                        granted: states[ConsentPurpose.healthData]?.granted ??
                            false,
                        onChanged: (value) => controller.set(
                          ConsentPurpose.healthData,
                          granted: value,
                        ),
                        hideDescription: true,
                      ),
                      _DecisionDate(
                        state: states[ConsentPurpose.healthData],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppTheme.spacingLg),

              // --- Lien politique de confidentialite ---
              Semantics(
                button: true,
                label: tr.consent.a11y.policyButton,
                child: TextButton.icon(
                  onPressed: onOpenPrivacyPolicy,
                  icon: const Icon(Icons.description_outlined),
                  label: Text(tr.consent.privacyPolicyLink),
                ),
              ),
              const SizedBox(height: AppTheme.spacingXl),
            ],
          ),
        ),
      ),
    );
  }
}

/// LA CONFIRMATION DU REFUS GLOBAL (tache 580, Y1).
///
/// Elle dit, avant d'agir, CE QUE LE GESTE EMPORTE : les quatre autorisations
/// d'un coup, et la morphologie enregistree sur l'appareil. Le libelle de
/// confirmation est le MEME que celui du bouton qui a ouvert la boite — on
/// confirme le geste qu'on a demande, pas un « OK » qui ne veut rien dire.
Future<void> _confirmerRefusGlobal(
  BuildContext context,
  ConsentController controller,
) async {
  final tr = Translations.of(context);
  final confirme = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(tr.consent.declineAll),
      content: Text(tr.consent.declineAllNote),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text(tr.consent.declineAllCancel),
        ),
        TextButton(
          key: const ValueKey('consent-decline-all-confirm'),
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(tr.consent.declineAll),
        ),
      ],
    ),
  );
  if (confirme ?? false) await controller.declineAll();
}

/// Affiche la date de derniere decision (ou "en attente" si jamais decide).
class _DecisionDate extends StatelessWidget {
  const _DecisionDate({required this.state});

  final ConsentState? state;

  @override
  Widget build(BuildContext context) {
    final tr = Translations.of(context);
    final theme = Theme.of(context);
    final decidedAt = state?.decidedAt;

    final label = decidedAt == null
        ? tr.consent.notDecided
        : tr.consent.decidedOn(
            date: '${decidedAt.day.toString().padLeft(2, '0')}/'
                '${decidedAt.month.toString().padLeft(2, '0')}/'
                '${decidedAt.year}',
          );

    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppTheme.spacingSm),
        child: Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: AppTheme.grisGranite,
          ),
        ),
      ),
    );
  }
}
