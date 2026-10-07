// Test miroir de `lib/features/trek/data/podometre_permission_service.dart`
// (lot 671-02) : le statut nomme et ses lectures tolerantes. Les deux chemins
// de l'autorisation sont prouves dans
// `test/comportement/permission_activite_physique_671_test.dart`.
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/trek/data/podometre_permission_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('chaque statut du systeme a son etat nomme', () {
    expect(
      podometerAccessOf(PermissionStatus.granted),
      PodometerAccess.granted,
    );
    expect(
      podometerAccessOf(PermissionStatus.limited),
      PodometerAccess.granted,
    );
    expect(
      podometerAccessOf(PermissionStatus.provisional),
      PodometerAccess.granted,
    );
    expect(podometerAccessOf(PermissionStatus.denied), PodometerAccess.denied);
    expect(
      podometerAccessOf(PermissionStatus.permanentlyDenied),
      PodometerAccess.permanentlyDenied,
    );
    expect(
      podometerAccessOf(PermissionStatus.restricted),
      PodometerAccess.unavailable,
    );
  });

  test('un statut illisible vaut indisponible, sans lever', () async {
    final service = PodometerPermissionService(
      readStatus: () async => throw StateError('pas de canal'),
    );
    expect(await service.status(), PodometerAccess.unavailable);
  });

  test('un refus au systeme rend refuse, ou refuse definitivement', () async {
    var statut = PermissionStatus.denied;
    final service = PodometerPermissionService(
      readStatus: () async => statut,
      request: () async {
        statut = PermissionStatus.permanentlyDenied;
        return false;
      },
    );
    expect(await service.request(), PodometerAccess.permanentlyDenied);
  });

  test('une demande qui leve ne casse rien : refusee', () async {
    final service = PodometerPermissionService(
      readStatus: () async => PermissionStatus.denied,
      request: () async => throw StateError('deja en cours'),
    );
    expect(await service.request(), PodometerAccess.denied);
  });

  test('le refus retenu est faux au depart, vrai une fois note', () async {
    final service = PodometerPermissionService();
    expect(await service.hasDeclined(), isFalse);
    await service.rememberDeclined();
    expect(await service.hasDeclined(), isTrue);
  });

  test('ouvrir les reglages du systeme ne leve jamais', () async {
    final service = PodometerPermissionService(
      openSettings: () async => throw StateError('pas de canal'),
    );
    expect(await service.openSystemSettings(), isFalse);
  });
}
