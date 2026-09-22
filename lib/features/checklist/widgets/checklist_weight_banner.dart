import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/ui/input_formatters.dart';
import '../../../i18n/translations.g.dart';
import '../../feasibility/domain/body_weight_reference.dart';
import '../../feasibility/domain/hiker_input_bounds.dart';

/// Formate un poids en grammes avec separateur de milliers (parite GR20).
/// Ex: 1600 -> "1 600 g", 350 -> "350 g".
String formatChecklistGrams(int grams) {
  final unit = t.checklist.weight.grams;
  if (grams < 1000) return '$grams $unit';
  final str = grams.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < str.length; i++) {
    if (i > 0 && (str.length - i) % 3 == 0) buffer.write(' ');
    buffer.write(str[i]);
  }
  return '${buffer.toString()} $unit';
}

/// Couleur / conseil / icone selon le ratio poids sac / corps.
///
/// Memes seuils que GR20 « Materiel & Sac » : 12 / 15 / 20 / 25 %. Couleurs
/// semantiques via [AppTheme] (hors systeme de peaux) — les paliers
/// intermediaires (jaune-vert, rouge fonce) sont des couleurs fixes comme GR20.
({Color color, String advice, IconData icon}) checklistRatioAdvice(
    double ratio) {
  final w = t.checklist.weight;
  if (ratio < 0.12) {
    return (
      color: AppTheme.vertFacile,
      advice: w.adviceUltraLight,
      icon: Icons.check_circle,
    );
  } else if (ratio < 0.15) {
    return (
      color: const Color(0xFF9ACD32), // jaune-vert (parite GR20)
      advice: w.adviceOk,
      icon: Icons.check_circle,
    );
  } else if (ratio < 0.20) {
    return (
      color: AppTheme.orangeDifficile,
      advice: w.adviceHeavy,
      icon: Icons.warning_amber,
    );
  } else if (ratio < 0.25) {
    return (
      color: AppTheme.rougeUrgence,
      advice: w.adviceTooHeavy,
      icon: Icons.error,
    );
  } else {
    return (
      color: const Color(0xFF8B0000), // rouge fonce (parite GR20)
      advice: w.adviceDanger,
      icon: Icons.error,
    );
  }
}

/// Bandeau en haut avec le poids total du sac + conseil colore + compteur
/// d'articles coches (parite GR20 « Materiel & Sac » — _WeightBanner).
class ChecklistWeightBanner extends StatelessWidget {
  const ChecklistWeightBanner({
    super.key,
    required this.checkedWeightGrams,
    required this.backpackRatio,
    required this.checkedCount,
    required this.totalCount,
  });

  /// Poids total du sac en grammes (articles coches, quantite comprise).
  final int checkedWeightGrams;

  /// Ratio sac / corps (0..1+), pilote la couleur (meme referentiel que jauge).
  final double backpackRatio;

  /// Nombre d'articles coches / total (compteur GR20).
  final int checkedCount;
  final int totalCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = checklistRatioAdvice(backpackRatio);
    final itemsLabel = t.checklist.weight.itemsChecked
        .replaceAll('{checked}', '$checkedCount')
        .replaceAll('{total}', '$totalCount');

