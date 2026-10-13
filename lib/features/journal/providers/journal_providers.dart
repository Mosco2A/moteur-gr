/// Le cablage du carnet, de la base jusqu'a l'ecran, en passant par le service
/// de photos hors ligne.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/daos/journal_dao.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../domain/matiere_de_demo.dart';
import '../../../i18n/translations.g.dart';
import '../../trail/trail_facade.dart' show stagesProvider;
// LA MEME SOURCE D'ETAPES QUE LE RECAPITULATIF (tache 810).
// `domainStagesProvider` est le derive SYNCHRONE des etapes du sentier ACTIF,
// en modele de domaine : c'est celui que lit `adventureStatsProvider`.
// Fabriquer le carnet et le recapitulatif sur deux listes differentes aurait
// permis a l'un de nommer une etape que l'autre ignore.
import '../../trek/trek_facade.dart' show domainStagesProvider;
import '../data/journal_repository.dart';
import '../data/photo_service.dart';
import '../domain/models/journal_entry.dart';
import '../../../core/services/session_demo.dart';

// ---------------------------------------------------------------------------
// Providers Riverpod 3 pour le journal de trek (E3.1c)
//
// Convention : select() partout, zero ref.watch brut dans build.
// Tout texte UI passe par Slang (t.journal.*).
// ---------------------------------------------------------------------------

/// Provider du DAO journal — couche basse Drift.
final journalDaoProvider = Provider<JournalDao>((ref) {
  return JournalDao(ref.watch(databaseProvider));
});

/// Provider du repository journal — couche domaine.
final journalRepositoryProvider = Provider<JournalRepository>((ref) {
  final dao = ref.watch(journalDaoProvider);
  return JournalRepository(dao);
});

/// Provider du PhotoService — gestion photos offline.
final photoServiceProvider = Provider<PhotoService>((ref) {
  final dao = ref.watch(journalDaoProvider);
  return PhotoService(journalDao: dao);
});

/// Etat du journal pour un sentier donne.
///
/// Contient les entrees groupees par jour, l'indicateur de chargement,
/// et les compteurs photo (limite quotidienne 3/jour).
class JournalScreenState {
  const JournalScreenState({
    this.entries = const [],
    this.isLoading = false,
    this.canAddPhoto = true,
    this.photosToday = 0,
  });

  /// Toutes les entrees du journal, triees par date descendante.
  final List<JournalEntryModel> entries;

  /// Vrai pendant le chargement initial depuis la base.
  final bool isLoading;

  /// Vrai si on peut encore ajouter une photo aujourd'hui (max 3).
  final bool canAddPhoto;

  /// Nombre de photos ajoutees aujourd'hui.
  final int photosToday;

  JournalScreenState copyWith({
    List<JournalEntryModel>? entries,
    bool? isLoading,
    bool? canAddPhoto,
    int? photosToday,
  }) {
    return JournalScreenState(
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      canAddPhoto: canAddPhoto ?? this.canAddPhoto,
      photosToday: photosToday ?? this.photosToday,
    );
  }

  /// Entrees regroupees par cle de date (format ISO yyyy-MM-dd).
  ///
  /// Utilise pour l'affichage par jour dans journal_screen.
  Map<String, List<JournalEntryModel>> get entriesByDay {
    final grouped = <String, List<JournalEntryModel>>{};
    for (final entry in entries) {
      final key = _dayKey(entry.createdAt);
      grouped.putIfAbsent(key, () => []).add(entry);
    }
    return grouped;
  }

  /// Cle de regroupement : yyyy-MM-dd.
  static String _dayKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}'
        '-${dt.day.toString().padLeft(2, '0')}';
  }
}

