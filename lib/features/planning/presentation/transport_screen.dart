import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/section_header.dart';
import '../domain/transport_info.dart';
import '../providers/transport_providers.dart';

/// Ecran TRANSPORT (parite GR20 `TransportScreen`, data-driven — regle
/// « donnees en externe » de Christophe #99460).
///
/// Deux onglets ALLER / RETOUR (parite GR20) :
///   * « Rejoindre {depart} »  = comment atteindre le point de DEPART du trek ;
///   * « Repartir de {arrivee} » = comment repartir du point d'ARRIVEE.
///
/// Les ENDPOINTS (depart / arrivee) sont resolus depuis les DONNEES du sentier,
/// DIRECTION-AWARE ([transportEndpointsProvider] : nom depuis les etapes,
/// `departureName`/`arrivalName`, ordre de marche). Le CONTENU de chaque onglet
/// (modes bus/train/ferry/avion, operateurs, horaires indicatifs, telephones,
/// liens) vient du catalogue transport du sentier ([trailTransportProvider]) —
/// PAS de widgets hardcodes par localite comme GR20. Le moteur reste GENERIQUE
/// multi-sentiers (#84627), zero hardcode de localite.
///
/// Fallback gracieux : sentier sans donnees transport -> ecran informatif
/// propre (aucun crash). Hors peau : couleurs semantiques d'AppTheme. Tout
/// libelle d'INTERFACE passe par Slang (`t.transport.*`, 5 langues) ; les
/// donnees propres au sentier restent dans la langue de la donnee.
class TransportScreen extends ConsumerWidget {
  const TransportScreen({super.key, required this.trailId});

  /// Identifiant du sentier courant (endpoints + donnees transport par sentier).
  final String trailId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = Translations.of(context);
    final endpoints = ref.watch(transportEndpointsProvider(trailId));
    final data = ref.watch(trailTransportProvider(trailId));

    // Libelles d'onglet : nom d'endpoint resolu, ou repli generique si les
    // etapes ne sont pas encore chargees (parite GR20 : titre dynamique).
    final departureName = endpoints?.departure ?? '';
    final arrivalName = endpoints?.arrival ?? '';

    final joinLabel = departureName.isNotEmpty
        ? t.transport.tabJoinNamed(name: departureName)
        : t.transport.tabJoin;
    final leaveLabel = arrivalName.isNotEmpty
        ? t.transport.tabLeaveNamed(name: arrivalName)
        : t.transport.tabLeave;

    // Resolution des infos par onglet (data-driven). Null-safe : si le sentier
    // n'a pas de donnees pour cet endpoint/sens, l'onglet montre un fallback.
    final arrivalTab = (data != null && departureName.isNotEmpty)
        ? data.forEndpoint(departureName, TransportRole.arrival)
        : null;
    final departureTab = (data != null && arrivalName.isNotEmpty)
        ? data.forEndpoint(arrivalName, TransportRole.departure)
        : null;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.transport.title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: t.a11y.back,
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          bottom: TabBar(
            tabs: [
              Tab(
                icon: const Icon(Icons.flight_land),
                text: joinLabel,
              ),
              Tab(
                icon: const Icon(Icons.flight_takeoff),
                text: leaveLabel,
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TransportTabView(
              key: const ValueKey('transport-tab-arrival'),
              info: arrivalTab,
              role: TransportRole.arrival,
              endpointName: departureName,
            ),
            _TransportTabView(
              key: const ValueKey('transport-tab-departure'),
              info: departureTab,
              role: TransportRole.departure,
              endpointName: arrivalName,
            ),
          ],
        ),
      ),
    );
  }
}

/// Contenu d'un onglet transport (parite GR20 `_build*Tab`), alimente par les
/// DONNEES ([EndpointTransport]) au lieu d'un widget hardcode par localite.
///
/// Si [info] est null (sentier sans donnees pour cet endpoint/sens), affiche un
/// fallback informatif propre (parite « ecran informatif », pas de crash).
class _TransportTabView extends StatelessWidget {
  const _TransportTabView({
    super.key,
    required this.info,
    required this.role,
    required this.endpointName,
  });