    return Container(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      color: a.color.withAlpha(25),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: a.color.withAlpha(40),
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            ),
            child: Icon(Icons.luggage, size: 32, color: a.color),
          ),
          const SizedBox(width: AppTheme.spacingBase),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      formatChecklistGrams(checkedWeightGrams),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: a.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacingSm),
                    Icon(a.icon, size: 20, color: a.color),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  a.advice,
                  style: theme.textTheme.bodySmall?.copyWith(color: a.color),
                ),
                Text(
                  itemsLabel,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Ligne de saisie du poids corporel + chip ratio (parite GR20).
///
/// FIX-1 (finding B1, BLOQUANT) : ce champ n'avait NI filtre de saisie, NI
/// longueur max, NI borne haute — il etait hors `Form`, donc sans validator.
/// L'app affichait « Poids du sac : Infinity kg » et « 150000000.0 kg » sans le
/// moindre message, et une fois `Infinity` pose, plus rien ne le reinitialisait.
/// Le champ applique desormais EXACTEMENT le modele de la fiche morpho :
///  - a la saisie : chiffres et separateur decimal uniquement (le signe moins et
///    les lettres — donc « Infinity » et « abc » — n'entrent plus), 5 caracteres
///    max, depassement SIGNALE (pas de troncature muette) ;
///  - a la validation : bornes [kWeightMinKg]..[kWeightMaxKg] avec le MEME
///    message borne que la morpho, affiche sous la ligne ;
///  - une valeur refusee n'est JAMAIS propagee : la jauge garde le dernier poids
///    valide au lieu d'afficher un verdict absurde.
class ChecklistBodyWeightRow extends StatefulWidget {
  const ChecklistBodyWeightRow({
    super.key,
    required this.bodyWeightKg,
    required this.backpackRatio,
    required this.onBodyWeightChanged,
  });

  final double bodyWeightKg;
  final double backpackRatio;
  final void Function(double kg) onBodyWeightChanged;

  @override
  State<ChecklistBodyWeightRow> createState() => _ChecklistBodyWeightRowState();
}

/// Longueur max du champ poids corporel (« 200.5 » = 5 caracteres), identique a
/// la fiche morpho.
const int kBodyWeightFieldMaxLength = 5;

class _ChecklistBodyWeightRowState extends State<ChecklistBodyWeightRow> {
  late final TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();

  /// Message borne affiche sous la ligne quand la saisie est refusee (null =
  /// aucune erreur). Meme texte que la fiche morpho : une seule regle, un seul
  /// message pour la meme donnee.
  String? _error;

  /// Vrai si la frappe en cours a ete tronquee faute de place : empeche le
  /// `onChanged` du meme evenement d'effacer le message qui vient de s'afficher
  /// (sinon une decimale mangee redeviendrait invisible).
  bool _truncatedThisEdit = false;

  @override
  void initState() {
    super.initState();
    _controller =
        TextEditingController(text: widget.bodyWeightKg.toStringAsFixed(0));
    // Sortie du champ : on reaffiche TOUJOURS le poids reellement utilise par la
    // jauge. Le texte a l'ecran ne peut donc pas rester sur une valeur refusee.
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) return;
    final effective = widget.bodyWeightKg.toStringAsFixed(0);
    if (_controller.text != effective || _error != null) {
      setState(() {
        _controller.text = effective;
        _error = null;
      });
    }
  }

  /// Applique une saisie : refus motive (message borne) ou propagation.
  ///
  /// Champ vide = « non renseigne » (meme convention que la morpho) : pas de
  /// message, pas de propagation — la jauge garde le dernier poids valide.
  void _onChanged(String raw) {
    final truncated = _truncatedThisEdit;
    _truncatedThisEdit = false;
    final text = raw.trim();
    if (text.isEmpty) {
      if (_error != null && !truncated) setState(() => _error = null);
      return;
    }
    final kg = double.tryParse(text.replaceAll(',', '.'));
    if (kg == null || !isValidBodyWeightKg(kg)) {
      final message = t.hikerProfile.errorWeight;
      if (_error != message) setState(() => _error = message);
      return;
    }
    // Saisie valide MAIS tronquee : on propage la valeur (elle est correcte) et
    // on garde le message, sinon la coupe passerait inapercue.
    if (_error != null && !truncated) setState(() => _error = null);
    widget.onBodyWeightChanged(kg);
  }

  @override
  void didUpdateWidget(ChecklistBodyWeightRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // LOT 1 (retour Chris #12) : quand le poids corporel change en amont (ex.
    // injection depuis la fiche profil), on synchronise le champ affiche — SAUF
    // si l'utilisateur est en train d'y saisir (focus) pour ne pas lui couper
    // la frappe. Le poids affiche colle ainsi a la source de verite (profil).
    if (widget.bodyWeightKg != oldWidget.bodyWeightKg && !_focusNode.hasFocus) {
      final next = widget.bodyWeightKg.toStringAsFixed(0);
      if (_controller.text != next) _controller.text = next;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final weightT = t.checklist.weight;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.monitor_weight_outlined,
                  size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: AppTheme.spacingSm),
              Flexible(
                child: Text(
                  weightT.bodyWeight,
                  style: theme.textTheme.bodyMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              SizedBox(
                width: 120,
                child: TextField(
                  key: const ValueKey('checklist-body-weight-field'),
                  controller: _controller,
                  focusNode: _focusNode,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  maxLength: kBodyWeightFieldMaxLength,
                  // BARRIERE DE SAISIE (modele morpho) : chiffres + separateur
                  // decimal uniquement. Le signe moins et les lettres ne sont plus
                  // saisissables, donc « -50 », « abc » et « Infinity » n'arrivent
                  // jamais jusqu'au parse.
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    NotifyingLengthLimitingTextInputFormatter(
                      kBodyWeightFieldMaxLength,
                      onLimitReached: () {
                        _truncatedThisEdit = true;
                        final message = t.hikerProfile.errorWeight;
                        if (_error != message) {
                          setState(() => _error = message);
                        }
                      },
                    ),
                  ],
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    isDense: true,
                    // Compteur masque : la borne est portee par maxLength (barriere
                    // physique) et par le message borne sous la ligne.
                    counterText: '',
                    suffixText: weightT.kilograms,
                    errorText: _error != null ? '' : null,
                    errorStyle: const TextStyle(height: 0, fontSize: 0),
                  ),
                  onTap: () {
                    _controller.selection = TextSelection(
                      baseOffset: 0,
                      extentOffset: _controller.text.length,
                    );
                  },
                  onChanged: _onChanged,
                ),
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Flexible(child: _RatioChip(ratio: widget.backpackRatio)),
            ],
          ),
          // Message de refus BORNE, pleine largeur (lisible, contrairement a un
          // errorText coince dans un champ de 120 px).
          if (_error case final message?)
            Padding(
              padding: const EdgeInsets.only(top: AppTheme.spacingXs),
              child: Row(
                children: [
                  Icon(Icons.error_outline,
                      size: 16, color: theme.colorScheme.error),
                  const SizedBox(width: AppTheme.spacingXs),
                  Expanded(
                    child: Text(
                      message,
                      key: const ValueKey('checklist-body-weight-error'),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.error),
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

/// Chip indicateur du ratio sac / poids corporel (parite GR20).
class _RatioChip extends StatelessWidget {
  const _RatioChip({required this.ratio});

  final double ratio;

  @override
  Widget build(BuildContext context) {
    final pct = (ratio * 100).toStringAsFixed(0);
    final color = checklistRatioAdvice(ratio).color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: color),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          '$pct%',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// Jauge visuelle du poids relatif — parite GR20 (_WeightGauge). Seuils
/// 12 / 15 / 20 / 25 %, marqueurs 15 / 20 / 25 %, texte d'objectif.
///
/// LE DENOMINATEUR A CHANGE LE 22/09, LE LIBELLE AUSSI (#7-e). Le pourcentage
/// n'est plus celui du POIDS CORPOREL mais celui de la BASE DE CHARGE,
/// `min(poids ; 25 × taille²)`. Changer le denominateur sans changer le libelle
/// aurait fait mentir l'ecran : a 1,78 m et 120 kg, « 16,7 % du poids » serait
/// devenu « 25,2 % » sans que rien ne dise de quoi.
class ChecklistWeightGauge extends StatelessWidget {
  const ChecklistWeightGauge({
    super.key,
    required this.backpackRatio,
    this.loadBaseKg = 0,
    this.referenceFallback,
  });

  final double backpackRatio;

  /// Base de charge (kg) sur laquelle le pourcentage est calcule — affichee,
  /// parce qu'un pourcentage dont on ignore la base ne veut rien dire.
  final double loadBaseKg;

  /// Pourquoi la reference de taille n'a pas pu etre calculee, `null` sinon.
  /// Quand elle manque, l'ecran DIT que le plafond porte sur le poids reel.
  final WeightReferenceFallback? referenceFallback;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final w = t.checklist.weight;
    final pct = backpackRatio * 100;

    Color gaugeColor;
    String gaugeLabel;
    if (pct < 12) {
      gaugeColor = AppTheme.vertFacile;
      gaugeLabel = w.gaugeUltraLight;
    } else if (pct < 15) {
      gaugeColor = const Color(0xFF9ACD32);
      gaugeLabel = w.gaugeOk;
    } else if (pct < 20) {
      gaugeColor = AppTheme.orangeDifficile;
      gaugeLabel = w.gaugeHeavy;
    } else if (pct < 25) {
      gaugeColor = AppTheme.rougeUrgence;
      gaugeLabel = w.gaugeWarn;
    } else {
      gaugeColor = const Color(0xFF8B0000);
      gaugeLabel = w.gaugeDanger;
    }

    final pctLabel = w.percentOfReference
        .replaceAll('{pct}', pct.toStringAsFixed(1));

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.spacingBase,
        vertical: AppTheme.spacingSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                flex: 2,
                child: Text(
                  pctLabel,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: gaugeColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 3,
                child: Text(
                  gaugeLabel,
                  style: theme.textTheme.bodySmall?.copyWith(color: gaugeColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Stack(
            children: [
              Container(
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.grisGranite.withAlpha(40),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              FractionallySizedBox(
                widthFactor: (pct / 30).clamp(0.0, 1.0),
                child: Container(
                  height: 12,
                  decoration: BoxDecoration(
                    color: gaugeColor,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
              ),
              Positioned(
                left: MediaQuery.of(context).size.width * 0.5 * (15 / 30) - 16,
                top: 14,
                child: Text('15%',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontSize: 14, color: AppTheme.grisGranite)),
              ),
              Positioned(
                left: MediaQuery.of(context).size.width * 0.5 * (20 / 30) - 16,
                top: 14,
                child: Text('20%',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontSize: 14, color: AppTheme.grisGranite)),
              ),
              Positioned(
                left: MediaQuery.of(context).size.width * 0.5 * (25 / 30) - 16,
                top: 14,
                child: Text('25%',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(fontSize: 14, color: AppTheme.grisGranite)),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            w.gaugeObjectiveReference,
            style: theme.textTheme.bodySmall
                ?.copyWith(fontSize: 14, fontStyle: FontStyle.italic),
          ),
          // DIRE DE QUOI LE POURCENTAGE EST LE POURCENTAGE (#7-e).
          if (referenceFallback == null && loadBaseKg > 0) ...[
            const SizedBox(height: 2),
            Text(
              w.referenceExplainer
                  .replaceAll('{kg}', loadBaseKg.toStringAsFixed(1)),
              key: const ValueKey('checklist-reference-explainer'),
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 14),
            ),
          ],
          // REPLI TRES PETITE TAILLE (#5-h) : on ne bloque personne, on dit
          // qu'on ne sait pas calculer. Aucune pathologie n'est nommee, aucun
          // diagnostic n'est pose — le message parle de l'application, pas de
          // la personne.
          if (referenceFallback ==
              WeightReferenceFallback.heightBelowReferenceDomain) ...[
            const SizedBox(height: 2),
            Text(
              w.referenceFallbackHeight,
              key: const ValueKey('checklist-reference-fallback'),
              style: theme.textTheme.bodySmall?.copyWith(fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}