/// LES PAGES FABRIQUEES DU CARNET, POUR LA DEMONSTRATION (tache 810).
///
/// LA LOI, POSEE PAR CHRISTOPHE LE 11/10/2026 A 09:27, verbatim : « tu rends
/// accessible le faux journal er le faux recap oui . Demo = toutes les
/// fonctionalite visible mais bouchonnees ». EN DEMO, TOUT SE VOIT, RIEN NE
/// S'ECRIT.
///
/// CE QUI ETAIT VIDE, ET POURQUOI. Le carnet n'etait pas FERME en demonstration
/// — il s'ouvrait deja en lecture (cf. [JournalScreen], tache 638). Il etait
/// VIDE, et pour une raison mecanique : ses quatre gestes d'ecriture sont
/// barres en demonstration, donc aucune entree ne nait, donc
/// `_EmptyJournalView` s'affichait. « Ton journal est vide » n'apprend rien a
/// qui veut voir a quoi sert un journal.
///
/// UNE PAGE PAR JOUR DE MARCHE, et le texte de chaque page nomme l'etape
/// REELLEMENT marchee ce jour-la, dans la langue de l'application. Les quatre
/// modeles de note tournent — depart, montee, village, arrivee — pour qu'un
/// carnet de sept jours ne lise pas sept fois la meme phrase.
///
/// AUCUNE PHOTO N'EST FABRIQUEE, et c'est delibere. Une entree de carnet avec
/// photo porte un CHEMIN DE FICHIER ([JournalEntryModel.photoPath]) : fabriquer
/// la ligne obligerait a fabriquer le fichier, c'est-a-dire a ECRIRE sur le
/// telephone — exactement ce que la demonstration promet de ne pas faire, et
/// exactement le defaut que la tache 760 a corrige sur ce meme ecran. Les pages
/// fabriquees sont donc des notes, et le bouton photo reste grise.
List<JournalEntryModel> pagesFabriqueesDuCarnet(
  MatiereDeDemo matiere, {
  required String langue,
}) {
  final pages = <JournalEntryModel>[];
  final journees = matiere.journees;
  for (var i = 0; i < journees.length; i++) {
    final journee = journees[i];
    final etape = journee.etape.nomLocalise(langue);
    final texte = switch (i) {
      0 => t.demo.carnetNoteDepart(nom: etape),
      _ when i == journees.length - 1 => t.demo.carnetNoteArrivee(nom: etape),
      _ when i.isOdd => t.demo.carnetNoteMontee(nom: etape),
      _ => t.demo.carnetNoteVillage(nom: etape),
    };
    pages.add(
      JournalEntryModel(
        // NEGATIF, DONC RECONNAISSABLE. Une cle Drift auto-incrementee vaut 1
        // ou plus : cet identifiant ne peut designer qu'une page fabriquee, et
        // il n'entrera jamais en collision avec une page du randonneur.
        id: MatiereDeDemo.idEntreeFabriquee(i + 1),
        trailId: matiere.session.trailId,
        stageNumber: journee.etape.orderIndex,
        text: texte,
        // L'heure d'ARRIVEE de la journee : on ecrit son carnet le soir, et
        // c'est cette date qui range la page dans sa journee.
        createdAt: journee.arrivee,
      ),
    );
  }
  return pages;
}

/// Notifier Riverpod 3 pour le journal de trek.
///
/// Charge les entrees depuis le repository, gere les CRUD notes/photos,
/// et maintient le compteur de quota photos quotidien.
class JournalScreenNotifier extends Notifier<JournalScreenState> {
  late JournalRepository _repo;
  late PhotoService _photoService;
  late String _trailId;

  /// La matiere fabriquee de la demonstration, ou `null` hors demonstration.
  MatiereDeDemo? _matiere;

  /// NUMERO DE LA CONSTRUCTION EN COURS — IL REND CADUQUE UN CHARGEMENT PARTI
  /// TROP TOT (tache 810).
  ///
  /// LE DEFAUT QU'IL CORRIGE, ET IL ETAIT MESURABLE. Riverpod REUTILISE
  /// l'instance d'un [Notifier] quand il le reconstruit : `build()` est rappele
  /// sur le MEME objet. Un [_loadEntries] parti a la construction precedente
  /// continuait donc de tourner et, en revenant, ecrivait son resultat dans
  /// l'etat COURANT. Scenario reel : le randonneur a son carnet ouvert, hors
  /// demonstration (un chargement de base part) ; il entre en demonstration (le
  /// notifier se reconstruit et pose les pages fabriquees) ; le chargement
  /// d'avant revient et REMPLACE les pages fabriquees par ce qu'il a lu. Un
  /// test du lot l'a attrape — le carnet rendait zero page en demonstration
  /// alors qu'il venait d'en poser quatre.
  ///
  /// Le meme defaut joue dans l'autre sens, et il est pire : a la sortie de
  /// demonstration, un chargement parti PENDANT la demonstration pourrait
  /// reposer un etat de demonstration sur le carnet reel.
  int _construction = 0;

