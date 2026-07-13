// E5.14a — Ecran contacts d'urgence.
//
// Liste les contacts personnels ordonnes par priorite
// + numeros de secours automatiques (112 + secours regionaux
// du sentier actif via TrailConfig).
// Bouton appel direct via url_launcher tel:.
// Position GPS affichee en haut de l'ecran.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/engine/trail_engine.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/app_haptics.dart';
import '../../../i18n/translations.g.dart';
import '../../trek/providers/gps_providers.dart';
import '../data/emergency_contacts_service.dart';
import '../domain/models/emergency_contact.dart';

/// Provider pour le service de contacts d'urgence.
///
/// Les secours regionaux viennent de la config du sentier actif
/// (TrailConfig.emergencyNumbers) — rien n'est hardcode.
final emergencyContactsServiceProvider = Provider<EmergencyContactsService>(
  (ref) => EmergencyContactsService(
    trailEmergencyNumbers: ref.watch(trailConfigProvider).emergencyNumbers,
  ),
);

/// E5.14a : Ecran contacts d'urgence.
///
/// Affiche la position GPS actuelle et la liste des contacts
/// (personnels + secours automatiques) avec bouton appel direct.
class EmergencyScreen extends ConsumerWidget {
  const EmergencyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final service = ref.watch(emergencyContactsServiceProvider);
    final contacts = service.getContacts();
    final positionAsync = ref.watch(positionStreamProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts urgence'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Bandeau position GPS
          _GpsPositionBanner(positionAsync: positionAsync),

          // E57 (LOT D/D1) : acces a la fiche infos sante LOCAL ONLY.
          // Usage terrain : montrer ses donnees vitales aux secours (RF-6/AM-4).
          _HealthInfoEntry(),

          // Liste des contacts
          Expanded(
            child: contacts.isEmpty
                ? Center(
                    child: Text(
                      'Aucun contact configure',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withAlpha(153),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(AppTheme.spacingBase),
                    itemCount: contacts.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppTheme.spacingSm),
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return _EmergencyContactTile(contact: contact);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// Bandeau affichant la position GPS actuelle.
class _GpsPositionBanner extends StatelessWidget {
  const _GpsPositionBanner({required this.positionAsync});

  final AsyncValue positionAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      color: AppTheme.rougeUrgence.withAlpha(30),
      child: positionAsync.when(
        loading: () => const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: AppTheme.spacingSm),
            Text('Acquisition GPS...'),
          ],
        ),
        error: (_, __) => const Row(
          children: [
            Icon(Icons.gps_off, size: 18, color: AppTheme.rougeUrgence),
            SizedBox(width: AppTheme.spacingSm),
            Text('Position GPS indisponible'),
          ],
        ),
        data: (position) {
          final lat = position.latitude.toStringAsFixed(5);
          final lng = position.longitude.toStringAsFixed(5);
          final alt = position.altitude.toStringAsFixed(0);
          return Row(
            children: [
              Icon(
                Icons.gps_fixed,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  'Position : $lat, $lng  -  Alt. ${alt}m',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Entree vers la fiche infos sante (E57, LOT D/D1).
///
/// Point d'entree principal de la fiche sante (route `/health`) : usage terrain
/// pour montrer ses donnees vitales aux secours (RF-6/AM-4). Les donnees restent
/// LOCAL ONLY (Drift, art. 9). Libelles via Slang (`t.health.*`), couleurs du
/// theme -- rien en dur.
class _HealthInfoEntry extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingBase,
        AppTheme.spacingBase,
        AppTheme.spacingBase,
        0,
      ),
      child: Card(
        elevation: 1,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            child: const Icon(
              Icons.medical_information_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Text(
            t.health.entryTitle,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(t.health.entrySubtitle),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/health'),
        ),
      ),
    );
  }
}

/// Tuile affichant un contact d'urgence avec bouton appel.
class _EmergencyContactTile extends StatelessWidget {
  const _EmergencyContactTile({required this.contact});

  final EmergencyContact contact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAuto = contact.isAutomatic;

    return Card(
      elevation: isAuto ? 2 : 1,
      color: isAuto
          ? AppTheme.rougeUrgence.withAlpha(20)
          : theme.colorScheme.surface,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              isAuto ? AppTheme.rougeUrgence : theme.colorScheme.primary,
          child: Icon(
            isAuto ? Icons.local_hospital : Icons.person,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          contact.name,
          style: TextStyle(
            fontWeight: isAuto ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        subtitle: Text(
          contact.phone,
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.phone,
            color: isAuto ? AppTheme.rougeUrgence : theme.colorScheme.primary,
            size: 28,
          ),
          tooltip: 'Appeler ${contact.name}',
          onPressed: () => _callContact(context, contact),
        ),
      ),
    );
  }

  /// Lance un appel telephonique -- K-05: appel immediat
  Future<void> _callContact(
    BuildContext context,
    EmergencyContact contact,
  ) async {
    // E5.5a : retour haptique fort sur action critique (appel d'urgence).
    AppHaptics.heavy();
    // Nettoyer le numero : retirer espaces pour le format tel:
    final cleanPhone = contact.phone.replaceAll(' ', '');
    try {
      final uri = Uri.parse('tel:$cleanPhone');
      await launchUrl(uri);
    } catch (_) {
      // Silencieux -- l'OS gere l'erreur si le tel ne peut pas appeler
    }
  }
}
