import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/daos/nuitee_selections_dao.dart';
import '../../../core/data/database.dart';
import '../../../core/engine/trail_engine.dart';
import '../../../core/providers/database_provider.dart';
import '../../trail/providers/trail_providers.dart';
import '../../trek/domain/models/stage_accommodation.dart';
import '../domain/models/nuitee_type.dart';

/// Hebergements d'une etape pour un sentier donne (reutilise le module booking :
/// [StageAccommodation] + [trailDataProvider] -> base Drift seedee par sentier).
///
/// Parametre par (trailId, stageNumber) pour rester generique multi-sentiers,
/// sans dependre d'un provider d'etat courant. Retourne une liste vide si le
/// sentier n'a pas de donnees d'hebergement (fallback gracieux).
final nuiteeStageAccommodationsProvider = FutureProvider.family<
    List<StageAccommodation>, ({String trailId, int stageNumber})>(
  (ref, key) async {
    if (key.trailId.isEmpty) return const [];
    final dataProvider = ref.watch(trailDataProvider);
    return dataProvider.getAccommodations(
      key.trailId,
      stageNumber: key.stageNumber,
    );
  },
);

/// Etat des nuitees du PROGRAMME (PARITE GR20 `BookingData`).
///
/// Deux maps indexees par numero de jour (dayNumber, 0 = N0) :
///  - [bookings] : nuit reservee (true) ou a reserver (false) ;
///  - [nuiteeTypes] : type de nuitee choisi (refuge par defaut).
class NuiteeSelectionsState {
  const NuiteeSelectionsState({
    required this.bookings,
    required this.nuiteeTypes,
  });

  final Map<int, bool> bookings;
  final Map<int, NuiteeType> nuiteeTypes;

  /// Etat vide (avant chargement DB).
  static const empty = NuiteeSelectionsState(bookings: {}, nuiteeTypes: {});

  /// Nombre de nuits marquees reservees (parite GR20 `bookedCount`).
  int get bookedCount => bookings.values.where((v) => v).length;

  /// Etat reserve d'une nuit (defaut : a reserver).
  bool isBooked(int dayNumber) => bookings[dayNumber] ?? false;

  /// Type choisi pour une nuit (defaut : refuge, comme GR20).
  NuiteeType typeFor(int dayNumber) =>
      nuiteeTypes[dayNumber] ?? NuiteeType.refuge;

  NuiteeSelectionsState copyWith({
    Map<int, bool>? bookings,
    Map<int, NuiteeType>? nuiteeTypes,
  }) {
    return NuiteeSelectionsState(
      bookings: bookings ?? this.bookings,
      nuiteeTypes: nuiteeTypes ?? this.nuiteeTypes,
    );
  }
}

/// Provider de l'etat des nuitees pour le sentier actif (parite GR20
/// `refugeBookingStateProvider`), avec persistance LOCALE (Drift).
///
/// Clone fonctionnel de l'assistant GR20 mais sans Firebase : l'etat par nuit
/// (type + reserve) est charge et sauvegarde dans la table nuitee_selections
/// via [NuiteeSelectionsDao] (offline-first, meme strategie que la checklist).
final nuiteeSelectionsProvider =
    NotifierProvider<NuiteeSelectionsNotifier, NuiteeSelectionsState>(
  NuiteeSelectionsNotifier.new,
);

/// Notifier de l'etat des nuitees (charge/sauvegarde en Drift, par sentier).
class NuiteeSelectionsNotifier extends Notifier<NuiteeSelectionsState> {
  @override
  NuiteeSelectionsState build() {
    _db = ref.read(databaseProvider);
    _trailId = ref.read(trailIdProvider);
    _load();
    return NuiteeSelectionsState.empty;
  }

  late AppDatabase _db;
  late String _trailId;

  NuiteeSelectionsDao get _dao => NuiteeSelectionsDao(_db);

  /// Charge l'etat persiste depuis la DB (par sentier).
  Future<void> _load() async {
    final rows = await _dao.getByTrailId(_trailId);
    final bookings = <int, bool>{};
    final types = <int, NuiteeType>{};
    for (final row in rows) {
      bookings[row.dayNumber] = row.isBooked;
      types[row.dayNumber] = NuiteeTypeUi.fromStorage(row.nuiteeType);
    }
    state = NuiteeSelectionsState(bookings: bookings, nuiteeTypes: types);
  }

  /// Bascule l'etat reserve d'une nuit et persiste (parite GR20 `toggleBooking`).
  Future<void> toggleBooking(int dayNumber) async {
    final next = !state.isBooked(dayNumber);
    state = state.copyWith(
      bookings: {...state.bookings, dayNumber: next},
    );
    await _dao.setBooked(_trailId, dayNumber, next);
  }

  /// Definit le type de nuitee d'une nuit et persiste (parite GR20
  /// `setNuiteeType`).
  Future<void> setNuiteeType(int dayNumber, NuiteeType type) async {
    state = state.copyWith(
      nuiteeTypes: {...state.nuiteeTypes, dayNumber: type},
    );
    await _dao.setType(_trailId, dayNumber, type.storageKey);
  }
}