  @override
  JournalScreenState build() {
    // `watch` SUR LE REPOSITORY (tache 564, LOT M, M1). Avec `read`, ce notifier
    // ne declarait AUCUNE dependance : invalider le repository — ce que fait
    // l'effacement art. 17 pour vider la memoire vive — ne le reconstruisait pas,
    // et le journal restait affiche apres avoir ete efface, alors que le dialogue
    // d'effacement promet « votre journal » noir sur blanc. Les deux autres
    // lectures restent en `read` : elles ne portent pas de donnee personnelle et
    // un `watch` y changerait le comportement de l'ecran.
    _repo = ref.watch(journalRepositoryProvider);
    _photoService = ref.read(photoServiceProvider);
    _trailId = ref.read(trailIdProvider);
    // TACHE 810 — LA MATIERE FABRIQUEE, RECONSTRUITE A CHAQUE ENTREE EN DEMO.
    //
    // `watch` et non `read` sur les trois : entrer ou sortir de la
    // demonstration doit RECONSTRUIRE ce notifier, sinon le carnet garderait
    // les pages fabriquees apres la sortie — le defaut meme que ce lot doit
    // rendre impossible. `generationDeDemoProvider` couvre le cas « sortir
    // puis rentrer » : Riverpod ne recalcule pas un provider dont la
    // dependance a retrouve sa valeur precedente (cf. `session_demo.dart`).
    // Toute construction rend caduc un chargement parti a la precedente.
    _construction++;
    final enDemo = ref.watch(enDemoProvider);
    ref.watch(generationDeDemoProvider);
    final etapes = enDemo ? ref.watch(domainStagesProvider) : null;
    _matiere = etapes == null || etapes.isEmpty
        ? null
        : MatiereDeDemo.pourSentier(
            trailId: _trailId,
            etapes: etapes,
            arriveeLe: DateTime.now(),
          );
    // EN DEMONSTRATION, [_loadEntries] N'EST MEME PAS APPELE, ET C'EST LE
    // POINT LE PLUS IMPORTANT DE CETTE METHODE.
    //
    // CE QUE LA PREMIERE VERSION DE CE LOT FAISAIT, ET POURQUOI C'ETAIT GRAVE.
    // Elle ne sortait ici que si la matiere etait DEJA prete, et retombait
    // sinon sur le chargeur de la base. Or la matiere nait des etapes du
    // sentier, qui se chargent de facon ASYNCHRONE : pendant ce court instant,
    // `enDemo` valait deja vrai et le carnet lisait la base. Il affichait donc
    // les VRAIES pages du randonneur, les siennes, a l'interieur d'une
    // demonstration — l'inverse exact de la promesse. Un test du lot l'a
    // attrape (« une page par etape seedee » rendait zero page).
    //
    // La regle est donc SANS CONDITION : en demonstration, la base n'est pas
    // lue. Tant que les etapes ne sont pas la, le carnet se dit en chargement —
    // un instant de roue tournante, jamais une page qui n'est pas a nous.
    //
    // Les pages fabriquees, elles, sont rendues ICI plutot que par le chargeur
    // asynchrone : elles sont disponibles SANS attendre, et passer par
    // [_loadEntries] poserait l'etat PENDANT le `build()`, ce que Riverpod
    // refuse.
    if (enDemo) {
      final fabriquee = _matiere;
      return JournalScreenState(
        entries: fabriquee == null
            ? const <JournalEntryModel>[]
            : pagesFabriqueesDuCarnet(
                fabriquee,
                langue: LocaleSettings.currentLocale.languageCode,
              ),
        // Les etapes du sentier se chargent encore : on attend la matiere, on
        // ne va pas chercher autre chose a montrer.
        isLoading: fabriquee == null,
        canAddPhoto: false,
      );
    }
    _loadEntries();
    return const JournalScreenState(isLoading: true);
  }

