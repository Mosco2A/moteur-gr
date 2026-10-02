import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/services/monetization_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/input_formatters.dart';
import '../../../i18n/translations.g.dart';
import '../../../core/services/session_demo.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/grise_en_demo.dart';
import '../../feasibility/domain/hiker_profile.dart';
import '../../feasibility/providers/hiker_profile_provider.dart';
import '../data/checklist_template.dart';
import '../providers/checklist_provider.dart';
import '../widgets/checklist_bottom_actions.dart';
import '../widgets/checklist_category_section.dart';
import '../widgets/checklist_demo_lock.dart';
import '../widgets/checklist_descent_alert.dart';
import '../widgets/checklist_preparation_section.dart';
import '../widgets/checklist_recommendation_banner.dart';
import '../widgets/checklist_seasonal_section.dart';
import '../widgets/checklist_shopping_modal.dart';
import '../widgets/checklist_weight_banner.dart';
import '../../../core/branding/stepways_icons.dart';

/// Ecran « Materiel & Sac » — CLONE INTEGRAL de l'ecran GR20 du meme nom
/// (parite #99433, PAREIL = PAREIL).
///
/// Nom d'ecran, rubriques, articles, categories, champs, libelles, disposition,
/// actions et comportements reproduisent GR20 « Materiel & Sac ». Hors systeme
/// de peaux (couleurs semantiques via [AppTheme]). Generique multi-sentiers :
/// le contenu est une donnee de template (surchargeable par sentier), mais le
/// contenu par defaut + le rendu + les fonctions sont ceux de GR20.
/// Persistance Drift (poids, quantite, coche, articles custom, liste de
/// courses). Tout texte via Slang (t.checklist.*).
class ChecklistScreen extends ConsumerStatefulWidget {
  const ChecklistScreen({super.key});

  @override
  ConsumerState<ChecklistScreen> createState() => _ChecklistScreenState();
}