  final EndpointTransport? info;
  final TransportRole role;
  final String endpointName;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    // Fallback gracieux : aucune donnee transport disponible.
    if (info == null || !info!.hasContent) {
      return _TransportEmptyState(endpointName: endpointName, role: role);
    }
    final data = info!;

    // Couleur d'accent selon le sens (parite GR20 : vert pour l'aller, orange
    // pour le retour). Hors peau : tokens semantiques d'AppTheme (palette
    // StepWays : vertFacile / orangeDifficile).
    final accent = role == TransportRole.arrival
        ? AppTheme.vertFacile
        : AppTheme.orangeDifficile;
    final introTitle = role == TransportRole.arrival
        ? (endpointName.isNotEmpty
            ? t.transport.joinTitle(name: endpointName)
            : t.transport.tabJoin)
        : (endpointName.isNotEmpty
            ? t.transport.leaveTitle(name: endpointName)
            : t.transport.tabLeave);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.spacingBase),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Introduction (parite GR20 : carte d'intro coloree par sens).
          if (data.intro.isNotEmpty) ...[
            AppCard(
              backgroundColor: accent.withAlpha(20),
              borderColor: accent.withAlpha(60),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: accent, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          introTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: accent,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(data.intro, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
          ],

          // Sections d'options (parite GR20 : SectionHeader + cartes).
          for (final section in data.sections)
            if (section.options.isNotEmpty) ...[
              SectionHeader(
                title: section.title,
                icon: _iconFor(section.mode),
              ),
              const SizedBox(height: AppTheme.spacingSm),
              for (final option in section.options) ...[
                _TransportOptionCard(option: option),
                const SizedBox(height: AppTheme.spacingSm),
              ],
              const SizedBox(height: AppTheme.spacingMd),
            ],

          // Conseils pratiques (parite GR20 : carte « Conseils »).
          if (data.advices.isNotEmpty)
            _AdviceCard(advices: data.advices),
          const SizedBox(height: AppTheme.spacingXl),
        ],
      ),
    );
  }
}

/// Carte d'une option de transport (parite GR20 `_TransportOptionCard`).
///
/// En-tete (icone + titre + description) + badge prix, bloc horaires, contact
/// telephonique cliquable (tel:) et — si present — bouton site web (url_launcher,
/// application externe). Les blocs vides (prix / horaires / contact / url) sont
/// masques : parite comportement GR20 sans champ obligatoire artificiel.
class _TransportOptionCard extends StatelessWidget {
  const _TransportOptionCard({required this.option});

  final TransportOption option;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    // Bleu = couleur secondaire du theme (peau active) ; les autres teintes sont
    // des tokens semantiques stables. Resolu ici (avec contexte) pour rester
    // « hors peau » cote couleur tout en suivant la peau pour le bleu.
    final color = _colorFor(option.mode, theme.colorScheme);
    final linkColor = theme.colorScheme.secondary;