  /// Charge les entrees du sentier actif depuis la base.
  ///
  /// EN DEMONSTRATION, LA BASE N'EST PAS LUE DU TOUT. Deux raisons, et la
  /// seconde est la plus importante : les pages fabriquees remplaceraient de
  /// toute facon ce qu'on y lirait, et surtout une demonstration n'a RIEN a
  /// montrer des vraies pages du randonneur sur ce sentier. Le carnet de
  /// demonstration est une vitrine, pas une fenetre sur les souvenirs de
  /// quelqu'un.
  Future<void> _loadEntries() async {
    final construction = _construction;
    final enDemoAuDepart = ref.read(enDemoProvider);
    final matiere = _matiere;
    if (matiere != null) {
      state = state.copyWith(
        entries: pagesFabriqueesDuCarnet(
          matiere,
          langue: LocaleSettings.currentLocale.languageCode,
        ),
        isLoading: false,
        // L'ajout de photo est grise en demonstration : le compteur du jour
        // n'a personne a renseigner, et l'interroger lirait la base.
        canAddPhoto: false,
        photosToday: 0,
      );
      return;
    }
    final entries = await _repo.getByTrailId(_trailId);
    final photosToday = await _photoService.photosToday(_trailId);
    // CE RESULTAT PARLE-T-IL ENCORE DU MONDE OU IL EST PARTI ? Deux facons d'en
    // sortir, et il faut les DEUX.
    //
    //  1. LE NOTIFIER A ETE RECONSTRUIT (cf. [_construction]).
    //  2. LA DEMONSTRATION A BASCULE SANS RECONSTRUCTION, et c'est le cas
    //     retors — celui qu'un test de ce lot a mis a jour. Entrer en
    //     demonstration marque bien ce notifier a refaire, mais la
    //     reconstruction est PARESSEUSE : elle n'a lieu qu'a la prochaine
    //     lecture. Si ce chargement-ci revient avant, son `state =` pose une
    //     valeur FRAICHE et annule la reconstruction en attente. Le carnet
    //     restait alors sur ce que la base avait rendu — les vraies pages du
    //     randonneur — pour tout le reste de la demonstration.
    //
    // On ne se contente donc pas de jeter le resultat : en ne touchant PAS a
    // l'etat, on laisse vivre la reconstruction en attente, qui posera les
    // pages fabriquees.
    if (construction != _construction) return;
    if (ref.read(enDemoProvider) != enDemoAuDepart) return;
    final canAdd = photosToday < PhotoService.maxPhotosPerDay;
    state = state.copyWith(
      entries: entries,
      isLoading: false,
      canAddPhoto: canAdd,
      photosToday: photosToday,
    );
  }

  /// Ajoute une note textuelle au journal.
  Future<void> addNote({
    required int stageNumber,
    required String content,
  }) async {
    // DEMO : rien ne s'ecrit (tache 634, DEM-260929-1123). Christophe :
    // « ON EST EN MODE DEMO » = rien ne compte, « rien en base ».
    if (ref.read(enDemoProvider)) return;
    await _repo.addNote(
      trailId: _trailId,
      stageNumber: stageNumber,
      text: content,
    );
    await _loadEntries();
  }

