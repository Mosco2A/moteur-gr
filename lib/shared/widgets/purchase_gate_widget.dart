import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/monetization_service.dart';
import '../../core/theme/app_theme.dart';
import '../../i18n/translations.g.dart';
import 'paywall_sheet.dart';
import '../../core/branding/stepways_icons.dart';

/// Widget gate qui encapsule un ecran et verifie l'achat du trek (E4.17).
///
/// ┌─────────────────────────────────────────────────────────────────────────┐
/// │ ATTENTION — CE WIDGET N'EST MONTE NULLE PART DANS `lib/`.                │
/// └─────────────────────────────────────────────────────────────────────────┘
///
/// MESURE DE LA TACHE 614 : recherche de `PurchaseGateWidget` dans tout `lib/`
/// = sa propre definition, plus une mention en commentaire dans
/// `monetization_service.dart`. AUCUN ecran ne l'encapsule. Il a pourtant
/// quatre tests qui passent — ils montent le widget eux-memes. C'est donc un
/// test qui rassure sans rien garder, exactement le defaut que le lot 601 a
/// traque dans les commentaires.
///
/// ET C'EST LA CAUSE D'UN DEFAUT COMMERCIAL REEL, pas une coquetterie : c'est
/// PARCE QUE ce bandeau n'etait monte nulle part que le cockpit de preparation
/// n'avait AUCUN chemin d'achat avant la tache 614 — le seul existait sur le
/// bouton de depart. Le chemin est desormais pose par [HubBuyTrekButton], qui
/// lit la meme source ([isDemoModeProvider]) et ne depend pas de ce widget.
///
/// SON SORT EST UNE DECISION DE PRODUIT, PAS DE CODE, et elle est posee : soit
/// il est monte quelque part et redevient un vrai garde, soit il part avec ses
/// tests. En attendant, ce bandeau ne protege rien, et le prochain agent doit le
/// savoir avant de croire qu'il tient le niveau gratuit.
///
/// Si le trek n'a pas ete achete, affiche un bandeau mode demo
/// en haut de l'ecran (#81774 : gratuit = demo + pub). Le tap sur
/// le bandeau ouvre l ecran paywall ([PaywallSheet]) qui propose
/// le deblocage premium du trek (achat stub, aucun paiement reel).
///
/// isDemoMode est PAR TREK, pas par user (#81805 V7) :
/// un trek achete ne debloque que ce sentier.
///
/// Utilisation :
/// ```dart
/// PurchaseGateWidget(
///   trailId: trailConfig.id,
///   child: MonEcranComplet(),
/// )
/// ```
class PurchaseGateWidget extends ConsumerWidget {
  const PurchaseGateWidget({
    super.key,
    required this.trailId,
    required this.child,
    this.demoBannerText,
    this.onPurchaseTap,
  });

  /// Identifiant du trek a verifier.
  final String trailId;

  /// Contenu de l'ecran encapsule.
  final Widget child;

  /// Texte personnalise du bandeau demo (defaut: t.monetization.demoBanner).
  final String? demoBannerText;

  /// Callback quand l'utilisateur tape le bandeau d'achat.
  /// Si null, ouvre le [PaywallSheet] par defaut.
  final VoidCallback? onPurchaseTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // StepWays LOT 1 : l'acces derive des droits Drift (async). On observe le
    // mode demo REACTIF (isDemoModeProvider) : il se reevalue au boot ET a
    // chaque mutation des droits, donc un achat pendant l'affichage bascule le
    // bandeau sans le laisser perime (reserve QA). Tant que c'est indetermine
    // (loading/error), on affiche le contenu nu (pas de flash du bandeau demo).
    final isDemo = ref.watch(isDemoModeProvider(trailId)).value ?? false;
    if (!isDemo) {
      // Trek jouable (achete / abo / vitrine) : affichage normal, pas de gate.
      return child;
    }
    // Mode demo : bandeau + contenu.
    return Column(
      children: [
        _DemoBanner(
          text: demoBannerText ?? t.monetization.demoBanner,
          onTap: onPurchaseTap ?? () => _openPaywall(context, ref),
        ),
        Expanded(child: child),
      ],
    );
  }

  /// Ouvre l ecran paywall (deblocage premium du trek).
  ///
  /// TACHE 614 — PASSE PAR LE GESTE UNIQUE [acheterSentier]. Le prix n'est plus
  /// transmis par personne : le service le lit au catalogue
  /// ([MonetizationService.stagesOfTrail]). Le parametre `totalStages` de ce
  /// widget a donc ete RETIRE plutot que laisse en decor — un parametre qui
  /// n'influence plus rien est un mensonge d'interface.
  void _openPaywall(BuildContext context, WidgetRef ref) {
    acheterSentier(context, ref, trailId: trailId);
  }

  /// Verifie si un trek est en mode demo (statique, sans widget).
  ///
  /// Raccourci pour verifier depuis du code non-widget. Async (l'acces derive
  /// des droits Drift, StepWays LOT 1). PAR TREK, pas par user (#81805 V7).
  static Future<bool> isDemoMode(MonetizationService service, String trailId) {
    return service.isDemoMode(trailId);
  }
}

/// Bandeau affiche en mode demo.
///
/// Fond orange, texte blanc, tap = ouverture paywall.
class _DemoBanner extends StatelessWidget {
  const _DemoBanner({
    required this.text,
    this.onTap,
  });

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final banner = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.orangeDifficile,
      ),
      child: Row(
        children: [
          const StepIcon(StepwaysIcons.cadenas, color: Colors.white, size: 18),
          const SizedBox(width: AppTheme.spacingSm),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          if (onTap != null)
            const StepIcon(StepwaysIcons.chevronDroite, color: Colors.white, size: 14),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: banner);
    }
    return banner;
  }
}
