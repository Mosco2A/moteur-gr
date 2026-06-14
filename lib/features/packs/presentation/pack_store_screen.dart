import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../domain/pack_catalog.dart';
import '../domain/sentier_pack.dart';
import 'pack_card.dart';

/// Store des packs sentier A LA CARTE (F8B-03, Phase 8 P8-B, regle metier R2).
///
/// Liste les packs ACHETABLES/TELECHARGEABLES INDEPENDAMMENT (Nord / Sud /
/// Complet / Mare a Mare) pour le sentier [trailId], chacun avec sa description,
/// sa taille (Mo), son etat (non telecharge / telecharge / mise a jour dispo),
/// son bouton telecharger + progression et la gestion de l'espace (supprimer).
///
/// MODELE A LA CARTE : un bandeau rappelle qu'on achete/telecharge un pack PAR
/// sentier, JAMAIS un abonnement global force (eviter le piege Komoot, A3-11).
/// La monetisation reelle est une decision de Christophe (voir PackPurchaseService).
///
/// a11y Semantics + Slang 5 langues (aucune chaine en dur). Riverpod 2.6 :
/// aucune logique reseau ici (deleguee aux controleurs de PackCard).
class PackStoreScreen extends ConsumerWidget {
  const PackStoreScreen({
    super.key,
    required this.trailId,
    this.updatablePackIds = const <String>{},
  });

  /// Sentier dont on liste les packs (genericite #84627).
  final String trailId;

  /// Ids de packs ayant une mise a jour disponible (etat « update »).
  final Set<String> updatablePackIds;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);

    // Catalogue A LA CARTE : libelles localises via Slang (domaine pur F8B-01).
    final packs = PackCatalog.availablePacks(
      trailId,
      labelResolver: (type) => _labelsFor(t, type),
    );

    return Scaffold(
      appBar: AppBar(title: Text(t.packs.title)),
      body: packs.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLg),
                child: Text(
                  t.packs.empty,
                  key: const ValueKey('pack-store-empty'),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              key: const ValueKey('pack-store-list'),
              children: [
                // En-tete : sous-titre + rappel A LA CARTE (pas d'abo, R2).
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.spacingMd,
                    AppTheme.spacingMd,
                    AppTheme.spacingMd,
                    AppTheme.spacingSm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.packs.subtitle,
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: AppTheme.spacingXs),
                      Semantics(
                        label: t.packs.alaCarteNote,
                        child: Container(
                          key: const ValueKey('pack-alacarte-note'),
                          padding: const EdgeInsets.all(AppTheme.spacingSm),
                          decoration: BoxDecoration(
                            color: AppTheme.vertFacile.withAlpha(30),
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusCard),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline,
                                  size: 18, color: AppTheme.vertFacile),
                              const SizedBox(width: AppTheme.spacingSm),
                              Expanded(
                                child: Text(
                                  t.packs.alaCarteNote,
                                  style:
                                      Theme.of(context).textTheme.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Une carte par pack a la carte.
                for (final pack in packs)
                  PackCard(
                    pack: pack,
                    manifest:
                        PackCatalog.manifestFor(trailId, pack.type),
                    updateAvailable: updatablePackIds.contains(pack.id),
                  ),
                const SizedBox(height: AppTheme.spacingLg),
              ],
            ),
    );
  }

  /// Resout les libelles localises d'un type de pack via Slang (5 langues).
  PackLabels _labelsFor(Translations t, String type) {
    final types = t.packs.types;
    switch (type) {
      case PackType.nord:
        return PackLabels(nom: types.nord.nom, description: types.nord.description);
      case PackType.sud:
        return PackLabels(nom: types.sud.nom, description: types.sud.description);
      case PackType.complet:
        return PackLabels(
            nom: types.complet.nom, description: types.complet.description);
      case PackType.mam:
      default:
        return PackLabels(nom: types.mam.nom, description: types.mam.description);
    }
  }
}
