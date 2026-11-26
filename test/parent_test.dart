import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:littlehands_gpt/main.dart';
import 'package:littlehands_gpt/models/child_profile.dart';
import 'package:littlehands_gpt/screens/parent/parent_gate.dart';
import 'package:littlehands_gpt/screens/time_up_screen.dart';
import 'package:littlehands_gpt/services/parent_lock.dart';
import 'package:littlehands_gpt/services/play_time_service.dart';
import 'package:littlehands_gpt/services/profile_service.dart';
import 'package:littlehands_gpt/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _mia = ChildProfile(id: 'mia', name: 'Mia', avatar: '🐰', age: 3);
const _sam = ChildProfile(id: 'sam', name: 'Sam', avatar: '🦁', age: 5);

Future<void> enterPin(WidgetTester tester, String pin) async {
  for (final d in pin.split('')) {
    await tester.tap(find.byKey(ValueKey('pin_key_$d')));
    await tester.pump();
  }
  await tester.pump();
  await tester.pump();
}

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProfileService.resetForTest();
    PlayTimeService.instance.timeUp.value = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
  });

  test('First child inherits old stars; each child has their own', () async {
    SharedPreferences.setMockInitialValues({'stars:colors:1': 2});
    await ProfileService.save(_mia);
    expect(ProfileService.active.value?.id, 'mia');
    expect(await ProgressService.stars('colors', 1), 2);

    await ProfileService.save(_sam);
    expect(ProfileService.active.value?.id, 'mia', reason: 'still Mia');
    await ProfileService.setActive('sam');
    expect(await ProgressService.stars('colors', 1), 0);
    await ProgressService.saveStars('colors', 1, 3);
    expect(await ProgressService.totalStars(), 3);

    await ProfileService.setActive('mia');
    expect(await ProgressService.totalStars(), 2);

    await ProfileService.delete('sam');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().where((k) => k.contains('sam')), isEmpty);

    // Profiles survive a restart.
    ProfileService.resetForTest();
    await ProfileService.load();
    expect(ProfileService.profiles.map((p) => p.name), ['Mia']);
    expect(ProfileService.active.value?.name, 'Mia');
  });

  test('Parent PIN is stored hashed and verified', () async {
    expect(await ParentLock.hasPin(), isFalse);
    await ParentLock.setPin('2468');
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys().any((k) => prefs.get(k) == '2468'), isFalse);
    expect(await ParentLock.verify('2468'), isTrue);
    expect(await ParentLock.verify('1111'), isFalse);
  });

  test('Daily limit raises time-up; extra minutes clear it', () async {
    await ProfileService.save(_mia.copyWith(dailyLimitMinutes: 1));
    final timer = PlayTimeService.instance;
    await timer.check();
    expect(timer.timeUp.value, isFalse);
    await timer.tick(50);
    expect(timer.timeUp.value, isFalse);
    await timer.tick(10);
    expect(timer.timeUp.value, isTrue);
    await timer.tick(30); // no counting while time is up
    expect(await timer.playedSecondsToday(ProfileService.active.value!), 60);

    await timer.grantExtra(15);
    expect(timer.timeUp.value, isFalse);

    // Paused (parent area open): time is not counted.
    timer.pause();
    await timer.tick(10000);
    timer.resume();
    expect(timer.timeUp.value, isFalse);

    // No limit: never time up.
    await ProfileService.save(_mia.copyWith(dailyLimitMinutes: 0));
    await timer.tick(100000);
    expect(timer.timeUp.value, isFalse);
  });

  testWidgets('Parent gate: create, verify, wrong PIN and forgot PIN',
      (tester) async {
    bool? result;
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async => result = await showParentGate(context),
          child: const Text('open'),
        ),
      ),
    ));

    // First time: create + confirm.
    await tester.tap(find.text('open'));
    await settle(tester);
    expect(find.text('Create a parent PIN'), findsOneWidget);
    await enterPin(tester, '1234');
    expect(find.text('Enter the PIN again'), findsOneWidget);
    await enterPin(tester, '1234');
    await settle(tester);
    expect(result, isTrue);
    expect(await ParentLock.verify('1234'), isTrue);

    // Next time: verify; a wrong PIN is refused.
    result = null;
    await tester.tap(find.text('open'));
    await settle(tester);
    expect(find.text('Grown-ups only'), findsOneWidget);
    await enterPin(tester, '9999');
    expect(find.text('Wrong PIN. Try again.'), findsOneWidget);

    // Forgot PIN: answer the grown-up question, then set a new PIN.
    await tester.ensureVisible(find.byKey(const ValueKey('forgot_pin')));
    await tester.tap(find.byKey(const ValueKey('forgot_pin')));
    await tester.pump();
    final question = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => t.data ?? '')
        .firstWhere((t) => t.startsWith('What is'));
    final nums = RegExp(r'\d+').allMatches(question).map((m) => m[0]!);
    final answer = nums.map(int.parse).reduce((a, b) => a * b).toString();
    await enterPin(tester, answer);
    expect(find.text('Create a parent PIN'), findsOneWidget);
    await enterPin(tester, '5678');
    await enterPin(tester, '5678');
    await settle(tester);
    expect(result, isTrue);
    expect(await ParentLock.verify('5678'), isTrue);

    // Closing the gate returns false.
    await tester.tap(find.text('open'));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('gate_close')));
    await settle(tester);
    expect(result, isFalse);
  });

  testWidgets('First run: set PIN, add child, then home shows the child',
      (tester) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const MyApp());
    await settle(tester);
    expect(find.text('Welcome to LittleHands'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('welcome_start')));
    await settle(tester);
    await enterPin(tester, '1357');
    await enterPin(tester, '1357');
    await settle(tester);

    expect(find.text('Add a child'), findsWidgets);
    await tester.enterText(find.byKey(const ValueKey('profile_name')), 'Zara');
    await tester.tap(find.byKey(const ValueKey('avatar_🦄')));
    await tester.tap(find.byKey(const ValueKey('age_4')));
    await tester.pump();
    await tester.ensureVisible(find.byKey(const ValueKey('profile_save')));
    await tester.tap(find.byKey(const ValueKey('profile_save')));
    await settle(tester);

    expect(find.text('Zara'), findsOneWidget);
    expect(find.text('Matching Game'), findsOneWidget);
    expect(ProfileService.active.value?.age, 4);
    expect(ProfileService.active.value?.avatar, '🦄');
  });

  testWidgets('Time-up screen covers the app; PIN unlocks extra time',
      (tester) async {
    await ParentLock.setPin('1111');
    await ProfileService.save(_mia.copyWith(dailyLimitMinutes: 1));
    await PlayTimeService.instance.tick(60);
    expect(PlayTimeService.instance.timeUp.value, isTrue);

    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => TimeUpOverlay(child: child!),
      home: const Scaffold(body: Text('activity')),
    ));
    await tester.pump();
    expect(find.text('Time for a break, Mia!'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('time_up_grownups')));
    await tester.pump();
    await enterPin(tester, '0000');
    expect(find.text('Wrong PIN. Try again.'), findsOneWidget);
    await enterPin(tester, '1111');
    await tester.pump();
    await tester.tap(find.byKey(const ValueKey('extra_15')));
    await tester.pump();
    await tester.pump();
    expect(find.byKey(const ValueKey('time_up')), findsNothing);
    expect(find.text('activity'), findsOneWidget);
  });
}