    return AppCard(
      borderColor: color.withAlpha(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tete : icone + titre/description + badge prix.
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withAlpha(30),
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                ),
                child: Icon(_iconFor(option.mode), color: color, size: 22),
              ),
              const SizedBox(width: AppTheme.spacingMd),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (option.description.isNotEmpty)
                      Text(
                        option.description,
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 14),
                      ),
                  ],
                ),
              ),
              if (option.price.isNotEmpty) ...[
                const SizedBox(width: AppTheme.spacingSm),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.vertFacile.withAlpha(30),
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  ),
                  child: Text(
                    option.price,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.vertFacile,
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Horaires indicatifs (bloc sombre, parite GR20).
          if (option.schedule.isNotEmpty) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.schedule,
                      size: 18, color: AppTheme.grisGranite),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      option.schedule,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Contact telephonique cliquable + eventuel bouton site (parite GR20).
          if (option.hasContact || option.hasUrl) ...[
            const SizedBox(height: AppTheme.spacingSm),
            Row(
              children: [
                if (option.hasContact)
                  Expanded(
                    child: Semantics(
                      button: true,
                      label: t.transport.a11y
                          .call(label: option.contactLabel),
                      child: InkWell(
                        onTap: () => _call(option.contact),
                        child: Row(
                          children: [
                            Icon(Icons.phone, size: 18, color: linkColor),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    option.contactLabel,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: linkColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    option.contact,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: linkColor,
                                      fontSize: 14,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  // Contact indisponible : libelle neutre (donnee « a completer »
                  // sans numero), aligne a gauche. Pas de lien tel: vide.
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            size: 18, color: AppTheme.grisGranite),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            option.contactLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppTheme.grisGranite,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (option.hasUrl)
                  Semantics(
                    button: true,
                    label: t.transport.a11y.website,
                    child: IconButton(
                      icon: Icon(Icons.open_in_new, size: 18, color: linkColor),
                      tooltip: t.transport.website,
                      onPressed: () => _openUrl(option.url!),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _call(String phone) async {
    final uri = Uri.parse('tel:${phone.replaceAll(' ', '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _openUrl(String urlStr) async {
    final uri = Uri.parse(urlStr);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

/// Carte de conseils pratiques (parite GR20 `_buildAdviceCard`).
class _AdviceCard extends StatelessWidget {
  const _AdviceCard({required this.advices});

  final List<String> advices;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);
    final accent = theme.colorScheme.secondary;

    return AppCard(
      backgroundColor: accent.withAlpha(15),
      borderColor: accent.withAlpha(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_outline,
                  color: AppTheme.jauneModere, size: 20),
              const SizedBox(width: 8),
              Text(
                t.transport.adviceTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppTheme.jauneModere,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final advice in advices)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('- ',
                      style: TextStyle(color: AppTheme.jauneModere)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(advice, style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Etat informatif quand aucune donnee transport n'est disponible (fallback
/// gracieux — parite « ecran informatif propre », pas de crash).
class _TransportEmptyState extends StatelessWidget {
  const _TransportEmptyState({required this.endpointName, required this.role});

  final String endpointName;
  final TransportRole role;

  @override
  Widget build(BuildContext context) {
    final t = Translations.of(context);
    final theme = Theme.of(context);

    final message = endpointName.isNotEmpty
        ? (role == TransportRole.arrival
            ? t.transport.empty.messageJoin(name: endpointName)
            : t.transport.empty.messageLeave(name: endpointName))
        : t.transport.empty.messageGeneric;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_bus_outlined,
              size: 72,
              color: AppTheme.grisGranite.withAlpha(80),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              t.transport.empty.title,
              style: theme.textTheme.titleLarge
                  ?.copyWith(color: AppTheme.grisGranite),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.grisGranite.withAlpha(180),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Icone Material pour une famille de mode (le domaine ne connait pas Material).
IconData _iconFor(TransportModeKind mode) {
  switch (mode) {
    case TransportModeKind.taxi:
      return Icons.local_taxi;
    case TransportModeKind.bus:
      return Icons.directions_bus;
    case TransportModeKind.train:
      return Icons.train;
    case TransportModeKind.shuttle:
      return Icons.airport_shuttle;
    case TransportModeKind.ferry:
      return Icons.directions_boat;
    case TransportModeKind.plane:
      return Icons.flight;
    case TransportModeKind.carRental:
      return Icons.car_rental;
    case TransportModeKind.other:
      return Icons.place_outlined;
  }
}

/// Couleur semantique d'accent pour une famille de mode (parite esprit GR20 ou
/// chaque mode a sa teinte). Hors peau : tokens semantiques stables d'AppTheme,
/// sauf le BLEU (bus/ferry/avion) qui suit la couleur secondaire de la peau
/// active ([scheme.secondary]) — d'ou le passage du [scheme] plutot qu'une
/// constante bleue figee (absente de la palette StepWays).
Color _colorFor(TransportModeKind mode, ColorScheme scheme) {
  switch (mode) {
    case TransportModeKind.taxi:
      return AppTheme.jauneModere;
    case TransportModeKind.bus:
      return scheme.secondary;
    case TransportModeKind.train:
      return AppTheme.vertFacile;
    case TransportModeKind.shuttle:
      return AppTheme.orangeDifficile;
    case TransportModeKind.ferry:
      return scheme.secondary;
    case TransportModeKind.plane:
      return scheme.secondary;
    case TransportModeKind.carRental:
      return AppTheme.grisGranite;
    case TransportModeKind.other:
      return AppTheme.grisGranite;
  }
}
