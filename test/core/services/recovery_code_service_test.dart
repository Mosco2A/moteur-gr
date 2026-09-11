import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/services/recovery_code_service.dart';

/// Tests du service de CODE DE RECONNEXION (modèle code-sur-tel, #99784).
///
/// Le code doit être : généré une seule fois, STABLE (même code à chaque appel),
/// persisté dans le keystore, lisible sans création via [peek], et lisible à la
/// main (pas de caractères ambigus).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('getOrCreate génère un code au 1er appel puis le renvoie STABLE', () async {
    final service = RecoveryCodeService();
    final first = await service.getOrCreate();
    expect(first, isNotEmpty);
    // Idempotent : le même code est renvoyé (c'est la clé du coffre).
    final second = await service.getOrCreate();
    expect(second, first);
  });

  test('peek renvoie null tant que le code n\'a jamais été créé', () async {
    final service = RecoveryCodeService();
    expect(await service.peek(), isNull);
    final created = await service.getOrCreate();
    expect(await service.peek(), created);
  });

  test('le code a le format lisible XXXX-XXXX-XXXX-XXXX, sans caractères ambigus',
      () async {
    final service = RecoveryCodeService();
    final code = await service.getOrCreate();
    // 4 groupes de 4 séparés par des tirets.
    expect(RegExp(r'^[A-Z0-9]{4}(-[A-Z0-9]{4}){3}$').hasMatch(code), isTrue);
    // Aucun caractère ambigu (0/O/1/I/L) — recopie manuelle fiable.
    for (final ambiguous in ['0', 'O', '1', 'I', 'L']) {
      expect(code.contains(ambiguous), isFalse,
          reason: 'le code ne doit pas contenir « $ambiguous »');
    }
  });

  test('persistance : un nouveau service lit le code déjà stocké', () async {
    final a = RecoveryCodeService();
    final code = await a.getOrCreate();
    // Un autre service sur le MÊME keystore (mock partagé) voit le même code.
    final b = RecoveryCodeService();
    expect(await b.peek(), code);
    expect(await b.getOrCreate(), code);
  });
}
