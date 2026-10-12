/// Le diplome a l'ecran avant le PDF : photos du carnet, chiffres et trace de
/// la session.
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/analytics/screen_entry.dart';
import '../../../core/branding/app_branding.dart';
import '../../../core/config/trail_config.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/map/fond_de_carte.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/ui/app_haptics.dart';
import '../../../i18n/translations.g.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/attribution_osm.dart';
import '../../../shared/widgets/grise_en_demo.dart';
import '../../journal/journal_facade.dart'
    show JournalEntryModel, journalScreenProvider;
import '../../trek/trek_facade.dart' show cadrageDOuverture;
import '../../../domain/trek_session.dart';
import '../../../domain/trek_completion.dart';
import '../domain/diploma_generator.dart';
import '../domain/diploma_pdf_service.dart';
import '../domain/finisher_number.dart';
import '../providers/session_trace_provider.dart';
import '../../after/after_facade.dart'
    show
        AdventureStats,
        adventureCongratulationsProvider,
        adventureStatsProvider,
        inAppReviewServiceProvider,
        isDiplomaUnlockedProvider,
        latestTrekSessionProvider;
import '../../../core/branding/stepways_icons.dart';
import '../../../core/services/session_demo.dart';

/// Ecran diplome de fin de trek avec recap aventure.
///
/// Affiche : photos journal, statistiques, carte trace, bouton PDF.
/// Tous les textes via Slang (t.diploma.*) -- zero texte en dur.
/// Photos journal integrees via journal_repository existant.
/// E5.17: Declenche la demande d'avis store post-diplome (1 fois par trek).
class DiplomaScreen extends ConsumerStatefulWidget {
  const DiplomaScreen({super.key});

  @override
  ConsumerState<DiplomaScreen> createState() => _DiplomaScreenState();
}

class _DiplomaScreenState extends ConsumerState<DiplomaScreen> {
  final _nameController = TextEditingController();
  bool _isGeneratingPdf = false;

  /// LE NOM TAPE PAR LE RANDONNEUR, vide tant qu'il n'a rien tape.
  ///
  /// A ne PAS confondre avec le nom qu'on ECRIT sur l'apercu : celui-la a un
  /// repli en attente, pour que le certificat existe des l'ouverture. C'est
  /// celui-ci, et lui seul, qui autorise a fabriquer un fichier.
  String get _nomSaisi => _nameController.text.trim();