class _ChecklistScreenState extends ConsumerState<ChecklistScreen> {
  @override
  Widget build(BuildContext context) {
    final checklistT = t.checklist;
    final isLoading = ref.watch(checklistProvider.select((s) => s.isLoading));

    // LOT 1 (retour Chris #12) : le poids du sac DERIVE du poids de la fiche
    // profil (source de verite unique). On injecte le poids morpho dans la
    // jauge Sac des qu'il est disponible, et on reste reactif si l'utilisateur
    // met a jour sa fiche. `seedBodyWeightFromProfile` n'ecrase pas une saisie
    // manuelle de session (override local). Fait ICI (dans build) via un watch
    // + un post-frame : on ne mute pas le provider Sac pendant la construction.
    final profileWeight =
        ref.watch(hikerProfileProvider).value?.weightKg ??
        HikerProfile.empty.weightKg;
    // La TAILLE suit la meme porte depuis le 22/09 : le plafond du sac n'est
    // plus un pourcentage du poids reel mais de la base de charge
    // `min(poids ; 25 × taille²)` (#4-b). Sans taille, la base retombe sur le
    // poids reel et le bandeau le DIT (#5-h).
    final profileHeight =
        ref.watch(hikerProfileProvider).value?.heightCm ??
        HikerProfile.empty.heightCm;
    if (profileWeight > 0 || profileHeight > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final notifier = ref.read(checklistProvider.notifier);
        if (profileWeight > 0) {
          notifier.seedBodyWeightFromProfile(profileWeight);
        }
        if (profileHeight > 0) {
          notifier.seedBodyHeightFromProfile(profileHeight);
        }
      });
    }

    if (isLoading) {
      return Scaffold(
        // Ph5 (L6b) : AppHeader universel (etat de chargement).
        appBar: AppHeader(title: checklistT.title),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final state = ref.watch(checklistProvider);
    final shoppingCount = state.shoppingListCount;

    // LE SAC EST BRIDE EN DEMO (tache 594, A2c). Il ne l'etait PAS DU TOUT :
    // recherche `isDemo|PurchaseGate|paywall|demo` dans `lib/features/checklist/`
    // = zero occurrence de monetisation (inventaire 593 §M7c). Le sac s'ouvrait
    // entier, gratuit et complet, alors que le modele eco en fait un outil du
    // trek ACHETE, jouable « pour de faux » en version bridee tant qu'on n'a
    // pas achete.
    //
    // TANT QUE LE DROIT N'EST PAS CONNU, ON NE BRIDE PAS (`?? false`) : meme
    // convention que le bandeau de demo existant — pas de clignotement du
    // verrou pendant l'hydratation des droits. Le bridage est un affichage ;
    // le verrou qui porte l'argent est celui de la REALISATION, et il vit dans
    // le domaine, pas ici.
    final trailId = ref.watch(trailIdProvider);
    // Le nombre d'etapes n'est plus lu ici : le prix du deblocage est resolu par
    // le service qui debite ([MonetizationService.stagesOfTrail], avenant 614).
    final isDemo = ref.watch(isDemoModeProvider(trailId)).value ?? false;

    return Scaffold(
      // Ph5 (L6b) : AppHeader universel + actions conservees (i / liste de
      // courses avec badge / reinitialiser) — parite ecran, aucune action perdue.
      appBar: AppHeader(
        title: checklistT.title,
        actions: [
          IconButton(
            icon: const StepIcon(StepwaysIcons.info),
            tooltip: checklistT.ui.help,
            onPressed: () => _showInfoSheet(context),
          ),
          // Badge compteur sur icone chariot (liste de courses).
          // GRISE EN DEMO (tache 638, bug 14) : la liste de courses se construit
          // en base, article par article — rien a en faire dans une demo.
          GriseEnDemo(
            child: Stack(
              children: [
                IconButton(
                  icon: const StepIcon(StepwaysIcons.panier),
                  tooltip: checklistT.ui.shoppingListTitle,
                  onPressed: () => _showShoppingListModal(state),
                ),
                if (shoppingCount > 0)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppTheme.rougeUrgence,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      child: Text(
                        '$shoppingCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // GRISE EN DEMO : reinitialiser le sac est une suppression en base.
          GriseEnDemo(
            child: IconButton(
              icon: const StepIcon(StepwaysIcons.rafraichir),
              tooltip: checklistT.reset,
              onPressed: () => _showResetDialog(context, checklistT),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // --- BANDEAU D'ESSAI (tache 594, A2c) : le sac est BRIDE en demo.
            if (isDemo) const ChecklistDemoBanner(),
            // --- Section SAC ADAPTATIF (LOT 5, B) : suggestions saison + trek,
            // ajoutables au sac (comptees dans la jauge). ADDITIVE : n'altere pas
            // la liste de base (parite GR20 intacte). Masquee si rien a adapter.
            //
            // MASQUEE EN DEMO : « liste materiel adaptee trek + saison » est
            // precisement ce que le modele eco (§7) reserve au trek ACHETE.
            if (!isDemo) const ChecklistSeasonalSection(),
            // --- Bandeau poids total + indicateur (pleine largeur, GR20) ---
            ChecklistWeightBanner(
              checkedWeightGrams: state.checkedWeightGrams,
              backpackRatio: state.backpackRatio,
              checkedCount: state.checkedCount,
              totalCount: state.totalCount,
            ),
            // --- Bandeau poids recommande ---
            ChecklistRecommendationBanner(
              bodyWeightKg: state.bodyWeightKg,
              bodyHeightCm: state.bodyHeightCm,
            ),
            // --- Poids corporel + ratio ---
            // GRISE EN DEMO (tache 638, bug 14) : le poids corporel est une
            // donnee de personne, et le modifier ici retombe sur la fiche du
            // randonneur. On ne touche pas au corps de quelqu'un dans une demo.
            GriseEnDemo(
              child: ChecklistBodyWeightRow(
                bodyWeightKg: state.bodyWeightKg,
                backpackRatio: state.backpackRatio,
                onBodyWeightChanged: (kg) =>
                    ref.read(checklistProvider.notifier).setBodyWeight(kg),
              ),
            ),
            // --- Jauge poids relatif (base de charge, pas poids reel) ---
            ChecklistWeightGauge(
              backpackRatio: state.backpackRatio,
              loadBaseKg: state.loadBaseKg,
              referenceFallback: state.weightReferenceFallback,
            ),
            // --- Alerte descente du dispositif poids (#4-c, #4-l) ---
            const ChecklistDescentAlert(),
            const SizedBox(height: AppTheme.spacingSm),
            // --- Categories + sections, avec padding horizontal (GR20) ---
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingBase,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (index, category) in checklistCategories.indexed)
                    if (!isDemo || index < kDemoChecklistCategoriesPlayable)
                      ChecklistCategorySection(
                        key: ValueKey('checklist-category-$category'),
                        categoryKey: category,
                        categoryName: _resolveCategoryName(category),
                        items: state.items
                            .where((i) => i.template.category == category)
                            .toList(),
                        onToggle: _handleToggle,
                        onEditItem: _showEditItemDialog,
                        onDeleteItem: _showDeleteItemDialog,
                        onAddItem: () => _showAddItemDialog(category),
                        onQuantityChanged: (itemId, newQty) => ref
                            .read(checklistProvider.notifier)
                            .setItemQuantity(itemId, newQty),
                        onToggleShoppingList: (itemId) => ref
                            .read(checklistProvider.notifier)
                            .toggleShoppingList(itemId),
                      )
                    else
                      ChecklistLockedCategory(
                        categoryKey: category,
                        categoryName: _resolveCategoryName(category),
                        trailId: trailId,
                      ),
                  // --- Preparation du sac ---
                  ChecklistPreparationSection(items: state.items),
                  // --- Checklist avant depart ---
                  const ChecklistPreDepartureSection(),
                  // --- Boutons du bas ---
                  // GRISEES EN DEMO (tache 638, bug 14) : valider le sac,
                  // construire la liste de courses et exporter ecrivent ou
                  // sortent des donnees. Rien de tout cela dans une demo.
                  const GriseEnDemo(child: ChecklistBottomActions()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _resolveCategoryName(String categoryKey) {
    final resolved = t['checklist.categories.$categoryKey'];
    return resolved is String ? resolved : categoryKey;
  }

  // ------------------------------------------------------------------ toggle

  void _handleToggle(String itemId) {
    final item = ref
        .read(checklistProvider)
        .items
        .firstWhere((i) => i.template.id == itemId);
    if (item.template.requirement == ChecklistRequirement.required &&
        item.isChecked) {
      _showRequiredWarning(itemId);
    } else {
      ref.read(checklistProvider.notifier).toggle(itemId);
    }
  }

  Future<void> _showRequiredWarning(String itemId) async {
    final ui = t.checklist.ui;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ui.requiredWarnTitle),
        content: Text(ui.requiredWarnBody),
        actions: [
          AppButton(
            variant: AppButtonVariant.text,
            label: ui.keep,
            isFullWidth: false,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          AppButton(
            variant: AppButtonVariant.filledTone,
            tone: AppTheme.rougeUrgence,
            label: ui.removeAnyway,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(checklistProvider.notifier).forceUncheck(itemId);
    }
  }

  // -------------------------------------------------------------- add / edit

  /// Valide un poids d'article saisi (grammes).
  ///
  /// FIX-1 (finding M3) : avant, « 99999999 » devenait 50 000 g et
  /// « 999999999999999999999 » devenait 100 g (depassement 64 bits ->
  /// `int.tryParse` null -> valeur par defaut), SANS AUCUN MESSAGE. Un clamp
  /// silencieux est un mensonge : on refuse desormais avec un message borne, et
  /// la saisie est physiquement limitee a [kItemWeightFieldMaxLength] chiffres.
  /// Retourne le message d'erreur, ou null si la valeur est acceptable.
  String? _validateItemWeight(String raw) {
    final grams = int.tryParse(raw.trim());
    if (grams == null ||
        grams < kItemWeightMinGrams ||
        grams > kItemWeightMaxGrams) {
      return t.checklist.ui.errorWeightGrams;
    }
    return null;
  }

  Future<void> _showAddItemDialog(String category) async {
    // GRISE ET QUI DIT POURQUOI (tache 638, bug 14). Cette porte ouvre un
    // dialogue dont l'enregistrement est barre en demo : l'ouvrir serait promettre
    // une ecriture qui n'aura pas lieu. On dit donc non, et on dit pourquoi.
    if (ref.read(enDemoProvider)) {
      direIndisponibleEnDemo(context);
      return;
    }
    final ui = t.checklist.ui;
    final nameCtrl = TextEditingController();
    final weightCtrl = TextEditingController(text: '100');
    String? nameError;
    String? weightError;
    // Vrai si la frappe en cours a ete tronquee : evite que le onChanged du
    // meme evenement efface le message qui vient d'etre affiche.
    var weightTruncated = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: Text(ui.addItemTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: ui.fieldName,
                  errorText: nameError,
                  errorMaxLines: 2,
                ),
                autofocus: true,
                onChanged: (_) {
                  if (nameError != null) {
                    setLocalState(() => nameError = null);
                  }
                },
              ),
              const SizedBox(height: AppTheme.spacingSm),
              TextField(
                key: const ValueKey('checklist-add-weight-field'),
                controller: weightCtrl,
                decoration: InputDecoration(
                  labelText: ui.fieldWeightGrams,
                  counterText: '',
                  errorText: weightError,
                  // Le message borne est plus large que le dialogue : sans ca
                  // il s'affiche tronque (« Poids invalide (0 a 50 … ») et la
                  // borne, qui est tout l'interet du message, disparait.
                  errorMaxLines: 2,
                ),
                keyboardType: TextInputType.number,
                maxLength: kItemWeightFieldMaxLength,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  NotifyingLengthLimitingTextInputFormatter(
                    kItemWeightFieldMaxLength,
                    onLimitReached: () {
                      weightTruncated = true;
                      setLocalState(() => weightError = ui.errorWeightGrams);
                    },
                  ),
                ],
                onChanged: (_) {
                  if (!weightTruncated && weightError != null) {
                    setLocalState(() => weightError = null);
                  }
                  weightTruncated = false;
                },
              ),
            ],
          ),
          actions: [
            AppButton(
              variant: AppButtonVariant.text,
              label: t.checklist.weight.cancel,
              isFullWidth: false,
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            AppButton(
              label: ui.add,
              onPressed: () {
                final nextName = nameCtrl.text.trim().isEmpty
                    ? ui.errorNameRequired
                    : null;
                final nextWeight = _validateItemWeight(weightCtrl.text);
                if (nextName != null || nextWeight != null) {
                  // Le dialogue RESTE ouvert : rien n'est invente dans le dos
                  // de l'utilisateur, il voit ce qui cloche et corrige.
                  setLocalState(() {
                    nameError = nextName;
                    weightError = nextWeight;
                  });
                  return;
                }
                Navigator.of(ctx).pop(true);
              },
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      await ref
          .read(checklistProvider.notifier)
          .addCustomItem(
            category,
            nameCtrl.text.trim(),
            int.parse(weightCtrl.text.trim()),
          );
    }
  }

  /// Dialogue d'edition d'un article (parite GR20) :
  /// - article du template : poids modifiable, nom en lecture seule ;
  /// - article custom : nom ET poids modifiables.
  Future<void> _showEditItemDialog(String itemId) async {
    // GRISE ET QUI DIT POURQUOI (tache 638, bug 14). Cette porte ouvre un
    // dialogue dont l'enregistrement est barre en demo : l'ouvrir serait promettre
    // une ecriture qui n'aura pas lieu. On dit donc non, et on dit pourquoi.
    if (ref.read(enDemoProvider)) {
      direIndisponibleEnDemo(context);
      return;
    }
    final ui = t.checklist.ui;
    final weightT = t.checklist.weight;
    final item = ref
        .read(checklistProvider)
        .items
        .firstWhere((i) => i.template.id == itemId);
    final name = checklistItemDisplayName(item);
    final nameCtrl = TextEditingController(text: name);
    final weightCtrl = TextEditingController(text: item.weightGrams.toString());
    String? nameError;
    String? weightError;
    var weightTruncated = false;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocalState) => AlertDialog(
          title: Text(item.isCustom ? ui.editCustomTitle : ui.editWeightTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: InputDecoration(
                  labelText: ui.fieldName,
                  errorText: nameError,
                  suffixIcon: item.isCustom
                      ? null
                      : const StepIcon(StepwaysIcons.cadenas, size: 16),
                ),
                enabled: item.isCustom,
                style: item.isCustom
                    ? null
                    : const TextStyle(color: AppTheme.grisGranite),
                onChanged: (_) {
                  if (nameError != null) {
                    setLocalState(() => nameError = null);
                  }
                },
              ),
              const SizedBox(height: AppTheme.spacingSm),
              TextField(
                key: const ValueKey('checklist-edit-weight-field'),
                controller: weightCtrl,
                decoration: InputDecoration(
                  labelText: weightT.itemWeight,
                  suffixText: weightT.grams,
                  counterText: '',
                  errorText: weightError,
                  errorMaxLines: 2,
                ),
                keyboardType: TextInputType.number,
                maxLength: kItemWeightFieldMaxLength,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  NotifyingLengthLimitingTextInputFormatter(
                    kItemWeightFieldMaxLength,
                    onLimitReached: () {
                      weightTruncated = true;
                      setLocalState(() => weightError = ui.errorWeightGrams);
                    },
                  ),
                ],
                autofocus: true,
                onChanged: (_) {
                  if (!weightTruncated && weightError != null) {
                    setLocalState(() => weightError = null);
                  }
                  weightTruncated = false;
                },
              ),
            ],
          ),
          actions: [
            AppButton(
              variant: AppButtonVariant.text,
              label: weightT.cancel,
              isFullWidth: false,
              onPressed: () => Navigator.of(ctx).pop(false),
            ),
            AppButton(
              label: weightT.save,
              onPressed: () {
                final nextName = item.isCustom && nameCtrl.text.trim().isEmpty
                    ? ui.errorNameRequired
                    : null;
                final nextWeight = _validateItemWeight(weightCtrl.text);
                if (nextName != null || nextWeight != null) {
                  setLocalState(() {
                    nameError = nextName;
                    weightError = nextWeight;
                  });
                  return;
                }
                Navigator.of(ctx).pop(true);
              },
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final newWeight = int.parse(weightCtrl.text.trim());
      final newName = nameCtrl.text.trim();
      final notifier = ref.read(checklistProvider.notifier);

      if (newWeight != item.weightGrams) {
        await notifier.setItemWeight(itemId, newWeight);
      }
      if (item.isCustom && newName.isNotEmpty && newName != name) {
        await notifier.setCustomName(itemId, newName);
      }
      // Auto-cocher l'article apres edition s'il ne l'est pas (parite GR20).
      final refreshed = ref
          .read(checklistProvider)
          .items
          .firstWhere((i) => i.template.id == itemId);
      if (!refreshed.isChecked) {
        await notifier.toggle(itemId);
      }
    }
  }

  Future<void> _showDeleteItemDialog(String itemId) async {
    // GRISE ET QUI DIT POURQUOI (tache 638, bug 14). Cette porte ouvre un
    // dialogue dont l'enregistrement est barre en demo : l'ouvrir serait promettre
    // une ecriture qui n'aura pas lieu. On dit donc non, et on dit pourquoi.
    if (ref.read(enDemoProvider)) {
      direIndisponibleEnDemo(context);
      return;
    }
    final ui = t.checklist.ui;
    final item = ref
        .read(checklistProvider)
        .items
        .firstWhere((i) => i.template.id == itemId);
    if (!item.isCustom) return;
    final name = checklistItemDisplayName(item);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ui.deleteItemTitle),
        content: Text(ui.deleteItemBody.replaceAll('{name}', name)),
        actions: [
          AppButton(
            variant: AppButtonVariant.text,
            label: t.checklist.weight.cancel,
            isFullWidth: false,
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          AppButton(
            variant: AppButtonVariant.filledTone,
            tone: AppTheme.rougeUrgence,
            label: ui.delete,
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(checklistProvider.notifier).deleteCustomItem(itemId);
    }
  }

  // ---------------------------------------------------------- shopping modal

  void _showShoppingListModal(ChecklistState state) {
    final byCategory = <String, List<ChecklistItemState>>{};
    for (final item in state.items.where((i) => i.inShoppingList)) {
      final catName = _resolveCategoryName(item.template.category);
      byCategory.putIfAbsent(catName, () => []).add(item);
    }
    if (byCategory.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.checklist.ui.shoppingListEmpty)));
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => ChecklistShoppingModal(uncheckedByCategory: byCategory),
    );
  }

  // ----------------------------------------------------------------- info

  void _showInfoSheet(BuildContext ctx) {
    final ui = t.checklist.ui;
    final theme = Theme.of(ctx);
    showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.grisGranite.withAlpha(80),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                StepIcon(
                  StepwaysIcons.sacADos,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  ui.infoTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _richInfoItem(
              theme,
              StepwaysIcons.cocheCercle,
              ui.infoCheckTitle,
              ui.infoCheckBody,
              theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _richInfoItem(
              theme,
              StepwaysIcons.cadenas,
              ui.infoRequiredTitle,
              ui.infoRequiredBody,
              AppTheme.rougeUrgence,
            ),
            const SizedBox(height: 12),
            _richInfoItem(
              theme,
              StepwaysIcons.poids,
              ui.infoGaugeTitle,
              ui.infoGaugeBody,
              AppTheme.vertFacile,
            ),
            const SizedBox(height: 12),
            _richInfoItem(
              theme,
              StepwaysIcons.plus,
              ui.infoAddTitle,
              ui.infoAddBody,
              AppTheme.orangeDifficile,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.vertFacile.withAlpha(15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.vertFacile.withAlpha(40)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StepIcon(
                    StepwaysIcons.cochePleine,
                    size: 18,
                    color: AppTheme.vertFacile,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      ui.infoValidateBody,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        color: AppTheme.vertFacile,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: AppButton(
                variant: AppButtonVariant.text,
                label: ui.infoUnderstood,
                labelFontSize: 16,
                isFullWidth: false,
                onPressed: () => Navigator.of(sheetCtx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// [icon] est un chemin d'icone Stepways ([StepwaysIcons]), tache 632.
  static Widget _richInfoItem(
    ThemeData theme,
    String icon,
    String title,
    String description,
    Color accentColor,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: accentColor.withAlpha(25),
            borderRadius: BorderRadius.circular(8),
          ),
          child: StepIcon(icon, size: 22, color: accentColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: accentColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------------------- reset

  void _showResetDialog(
    BuildContext context,
    Translations$checklist$fr checklistT,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(checklistT.resetConfirm),
        content: Text(checklistT.resetDescription),
        actions: [
          AppButton(
            variant: AppButtonVariant.text,
            label: checklistT.cancel,
            isFullWidth: false,
            onPressed: () => Navigator.of(ctx).pop(),
          ),
          AppButton(
            label: checklistT.confirm,
            onPressed: () {
              ref.read(checklistProvider.notifier).resetAll();
              Navigator.of(ctx).pop();
            },
          ),
        ],
      ),
    );
  }
}