  /// Ajoute une entree de journal AVEC une photo (R10, LOT L10).
  ///
  /// [sourcePath] est le fichier choisi par l'utilisateur (appareil photo ou
  /// galerie). Il est compresse et recopie dans le stockage local du journal par
  /// [PhotoService] (<= 500 Ko, 3 photos/jour), PUIS seulement l'entree est
  /// inseree : jamais de ligne en base pointant vers un fichier absent.
  /// [content] peut etre vide (photo seule).
  ///
  /// Retourne `null` en cas de succes, sinon le [PhotoError] a presenter a
  /// l'utilisateur (quota du jour atteint, photo trop lourde, fichier
  /// introuvable, erreur disque).
  Future<PhotoError?> addPhotoNote({
    required int stageNumber,
    required String content,
    required String sourcePath,
  }) async {
    // DEMO : LA GARDE PASSE DEVANT L'ECRITURE DU FICHIER (tache 760).
    //
    // ELLE ETAIT UNE LIGNE TROP BAS, ET C'ETAIT MESURABLE. La barriere du lot
    // 634 ne protegeait que la BASE : `savePhotoFromFile` tournait AVANT elle,
    // donc chaque photo prise en demo etait compressee et recopiee dans
    // `journal_photos/` — un JPEG bien reel, sans aucune ligne de journal pour
    // le designer. Jamais affiche (le carnet lit la base), jamais compte au
    // quota du jour, jamais efface : un orphelin sur le telephone, a l'endroit
    // meme ou l'application promet que « rien n'est enregistre ».
    //
    // Rien n'est perdu pour le randonneur : en demo le carnet est en lecture
    // seule et son bouton d'ajout est grise, donc ce chemin n'est atteint que
    // par un ecran qui aurait oublie de griser — exactement le cas que la
    // barriere d'ecriture existe pour couvrir.
    if (ref.read(enDemoProvider)) return null;

    final saved = await _photoService.savePhotoFromFile(
      trailId: _trailId,
      sourcePath: sourcePath,
    );
    if (!saved.isSuccess) return saved.error ?? PhotoError.ioError;

    await _repo.addPhotoNote(
      trailId: _trailId,
      stageNumber: stageNumber,
      text: content,
      photoPath: saved.path!,
      photoSizeBytes: saved.sizeBytes ?? 0,
    );
    await _loadEntries();
    return null;
  }

  /// Met a jour le texte d'une entree existante.
  Future<void> updateNote(int entryId, String content) async {
    // DEMO : rien ne s'ecrit (tache 634, DEM-260929-1123). Christophe :
    // « ON EST EN MODE DEMO » = rien ne compte, « rien en base ».
    if (ref.read(enDemoProvider)) return;
    await _repo.updateNote(entryId, content);
    await _loadEntries();
  }

  /// Supprime une entree par son identifiant.
  Future<void> deleteEntry(int entryId) async {
    // DEMO : rien ne s'ecrit (tache 634, DEM-260929-1123). Christophe :
    // « ON EST EN MODE DEMO » = rien ne compte, « rien en base ».
    if (ref.read(enDemoProvider)) return;
    await _repo.deleteEntry(entryId);
    await _loadEntries();
  }

  /// Verifie si on peut encore ajouter une photo aujourd'hui.
  Future<bool> canAddPhotoToday() async {
    return _photoService.canAddPhoto(_trailId);
  }

  /// Force le rechargement complet des entrees.
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true);
    await _loadEntries();
  }
}

/// Provider principal du journal ecran — pilote JournalScreen.
///
/// Usage dans le build du widget :
/// ```dart
/// final isLoading = ref.watch(
///   journalScreenProvider.select((s) => s.isLoading),
/// );
/// ```
final journalScreenProvider =
    NotifierProvider<JournalScreenNotifier, JournalScreenState>(
      JournalScreenNotifier.new,
    );

/// Nombre d'etapes REELLES du sentier, pour le selecteur d'etape du journal
/// (R10, LOT L10).
///
/// Remplace le `16` EN DUR du menu deroulant « Etape » : 16 est le compte du
/// GR20, alors que les sentiers StepWays en ont 7, 12 ou 5. Sur un sentier a
/// 7 etapes, l'utilisateur pouvait rattacher une note aux etapes 8 a 16, qui
/// n'existent pas — le moteur cessait d'etre generique.
///
/// Source de verite : les etapes reellement chargees du sentier
/// ([stagesProvider]). Repli sur `TrailConfig.totalStages` tant que la base n'a
/// pas repondu (ou si aucune etape n'est seedee), et PLANCHER A 1 pour ne
/// jamais rendre un menu deroulant vide (un `DropdownButtonFormField` sans item
/// mais avec une valeur initiale leve une assertion Flutter).
final journalStageCountProvider = Provider.family<int, String>((ref, trailId) {
  final loaded = ref
      .watch(stagesProvider(trailId))
      .maybeWhen(data: (stages) => stages.length, orElse: () => 0);
  if (loaded > 0) return loaded;
  final declared = ref.watch(trailConfigProvider.select((c) => c.totalStages));
  return declared > 0 ? declared : 1;
});