  @override
  void initState() {
    super.initState();
    observeScreenEntry(ref, ScreenBreadcrumb.diploma);
    // E5.17: Demander un avis store apres affichage du diplome (trek termine).
    // PostFrameCallback pour laisser le build se terminer avant la dialog native.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestInAppReviewIfEligible();
    });
  }

  /// E5.17: Demande d'avis store — 1 seule fois par trek.
  ///
  /// PARITE GR20, LOT 3 : ne se declenche que si le diplome est reellement
  /// ACCESSIBLE (finisher reel ou vitrine). Sur un diplome verrouille, aucun
  /// avis n'est demande (on ne felicite pas un trek non fini).
  Future<void> _requestInAppReviewIfEligible() async {
    if (!ref.read(isDiplomaUnlockedProvider)) return;
    // DEMO : on ne demande pas un avis sur le store pour un diplome simule, et
    // on n'ecrit pas la ligne « avis demande » qui l'empecherait de l'etre le
    // jour d'un VRAI trek termine (tache 634, DEM-260929-1123).
    if (ref.read(enDemoProvider)) return;
    final config = ref.read(trailConfigProvider);
    final trailId = config.id;
    final reviewService = ref.read(inAppReviewServiceProvider);
    await reviewService.requestReviewIfEligible(trailId);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final diplomaT = t.diploma;
    final config = ref.watch(trailConfigProvider);

    // PARITE GR20, LOT 3 (#99433), point 3.B(1) — GATE FINISHER + exception
    // vitrine. Le diplome est VERROUILLE tant que le parcours n'a pas ete
    // reellement parcouru en entier (session `parcoursFullyWalked`), SAUF sur un
    // sentier VITRINE ou il est deverrouille pour la demonstration (comme le
    // diplome GR20 en mode demo). Gate porte par [isDiplomaUnlockedProvider].
    final isUnlocked = ref.watch(isDiplomaUnlockedProvider);
    if (!isUnlocked) {
      return Scaffold(
        // Ph5 (L6d) : AppHeader universel (etat verrouille).
        appBar: AppHeader(title: diplomaT.title),
        body: _LockedState(
          title: diplomaT.lockedTitle,
          message: diplomaT.lockedMessage,
        ),
      );
    }

    // Journal : entrees avec photos (select pour granularite fine)
    final journalEntries = ref.watch(
      journalScreenProvider.select((s) => s.entries),
    );
    final isJournalLoading = ref.watch(
      journalScreenProvider.select((s) => s.isLoading),
    );

    // Filtrer les entrees ayant une photo
    final photoEntries = journalEntries
        .where((e) => e.photoPath != null && e.photoPath!.isNotEmpty)
        .toList();

    // PARITE GR20, LOT 3 (#99433), point 3.B(2) — CHIFFRES REELS. Les stats du
    // diplome refletent la SESSION REELLE (etapes REELLEMENT marchees,
    // distance/D+ parcourus), pas les totaux statiques du sentier. On resout les
    // stats reelles ([adventureStatsProvider]) ; en leur absence (vitrine sans
    // session enregistree, demo), on retombe sur les totaux du sentier pour que
    // la demonstration reste parlante — parite avec la demo GR20.
    final realStats = ref.watch(adventureStatsProvider).value;

    // CORRECTIF L5-7 : la session est OBSERVEE ici, pas lue a la volee plus
    // bas. Un `read` sur un FutureProvider rend `AsyncLoading` tant que rien
    // ne l'observe : le numero de finisher restait alors invisible a l'ecran.
    final session = ref.watch(latestTrekSessionProvider).value;

    // PARITE GR20, LOT 3 (#99433), point 3.B(3) — LIBELLE Integral/partiel,
    // branche sur [TrekCongratulations] du parcours reel.
    final congrats = ref.watch(adventureCongratulationsProvider);

    // LE CERTIFICAT, RECALCULE A CHAQUE IMAGE (tache 836). Tant qu'aucun nom
    // n'est tape, il porte le nom EN ATTENTE : l'ecran de la recompense montre
    // alors le diplome qu'on vient de gagner, pas deux messages de manque.
    final apercu = _construireLeDiplome(
      config,
      realStats,
      nom: _nomSaisi.isEmpty ? diplomaT.namePending : _nomSaisi,
    );

    return Scaffold(
      // Ph5 (L6d) : AppHeader universel (diplome deverrouille).
      appBar: AppHeader(title: diplomaT.title),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.spacingBase),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Titre recap aventure
            _RecapHeader(title: diplomaT.recapTitle),
            const SizedBox(height: AppTheme.spacingLg),

            // Libelle parcours integral / partiel (parite GR20, 3.B.3).
            _ParcoursLabel(congrats: congrats, stats: realStats),
            const SizedBox(height: AppTheme.spacingLg),

            // LE DIPLOME PASSE DEVANT SON RECAPITULATIF (tache 836).
            //
            // CE QUE LA MESURE A DIT, ET POURQUOI RENDRE LE CERTIFICAT NE
            // SUFFISAIT PAS. Une fois l'apercu sorti de son `if`, il existait
            // des l'ouverture — mais il tombait a 1 182 points du haut sur un
            // ecran de 844, soit 338 points SOUS LA PLIURE : trois blocs de
            // recapitulatif le precedaient. Christophe aurait donc toujours
            // ouvert l'ecran sur « Aucune photo dans le journal », et le defaut
            // qu'il a decrit — « a l'ouverture on ne voit que... » — serait
            // reste entier.
            //
            // L'ORDRE SUIT DONC CE QUE L'ECRAN EST : d'abord la recompense (le
            // certificat, le nom a y porter, les deux sorties), ensuite
            // l'aventure en details (photos, chiffres, trace, notes). Le
            // recapitulatif n'a pas disparu d'un pixel, il est dessous.
            _buildDiplomaPreview(Theme.of(context), session, realStats, apercu),
            const SizedBox(height: AppTheme.spacingLg),

            // Saisie du nom
            Text(
              diplomaT.yourName,
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(hintText: diplomaT.namePlaceholder),
              // L'APERCU EST DERIVE, PLUS STOCKE (tache 836). La frappe n'a
              // plus qu'a demander une reconstruction : le certificat se
              // recalcule a chaque image a partir du champ, de la config et des
              // chiffres. Il n'y a donc plus d'etat a oublier de remplir — ce
              // qui etait exactement le defaut.
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // LES DEUX SORTIES DU DIPLOME ECRIVENT UN FICHIER, DONC ELLES SONT
            // GRISEES EN DEMONSTRATION (tache 810).
            //
            // Le diplome s'OUVRE desormais en demonstration — il se lit, il
            // s'admire, son apercu se dessine. Mais `_generatePdf` appelle
            // `DiplomaPdfService.savePdf`, et le partage passe par le MEME
            // chemin : les deux posent un PDF bien reel dans les fichiers du
            // telephone, portant un nom de finisher qui n'a rien marche. C'est
            // precisement ce que la demonstration promet de ne pas faire, et
            // c'est le defaut qu'avait corrige la tache 760 sur les photos du
            // carnet — on ne le rejoue pas ici.
            //
            // GRISEES, ET NON RETIREES : la regle de `GriseEnDemo` n'a que deux
            // branches, active a l'identique ou visiblement indisponible. Un
            // appui DIT pourquoi au lieu de ne rien faire.
            GriseEnDemo(
              child: AppButton(
                label: diplomaT.downloadPdf,
                icon: StepwaysIcons.pdf,
                onPressed: _nomSaisi.isNotEmpty && !_isGeneratingPdf
                    ? () => _generatePdf(
                        config,
                        realStats,
                        session: session,
                        donnees: apercu,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: AppTheme.spacingMd),

            // CORRECTIF L5-7 : le partage du diplome, absent cote StepWays —
            // l'ecran n'avait aucun bouton de partage, ni reel ni decoratif.
            GriseEnDemo(
              child: AppButton(
                label: diplomaT.shareDiploma,
                icon: StepwaysIcons.partager,
                onPressed: _nomSaisi.isNotEmpty && !_isGeneratingPdf
                    ? () => _generatePdf(
                        config,
                        realStats,
                        session: session,
                        donnees: apercu,
                        share: true,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // --- L'AVENTURE EN DETAILS, SOUS LA RECOMPENSE (tache 836) ---
            //
            // Ces quatre sections n'ont pas change d'un pixel : elles ont
            // seulement cesse de passer DEVANT le diplome. Voir la raison
            // mesuree au-dessus de l'apercu.

            // Section photos journal
            _JournalPhotosSection(
              photoEntries: photoEntries,
              isLoading: isJournalLoading,
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Section statistiques REELLES de la session (fallback config).
            _StatsSection(config: config, stats: realStats),
            const SizedBox(height: AppTheme.spacingLg),

            // Section carte trace (trace GPS reel de la session — F3)
            const _MapTraceSection(),
            const SizedBox(height: AppTheme.spacingLg),

            // Section journal count
            _JournalCountSection(count: journalEntries.length),
          ],
        ),
      ),
    );
  }

  /// Numero de finisher de la session en cours (CORRECTIF L5-7).
  ///
  /// `null` tant qu'aucune session n'est lisible : on prefere un diplome
  /// sans numero a un numero invente.
  String? _finisherNumber(TrekSession? session, AdventureStats? stats) {
    if (session == null) return null;
    final number = buildFinisherNumber(
      sessionId: session.id,
      finishedAt: session.finishedAt ?? stats?.endDate ?? DateTime.now(),
    );
    return t.diploma.finisherNumber(number: number);
  }

  /// LE CERTIFICAT, CALCULE SANS RIEN STOCKER (tache 836).
  ///
  /// C'etait une methode a `setState` qui remplissait un champ d'etat, et qui
  /// le remettait a `null` quand le nom etait vide. Deux consequences, dont une
  /// etait le defaut constate : il n'y avait AUCUN certificat a l'ouverture de
  /// l'ecran (rien n'appelait cette methode), et il fallait se souvenir de la
  /// rappeler a chaque changement de chiffres.
  ///
  /// Derive de ses entrees, le certificat ne peut plus manquer : il existe des
  /// le premier build. [nom] est deja resolu par l'appelant — le nom tape, ou
  /// le nom en attente.
  DiplomaData _construireLeDiplome(
    TrailConfig config,
    AdventureStats? stats, {
    required String nom,
  }) {
    // Chiffres REELS de la session si disponibles (etapes marchees,
    // distance/D+ parcourus, duree/date reelles), sinon fallback totaux du
    // sentier (demo/vitrine sans session). Parite GR20, 3.B.2.
    final useReal = stats != null && stats.hasWalkedStages;
    return DiplomaGenerator.createDiploma(
      hikerName: nom,
      trailName: config.displayName,
      trailRegion: config.region,
      totalStages: useReal ? stats.stagesWalked : config.totalStages,
      totalDistanceKm: useReal ? stats.distanceKm : config.totalDistanceKm,
      totalElevationGain: useReal
          ? stats.elevationGainM
          : config.totalElevationGain,
      completionDate: useReal
          ? (stats.endDate ?? DateTime.now())
          : DateTime.now(),
      durationDays: useReal ? stats.durationDays : config.defaultDuration,
    );
  }

  Widget _buildDiplomaPreview(
    ThemeData theme,
    TrekSession? session,
    AdventureStats? stats,
    DiplomaData data,
  ) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(
            color: theme.colorScheme.primary.withAlpha(100),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            StepIcon(
              StepwaysIcons.diploma,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: AppTheme.spacingBase),
            Text(
              t.diploma.pdfTitle,
              style: theme.textTheme.headlineLarge?.copyWith(letterSpacing: 8),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(data.trailName, style: theme.textTheme.titleLarge),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              data.mainText,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              data.formattedDate,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontStyle: FontStyle.italic,
              ),
            ),
            // CORRECTIF L5-7 : le numero de finisher, visible a l'ecran comme
            // sur le PDF. Absent quand aucune session n'est lisible : un
            // diplome sans numero vaut mieux qu'un numero invente.
            if (_finisherNumber(session, stats) case final number?) ...[
              const SizedBox(height: AppTheme.spacingSm),
              Text(
                number,
                style: theme.textTheme.bodySmall?.copyWith(
                  letterSpacing: 1.5,
                  color: theme.colorScheme.onSurface.withAlpha(150),
                ),
              ),
            ],
            // LA MARQUE DE CELUI QUI DELIVRE LE DIPLOME (tache 632), au meme
            // endroit que sur le PDF : en bas, sous le numero de finisher.
            // L'apercu et le document imprime doivent se ressembler — sinon le
            // randonneur decouvre le logo en ouvrant le fichier.
            const SizedBox(height: AppTheme.spacingLg),
            const AppLogo.horizontal(hauteur: 24),
          ],
        ),
      ),
    );
  }

  /// Genere le PDF via DiplomaPdfService.
  Future<void> _generatePdf(
    TrailConfig config,
    AdventureStats? stats, {
    required DiplomaData donnees,
    TrekSession? session,
    bool share = false,
  }) async {
    // UN FICHIER N'EST ECRIT QUE POUR UN NOM REEL (tache 836). L'apercu existe
    // des l'ouverture avec un nom en attente ; un PDF portant ce repli serait
    // un faux diplome pose dans les fichiers du telephone. Les deux boutons
    // sont deja desactives sans nom — cette garde est la seconde serrure, pour
    // qu'un futur appelant ne puisse pas l'oublier.
    if (_nomSaisi.isEmpty) return;
    // E5.5a : retour haptique moyen a la generation du diplome.
    AppHaptics.medium();
    setState(() => _isGeneratingPdf = true);

    try {
      final diplomaT = t.diploma;
      // Chiffres REELS de la session si disponibles, sinon totaux du sentier
      // (demo/vitrine). Meme regle que l'apercu (parite GR20, 3.B.2).
      final useReal = stats != null && stats.hasWalkedStages;
      final endDate = useReal
          ? (stats.endDate ?? DateTime.now())
          : DateTime.now();
      final startDate = useReal
          ? (stats.startDate ??
                endDate.subtract(Duration(days: stats.durationDays)))
          : DateTime.now().subtract(Duration(days: config.defaultDuration));
      final data = DiplomaPdfData(
        hikerName: donnees.hikerName,
        trailName: config.displayName,
        trailRegion: config.region,
        totalStages: useReal ? stats.stagesWalked : config.totalStages,
        totalDistanceKm: useReal ? stats.distanceKm : config.totalDistanceKm,
        totalElevationGain: useReal
            ? stats.elevationGainM
            : config.totalElevationGain,
        startDate: startDate,
        endDate: endDate,
        durationDays: useReal ? stats.durationDays : config.defaultDuration,
      );

      final labels = DiplomaPdfLabels(
        title: diplomaT.pdfTitle,
        subtitle: diplomaT.pdfSubtitle,
        certifies: diplomaT.certifies,
        completed: diplomaT.completed,
        stages: diplomaT.pdfStages,
        distance: diplomaT.pdfDistance,
        elevation: diplomaT.pdfElevation,
        duration: diplomaT.pdfDuration,
        from: diplomaT.pdfFrom,
        to: diplomaT.pdfTo,
        issuedOn: diplomaT.pdfIssuedOn,
        // CORRECTIF L5-7 : le numero de finisher est imprime SUR le
        // document. Un numero visible a l'ecran mais absent du PDF ne
        // certifierait rien — c'est le fichier qui circule.
        finisherNumber: _finisherNumber(session, stats),
      );

      // LE LOGO EST LU ICI, PAS DANS LE SERVICE (tache 632). L'ecran a un
      // paquet d'assets sous la main ; le service du domaine, lui, tourne aussi
      // dans des tests sans liaison Flutter initialisee et ne doit rien savoir
      // de `rootBundle`. Si la lecture echoue, le diplome sort quand meme —
      // sans marque plutot que pas du tout.
      String? logoSvg;
      try {
        logoSvg = await DefaultAssetBundle.of(
          context,
        ).loadString(AppBranding.logoHorizontal);
      } catch (_) {
        logoSvg = null;
      }

      // CORRECTIF L5-1 : le retour de generatePdf est AFFECTE, puis ECRIT.
      // Avant, les octets etaient calcules puis jetes, et le message qui
      // suivait reprenait le LIBELLE DU BOUTON — le randonneur croyait
      // avoir telecharge son diplome alors qu'aucun fichier n'existait.
      final bytes = await DiplomaPdfService.generatePdf(
        data: data,
        labels: labels,
        logoSvg: logoSvg,
      );
      final file = await DiplomaPdfService.savePdf(
        bytes: bytes,
        trailId: config.id,
      );

      // Le partage vient APRES l'ecriture : on ne propose jamais un fichier
      // qui n'existe pas encore.
      if (share) {
        await Share.shareXFiles([XFile(file.path)], subject: diplomaT.title);
        return;
      }

      if (mounted) {
        // On nomme le FICHIER REELLEMENT ecrit : un message qui reprend le
        // libelle du bouton ne prouve rien.
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(diplomaT.pdfSaved(file: file.uri.pathSegments.last)),
          ),
        );
      }
    } catch (_) {
      // Un echec d'ecriture (support plein, permission) doit se VOIR :
      // le silence rejouerait exactement le defaut corrige ici.
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(share ? t.diploma.shareError : t.diploma.pdfError),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }
}

