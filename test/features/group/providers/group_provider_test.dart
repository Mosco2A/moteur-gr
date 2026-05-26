import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/features/group/providers/group_provider.dart';

void main() {
  group('groupCodeProvider', () {
    test('initiale null', () {
      final c = ProviderContainer(); addTearDown(c.dispose);
      expect(c.read(groupCodeProvider), isNull);
    });
    test('mise a jour', () {
      final c = ProviderContainer(); addTearDown(c.dispose);
      c.read(groupCodeProvider.notifier).state = 'ABC123';
      expect(c.read(groupCodeProvider), 'ABC123');
    });
    test('remise a null', () {
      final c = ProviderContainer(); addTearDown(c.dispose);
      c.read(groupCodeProvider.notifier).state = 'ABC123';
      c.read(groupCodeProvider.notifier).state = null;
      expect(c.read(groupCodeProvider), isNull);
    });
  });
  group('isGroupActiveProvider', () {
    test('false sans code', () {
      final c = ProviderContainer(); addTearDown(c.dispose);
      expect(c.read(isGroupActiveProvider), isFalse);
    });
    test('true avec code', () {
      final c = ProviderContainer(); addTearDown(c.dispose);
      c.read(groupCodeProvider.notifier).state = 'XYZ789';
      expect(c.read(isGroupActiveProvider), isTrue);
    });
  });
  group('watcherCountProvider', () {
    test('0 sans groupe', () {
      final c = ProviderContainer(); addTearDown(c.dispose);
      expect(c.read(watcherCountProvider), 0);
    });
  });
}
