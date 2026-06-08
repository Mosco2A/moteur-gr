import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moteur_gr/core/ui/app_haptics.dart';

/// Tests E5.5a — micro-interactions haptiques.
///
/// Capture les appels sur le canal plateforme pour verifier que chaque
/// niveau d'intensite declenche bien le HapticFeedback attendu.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final calls = <MethodCall>[];

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      calls.add(call);
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('heavy() declenche HapticFeedback heavyImpact', () async {
    await AppHaptics.heavy();
    expect(calls, hasLength(1));
    expect(calls.single.method, 'HapticFeedback.vibrate');
    expect(calls.single.arguments, 'HapticFeedbackType.heavyImpact');
  });

  test('medium() declenche HapticFeedback mediumImpact', () async {
    await AppHaptics.medium();
    expect(calls.single.arguments, 'HapticFeedbackType.mediumImpact');
  });

  test('light() declenche HapticFeedback lightImpact', () async {
    await AppHaptics.light();
    expect(calls.single.arguments, 'HapticFeedbackType.lightImpact');
  });
}
