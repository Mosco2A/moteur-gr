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
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../core/ui/app_haptics.dart';
import '../../../i18n/translations.g.dart';
import '../../trek/providers/gps_providers.dart';
import '../data/emergency_contacts_service.dart';
import '../domain/models/emergency_contact.dart';
import '../../../core/branding/stepways_icons.dart';
import 'health_info_screen.dart' show healthInfoProvider;

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
    // LES CONTACTS PERSONNELS VIENNENT DE LA FICHE D'URGENCE (tache 630).
    //
    // AVANT CE LOT ILS NE VENAIENT DE NULLE PART. `addContact` n'etait appele
    // par aucune ligne de `lib/` et le service gardait sa liste EN MEMOIRE :
    // aucun ecran ne permettait d'ajouter un proche a prevenir, et un proche
    // ajoute n'aurait de toute facon pas survecu au redemarrage. Cet ecran
    // n'affichait donc jamais que le 112 et les secours du sentier.
    //
    // POURQUOI L'ALIMENTATION SE FAIT ICI ET PAS DANS LE PROVIDER. Faire
    // observer la fiche au provider du service le ferait RECONSTRUIRE a chaque
    // modification de la fiche — et avec lui le service du widget d'ecran
    // verrouille, qui en depend et qui perdrait son etat « actif ». Un
    // secouriste verrait la notification de secours disparaitre parce que le
    // randonneur a corrige une allergie. Le service est un cache mutable : on le
    // realimente, on ne le refabrique pas.
    // `asData?.value` et pas `value` : pendant le chargement, ou si la lecture a
    // echoue, on ne veut PAS d'exception sur l'ecran d'urgence — on veut la
    // liste des secours automatiques, qui est toujours la.
    final fiche = ref.watch(healthInfoProvider).asData?.value;
    if (fiche != null) service.chargerDepuisLaFiche(fiche.emergencyContacts);
    final contacts = service.getContacts();
    final positionAsync = ref.watch(positionStreamProvider);

    return Scaffold(
      // Ph5 (L6d) : AppHeader universel. Titre en dur « Contacts urgence » ->
      // Slang (t.nav.emergency). Leading custom (Navigator.pop) retire : back
      // centralise (pop/accueil + Android).
      appBar: AppHeader(title: t.nav.emergency),
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
                      t.sos.noContacts,
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
        loading: () => Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: AppTheme.spacingSm),
            Text(t.sos.gpsAcquiring),
          ],
        ),
        error: (_, __) => Row(
          children: [
            const StepIcon(StepwaysIcons.gpsPerdu, size: 18, color: AppTheme.rougeUrgence),
            const SizedBox(width: AppTheme.spacingSm),
            Text(t.sos.positionUnavailable),
          ],
        ),
        data: (position) {
          final lat = position.latitude.toStringAsFixed(5);
          final lng = position.longitude.toStringAsFixed(5);
          final alt = position.altitude.toStringAsFixed(0);
          return Row(
            children: [
              StepIcon(
                StepwaysIcons.maPosition,
                size: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Expanded(
                child: Text(
                  t.sos.positionLine(lat: lat, lng: lng, alt: alt),
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
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
      // SW-SKIN-L3e : Card -> AppCard. elevation 1 conservee ; padding zero
      // car le ListTile porte son padding interne (iso-rendu de la tuile).
      child: AppCard(
        elevation: 1,
        padding: EdgeInsets.zero,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primary,
            child: const StepIcon(
              StepwaysIcons.ficheMedicale,
              color: Colors.white,
              size: 20,
            ),
          ),
          title: Text(
            t.health.entryTitle,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(t.health.entrySubtitle),
          trailing: const StepIcon(StepwaysIcons.chevronDroite),
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

    // SW-SKIN-L3e : Card -> AppCard. elevation dynamique conservee ; le fond
    // teinte rouge (contact automatique = SOS) porte par backgroundColor ;
    // padding zero car le ListTile porte son padding interne (iso-rendu).
    return AppCard(
      elevation: isAuto ? 2 : 1,
      backgroundColor: isAuto
          ? AppTheme.rougeUrgence.withAlpha(20)
          : theme.colorScheme.surface,
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAuto
              ? AppTheme.rougeUrgence
              : theme.colorScheme.primary,
          child: StepIcon(
            isAuto ? StepwaysIcons.secours : StepwaysIcons.monCompte,
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
          icon: StepIcon(
            StepwaysIcons.telephone,
            color: isAuto ? AppTheme.rougeUrgence : theme.colorScheme.primary,
            size: 28,
          ),
          tooltip: t.sos.callContact(name: contact.name),
          onPressed: () => _callContact(context, contact),
        ),
      ),
    );
  }

  /// Lance un appel telephonique -- K-05: appel immediat
  ///
  /// L'ECHEC ETAIT AVALE, SUR L'ECRAN D'URGENCE (tache 579, LOT X). Le `catch`
  /// portait en commentaire « l'OS gere l'erreur si le tel ne peut pas
  /// appeler ». C'est faux : si `launchUrl` LEVE, c'est precisement que l'OS n'a
  /// rien gere — aucune application de telephonie, tablette sans radio, canal de
  /// plateforme absent. Le randonneur appuyait sur le bouton d'appel des
  /// secours, ne voyait rien, et pouvait croire que l'appel partait. C'est le
  /// pire endroit de l'application pour se taire. Le numero est desormais donne
  /// EN CLAIR dans le message, pour qu'il puisse etre compose a la main.
  Future<void> _callContact(
    BuildContext context,
    EmergencyContact contact,
  ) async {
    // E5.5a : retour haptique fort sur action critique (appel d'urgence).
    AppHaptics.heavy();
    final messenger = ScaffoldMessenger.of(context);
    // Nettoyer le numero : retirer espaces pour le format tel:
    final cleanPhone = contact.phone.replaceAll(' ', '');
    var lance = false;
    try {
      final uri = Uri.parse('tel:$cleanPhone');
      lance = await launchUrl(uri);
    } on Object {
      lance = false;
    }
    if (lance) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(t.sos.cannotCall(number: contact.phone)),
        duration: const Duration(seconds: 6),
      ),
    );
  }
}