// ---------------------------------------------------------------------------
// Widgets prives
// ---------------------------------------------------------------------------

/// En-tete de la section recap aventure.
class _RecapHeader extends StatelessWidget {
  const _RecapHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        StepIcon(
          StepwaysIcons.sommet,
          color: theme.colorScheme.primary,
          size: 28,
        ),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(
          child: Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

/// Section photos du journal avec carrousel horizontal.
class _JournalPhotosSection extends StatelessWidget {
  const _JournalPhotosSection({
    required this.photoEntries,
    required this.isLoading,
  });

  final List<JournalEntryModel> photoEntries;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diplomaT = t.diploma;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          diplomaT.recapJournalPhotos,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        if (isLoading)
          const Center(child: CircularProgressIndicator())
        else if (photoEntries.isEmpty)
          AppCard(
            padding: const EdgeInsets.all(AppTheme.spacingLg),
            child: Center(
              child: Text(
                diplomaT.recapNoPhotos,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.grisTexteSecondaire,
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photoEntries.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: AppTheme.spacingSm),
              itemBuilder: (context, index) {
                final entry = photoEntries[index];
                return _PhotoCard(entry: entry);
              },
            ),
          ),
      ],
    );
  }
}

/// Carte individuelle pour une photo du journal.
class _PhotoCard extends StatelessWidget {
  const _PhotoCard({required this.entry});
  final JournalEntryModel entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final file = File(entry.photoPath!);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      child: SizedBox(
        width: 140,
        height: 160,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image de la photo
            file.existsSync()
                ? Image.file(file, fit: BoxFit.cover)
                : Container(
                    color: AppTheme.grisClair,
                    child: const StepIcon(
                      StepwaysIcons.imageManquante,
                      size: 40,
                    ),
                  ),
            // Etiquette etape en bas
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  vertical: AppTheme.spacingXs,
                  horizontal: AppTheme.spacingSm,
                ),
                color: Colors.black54,
                child: Text(
                  '${t.journal.stage} ${entry.stageNumber}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Section statistiques du trek.
///
/// PARITE GR20, LOT 3 (#99433), point 3.B(2) : affiche les chiffres de la
/// SESSION REELLE ([stats]) — etapes REELLEMENT marchees, distance/D+
/// parcourus, duree reelle — quand ils existent. En leur absence (vitrine sans
/// session enregistree / demo), retombe sur les totaux du sentier ([config])
/// pour une demonstration parlante (parite avec la demo GR20).
class _StatsSection extends StatelessWidget {
  const _StatsSection({required this.config, required this.stats});
  final TrailConfig config;
  final AdventureStats? stats;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diplomaT = t.diploma;

    final useReal = stats != null && stats!.hasWalkedStages;
    final stagesText = useReal
        ? '${stats!.stagesWalked}'
        : '${config.totalStages}';
    final distanceText = useReal
        ? stats!.distanceKm.toStringAsFixed(0)
        : config.totalDistanceKm.toStringAsFixed(0);
    final elevationText = useReal
        ? '${stats!.elevationGainM}'
        : '${config.totalElevationGain}';
    final durationText = useReal
        ? '${stats!.durationDays}'
        : '${config.defaultDuration}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          diplomaT.recapStats,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        AppCard(
          child: Column(
            children: [
              _StatRow(
                icon: StepwaysIcons.depart,
                label: diplomaT.recapStages.replaceAll('{count}', stagesText),
              ),
              const Divider(height: AppTheme.spacingBase),
              _StatRow(
                icon: StepwaysIcons.distance,
                label: diplomaT.recapDistance.replaceAll('{km}', distanceText),
              ),
              const Divider(height: AppTheme.spacingBase),
              _StatRow(
                icon: StepwaysIcons.denivelePlus,
                label: diplomaT.recapElevation.replaceAll(
                  '{meters}',
                  elevationText,
                ),
              ),
              const Divider(height: AppTheme.spacingBase),
              _StatRow(
                icon: StepwaysIcons.calendrier,
                label: diplomaT.recapDuration.replaceAll(
                  '{days}',
                  durationText,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Libelle « Parcours integral / partiel » derive du parcours reel.
///
/// PARITE GR20, LOT 3 (#99433), point 3.B(3) : branche
/// [TrekCongratulations.partialLabel]/[TrekCompletionKind] -> libelle i18n.
/// « Integral » quand le parcours reel est ENTIER et fini (finisher) ;
/// « partiel » sinon. Sans plan (pas d'etapes chargees), rien n'est affiche.
class _ParcoursLabel extends StatelessWidget {
  const _ParcoursLabel({required this.congrats, required this.stats});
  final TrekCongratulations? congrats;
  final AdventureStats? stats;

  @override
  Widget build(BuildContext context) {
    final congrats = this.congrats;
    if (congrats == null) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final diplomaT = t.diploma;

    // Integral = parcours ENTIER reellement fini (finisher). Un parcours partiel
    // (portion) OU non entierement marche -> libelle « partiel ».
    final isIntegral = congrats.isFull && (stats?.fullyWalked ?? false);
    final label = isIntegral ? diplomaT.labelIntegral : diplomaT.labelPartial;

    return Semantics(
      label: label,
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.spacingBase,
            vertical: AppTheme.spacingSm,
          ),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withAlpha(30),
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StepIcon(
                isIntegral ? StepwaysIcons.diploma : StepwaysIcons.sommet,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: AppTheme.spacingSm),
              Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Etat verrouille du diplome (trek non fini, hors vitrine) — parite GR20.
class _LockedState extends StatelessWidget {
  const _LockedState({required this.title, required this.message});
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingLg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const StepIcon(
              StepwaysIcons.cadenas,
              size: 64,
              color: AppTheme.grisTexteSecondaire,
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppTheme.grisTexteSecondaire,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppTheme.grisTexteSecondaire,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Ligne de statistique individuelle avec icone.
class _StatRow extends StatelessWidget {
  const _StatRow({required this.icon, required this.label});
  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        StepIcon(icon, color: theme.colorScheme.primary, size: 22),
        const SizedBox(width: AppTheme.spacingSm),
        Expanded(child: Text(label, style: theme.textTheme.bodyLarge)),
      ],
    );
  }
}

/// Section carte du trace — la trace de la session, SUR UNE CARTE (F3).
///
/// Lit la trace de la derniere session par [sessionTraceProvider] — les points
/// persistes au fil de l'eau, ou la matiere fabriquee en demonstration — et la
/// pose sur le fond de carte du sentier. Repli : le message `recapNoMap` quand
/// il n'y a pas deux points a relier.
class _MapTraceSection extends ConsumerWidget {
  const _MapTraceSection();

  /// La hauteur du cadre de la trace, en points (valeur de parite).
  static const double _hauteurDeLaTrace = 180;

  /// La marge entre la trace et le bord du cadre, en points.
  ///
  /// Nommee parce qu'elle sert DEUX fois : au cadrage d'ouverture, qui en
  /// deduit le zoom, et au `initialCameraFit` garde-fou. Deux valeurs
  /// differentes feraient sauter la vue entre la premiere image et la suivante.
  static const double _margeDeLaTrace = 16;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final diplomaT = t.diploma;
    final traceAsync = ref.watch(sessionTraceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          diplomaT.recapMapTrace,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppTheme.spacingSm),
        // LA TRACE DU DIPLOME EST SUR UNE CARTE, COMME CELLE DU CARNET
        // (tache 836).
        //
        // ELLE ETAIT DESSINEE A NU : un [SessionTracePainter] posait la
        // polyligne sur le fond de la carte-conteneur, sans aucune tuile.
        // Christophe a releve les deux ecrans cote a cote — le carnet montre la
        // trace sur une carte, le diplome la montrait sur du vide, quand il la
        // montrait. Un diplome est l'ecran de la recompense : la trace y doit
        // etre LISIBLE, c'est-a-dire posee sur un terrain.
        //
        // MEME MONTAGE QUE LA VIGNETTE DU CARNET, et pour les memes raisons
        // ecrites la-bas : fond par [FondDeCarte] (seul autorise a batir une
        // couche de tuiles), centre et zoom calcules AVANT la premiere
        // image par `cadrageDOuverture` — sans quoi le fond reste gris
        // definitivement, puisque la vignette n'accepte aucun geste — et
        // l'attribution ODbL, obligatoire des qu'on affiche de l'OSM.
        //
        // LE PEINTRE N'EST PAS SUPPRIME : le recapitulatif d'aventure l'emploie
        // encore, ou le rendu sans tuiles est assume. Ce lot ne touche qu'aux
        // deux ecrans que Christophe a nommes.
        AppCard(
          padding: EdgeInsets.zero,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            child: SizedBox(
              height: _hauteurDeLaTrace,
              width: double.infinity,
              child: traceAsync.when(
                data: (points) {
                  if (points.length < 2) {
                    return _NoTracePlaceholder(message: diplomaT.recapNoMap);
                  }
                  final latLngs = [
                    for (final p in points) LatLng(p.lat, p.lng),
                  ];
                  final cible = LatLngBounds.fromPoints(latLngs);
                  return LayoutBuilder(
                    builder: (context, contraintes) {
                      final ouverture = cadrageDOuverture(
                        cible,
                        _margeDeLaTrace,
                        contraintes.biggest,
                      );
                      return FlutterMap(
                        options: MapOptions(
                          initialCenter: ouverture.centre,
                          initialZoom: ouverture.zoom,
                          initialCameraFit: CameraFit.bounds(
                            bounds: cible,
                            padding: const EdgeInsets.all(_margeDeLaTrace),
                          ),
                          // Vignette de lecture : aucun geste, pour ne pas
                          // voler le defilement du diplome sous le doigt.
                          interactionOptions: const InteractionOptions(
                            flags: InteractiveFlag.none,
                          ),
                        ),
                        children: [
                          const FondDeCarte.duSentierActif(),
                          PolylineLayer(
                            polylines: [
                              Polyline(
                                points: latLngs,
                                strokeWidth: 3,
                                color: theme.colorScheme.primary,
                              ),
                            ],
                          ),
                          const AttributionOsm(),
                        ],
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) =>
                    _NoTracePlaceholder(message: diplomaT.recapNoMap),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Placeholder affiche quand aucun trace de session n'est disponible.
class _NoTracePlaceholder extends StatelessWidget {
  const _NoTracePlaceholder({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StepIcon(
            StepwaysIcons.map,
            size: 48,
            color: theme.colorScheme.primary.withAlpha(120),
          ),
          const SizedBox(height: AppTheme.spacingSm),
          Text(
            message,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.grisTexteSecondaire,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section compteur notes journal.
class _JournalCountSection extends StatelessWidget {
  const _JournalCountSection({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final diplomaT = t.diploma;

    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        leading: StepIcon(
          StepwaysIcons.journal,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          diplomaT.recapJournalEntries.replaceAll('{count}', '$count'),
          style: theme.textTheme.bodyLarge,
        ),
      ),
    );
  }
}
