import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:littlehands_gpt/models/learning_content.dart';
import 'package:littlehands_gpt/screens/learn/story_screen.dart';
import 'package:littlehands_gpt/screens/levels_screen.dart';
import 'package:littlehands_gpt/screens/parent/paywall_screen.dart';
import 'package:littlehands_gpt/services/access_policy.dart';
import 'package:littlehands_gpt/services/profile_service.dart';
import 'package:littlehands_gpt/services/subscription_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fake_subscriptions.dart';

Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Widget levelsApp() => MaterialApp(
      home: LevelsScreen(
        activityKey: 'demo',
        title: 'Demo',
        levels: const [
          LevelInfo(title: 'One', emoji: '1️⃣'),
          LevelInfo(title: 'Two', emoji: '2️⃣'),
        ],
        buildLevel: (_, i, onComplete) => Scaffold(
          body: ElevatedButton(
            key: ValueKey('finish_$i'),
            onPressed: () => onComplete(3),
            child: Text('Playing level ${i + 1}'),
          ),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    ProfileService.resetForTest();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
  });

  test('Free plan: only level 1 and the first story', () async {
    await useFakeSubscriptions();
    expect(AccessPolicy.canPlayLevel(0), isTrue);
    expect(AccessPolicy.canPlayLevel(1), isFalse);
    expect(AccessPolicy.canReadStory(0), isTrue);
    expect(AccessPolicy.canReadStory(1), isFalse);

    await useFakeSubscriptions(premium: true);
    expect(AccessPolicy.canPlayLevel(2), isTrue);
    expect(AccessPolicy.canReadStory(1), isTrue);
  });

  testWidgets('Free child: premium level asks for a grown-up, no Next',
      (tester) async {
    await useFakeSubscriptions();
    await tester.pumpWidget(levelsApp());
    await settle(tester);
    expect(find.byKey(const ValueKey('premium_2')), findsOneWidget);

    // Finishing level 1 does not offer "Next" into a premium level.
    await tester.tap(find.byKey(const ValueKey('level_1')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('finish_0')));
    await settle(tester);
    expect(find.byKey(const ValueKey('celebration_next')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('celebration_exit')));
    await settle(tester);

    // Tapping the premium level goes to the parent gate, not the level.
    await tester.tap(find.byKey(const ValueKey('level_2')));
    await settle(tester);
    expect(find.text('Playing level 2'), findsNothing);
    expect(find.text('Create a parent PIN'), findsOneWidget);
  });

  testWidgets('Premium unlocks the level list immediately', (tester) async {
    final fake = await useFakeSubscriptions();
    await tester.pumpWidget(levelsApp());
    await settle(tester);
    expect(find.byKey(const ValueKey('premium_2')), findsOneWidget);

    fake.premium = true;
    await SubscriptionService.buy(fake.available.first);
    await settle(tester);
    expect(find.byKey(const ValueKey('premium_2')), findsNothing);
  });

  testWidgets('Paywall: yearly plan preselected, subscribe unlocks Premium',
      (tester) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final fake = await useFakeSubscriptions();

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PaywallScreen())),
          child: const Text('open'),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await settle(tester);
    expect(find.text('Unlock every level and story'), findsOneWidget);
    expect(find.text(r'$39.99 per year · 7-day free trial'), findsOneWidget);
    expect(find.text('Start free trial'), findsOneWidget);

    // Backing out of the store sheet changes nothing.
    fake.cancelNext = true;
    final boughtBefore = fake.bought;
    await tester.ensureVisible(find.byKey(const ValueKey('subscribe')));
    await tester.tap(find.byKey(const ValueKey('subscribe')));
    await settle(tester);
    expect(SubscriptionService.isPremium.value, isFalse);
    expect(fake.bought, boughtBefore);
    expect(find.text('Something went wrong. Try again.'), findsNothing);

    fake.cancelNext = false;
    await tester.ensureVisible(find.byKey(const ValueKey('subscribe')));
    await tester.tap(find.byKey(const ValueKey('subscribe')));
    await settle(tester);
    expect(fake.bought?.id, 'annual');
    expect(SubscriptionService.isPremium.value, isTrue);
    expect(find.text('open'), findsOneWidget, reason: 'paywall closed');
  });

  testWidgets('Restore with nothing to restore says so', (tester) async {
    tester.view.physicalSize = const Size(1206, 2622);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await useFakeSubscriptions();
    await tester.pumpWidget(const MaterialApp(home: PaywallScreen()));
    await settle(tester);
    await tester.ensureVisible(find.byKey(const ValueKey('restore')));
    await tester.tap(find.byKey(const ValueKey('restore')));
    await settle(tester);
    expect(
        find.text('No active Premium subscription was found.'), findsOneWidget);
  });

  testWidgets('Without RevenueCat keys the paywall explains, nothing breaks',
      (tester) async {
    SubscriptionService.useBackend(FakeSubscriptions(configured: false));
    await SubscriptionService.init();
    await tester.pumpWidget(const MaterialApp(home: PaywallScreen()));
    await settle(tester);
    expect(
        find.byKey(const ValueKey('paywall_not_configured')), findsOneWidget);
  });

  testWidgets('Story list: second story is Premium for free users',
      (tester) async {
    await useFakeSubscriptions();
    final stories = [
      Story(id: 'a', title: 'A', emoji: '🐰', pages: ['p']),
      Story(id: 'b', title: 'B', emoji: '🌙', pages: ['p']),
    ];
    await tester
        .pumpWidget(MaterialApp(home: StoryListScreen(stories: stories)));
    await settle(tester);
    expect(find.text('👑 Premium · ask a grown-up'), findsOneWidget);
  });
}
