import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:littlehands_gpt/models/activity.dart';
import 'package:littlehands_gpt/models/learning_content.dart';
import 'package:littlehands_gpt/screens/activities/drag_match_screen.dart';
import 'package:littlehands_gpt/screens/learn/abc_screen.dart';
import 'package:littlehands_gpt/screens/learn/color_screen.dart';
import 'package:littlehands_gpt/screens/learn/story_screen.dart';
import 'package:littlehands_gpt/screens/levels_screen.dart';
import 'package:littlehands_gpt/services/content_engine.dart';
import 'package:littlehands_gpt/services/progress_service.dart';
import 'package:littlehands_gpt/services/tts_service.dart';
import 'package:littlehands_gpt/widgets/shape_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // flutter_tts talks to a platform channel; stub it out in tests.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
            const MethodChannel('flutter_tts'), (call) async => 1);
  });

  test('ContentEngine loads bundled activities from the manifest', () async {
    final all = await ContentEngine().loadAll();
    expect(all, isNotEmpty);
    final match = all.firstWhere((a) => a.id == 'animals_match');
    expect(match.type, 'drag_match');
    expect(match.items.map((i) => i.id), containsAll(['lion', 'cow', 'duck']));
    for (final item in match.items) {
      // Every referenced image must exist in the bundle.
      await rootBundle.load(item.imageAsset);
    }
  });

  test('loadForAge filters by age range', () async {
    expect(await ContentEngine().loadForAge(3), isNotEmpty);
    expect(await ContentEngine().loadForAge(9), isEmpty);
  });

  testWidgets('DragMatch awards 3 stars when every match is first try',
      (tester) async {
    final activity = Activity(
      id: 't',
      type: 'drag_match',
      titleEn: 'Test',
      titleAr: 'اختبار',
      minAge: 2,
      maxAge: 5,
      items: [
        for (final id in ['lion', 'cow'])
          ActivityItem(
            id: id,
            imageAsset: 'assets/animals/$id.jpeg',
            labelEn: id,
            labelAr: id,
            matchTargetId: id,
          ),
      ],
    );
    int? stars;
    await tester.pumpWidget(MaterialApp(
      home: DragMatchScreen(
        activity: activity,
        languageCode: 'en',
        speed: NarrationSpeed.normal,
        onComplete: (s) => stars = s,
      ),
    ));

    for (final id in ['lion', 'cow']) {
      final from = tester.getCenter(find.byKey(ValueKey('piece_$id')));
      final to = tester.getCenter(find.byKey(ValueKey('target_$id')));
      final gesture = await tester.startGesture(from);
      await gesture.moveBy(const Offset(0, -20));
      await gesture.moveTo(to);
      await gesture.up();
      await tester.pump();
    }
    await tester.pump(const Duration(seconds: 1));
    expect(stars, 3);
  });

  test('LearningContent loads stories, 26 letters and colours', () async {
    final c = await LearningContent.load();
    expect(c.stories, isNotEmpty);
    expect(c.abc.map((a) => a.letter).join(), 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
    expect(c.colors.length, greaterThanOrEqualTo(10));
    expect(c.colorLevels.map((l) => l.level), [1, 2, 3]);
    expect(c.abcLevels.map((l) => l.level), [1, 2, 3]);
    for (final l in c.colorLevels) {
      l.colors.forEach(c.color); // every colour name must exist
    }
  });

  testWidgets('Story reader pages forward', (tester) async {
    final story = Story(
        id: 's', title: 'T', emoji: '🐰', pages: ['Page one', 'Page two']);
    await tester.pumpWidget(MaterialApp(home: StoryReaderScreen(story: story)));
    expect(find.text('Page one'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('story_next')));
    await tester.pump();
    expect(find.text('Page two'), findsOneWidget);
    expect(find.text('2 / 2'), findsOneWidget);
  });

  testWidgets('ABC explore level completes after every letter is tapped',
      (tester) async {
    final letters = [
      AbcEntry(letter: 'A', word: 'Apple', emoji: '🍎'),
      AbcEntry(letter: 'B', word: 'Ball', emoji: '⚽'),
    ];
    int? stars;
    await tester.pumpWidget(MaterialApp(
        home: AbcExploreScreen(
            title: 'T', letters: letters, onComplete: (s) => stars = s)));
    await tester.tap(find.byKey(const ValueKey('abc_B')));
    await tester.pump();
    expect(find.text('Bb'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('abc_A')));
    await tester.pump(const Duration(seconds: 3));
    expect(stars, 3);
  });

  testWidgets('Color level: one mistake gives 2 stars after all rounds',
      (tester) async {
    final content = await LearningContent.load();
    final level = ColorLevel(
        level: 1,
        title: 'T',
        emoji: '🔴',
        mode: 'color',
        colors: ['Red', 'Blue'],
        shapes: ['circle'],
        choices: 2,
        rounds: 2);
    int? stars;
    await tester.pumpWidget(MaterialApp(
        home: ColorLevelScreen(
            level: level, content: content, onComplete: (s) => stars = s)));

    String target() {
      final p =
          tester.widget<Text>(find.byKey(const ValueKey('color_prompt'))).data!;
      return p.contains('Red') ? 'Red' : 'Blue';
    }

    final wrong = target() == 'Red' ? 'Blue' : 'Red';
    await tester.tap(find.byKey(ValueKey('choice_${wrong}_circle')));
    await tester.pump();
    for (var round = 0; round < 2; round++) {
      await tester.tap(find.byKey(ValueKey('choice_${target()}_circle')));
      await tester.pump();
      // Extra taps during the feedback must not count.
      await tester.tap(find.byKey(ValueKey('choice_${target()}_circle')));
      await tester.pump(const Duration(seconds: 4));
    }
    expect(stars, 2);
  });

  testWidgets('Shapes level always offers the target among 6 choices',
      (tester) async {
    final content = await LearningContent.load();
    final level = content.colorLevels.firstWhere((l) => l.usesShapes);
    tester.view.physicalSize = const Size(1206, 2622); // iPhone-sized
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    int? stars;
    await tester.pumpWidget(MaterialApp(
        home: ColorLevelScreen(
            level: level,
            content: content,
            random: Random(7),
            onComplete: (s) => stars = s)));
    for (var round = 0; round < level.rounds; round++) {
      final prompt =
          tester.widget<Text>(find.byKey(const ValueKey('color_prompt'))).data!;
      // "Find the Red star!" -> Red_star
      final parts = prompt.replaceAll('!', '').split(' ');
      final key = '${parts[2]}_${parts[3]}';
      expect(find.byKey(ValueKey('choice_$key')), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is ShapeView), findsNWidgets(6));
      await tester.tap(find.byKey(ValueKey('choice_$key')));
      await tester.pump(const Duration(seconds: 3));
    }
    expect(stars, 3);
  });

  test('Progress keeps best stars and unlocks the next level', () async {
    await ProgressService.saveStars('t', 1, 2);
    await ProgressService.saveStars('t', 1, 1); // lower score is ignored
    final stars = await ProgressService.starsForLevels('t', 3);
    expect(stars, [2, 0, 0]);
    expect(ProgressService.isUnlocked(stars, 0), isTrue);
    expect(ProgressService.isUnlocked(stars, 1), isTrue);
    expect(ProgressService.isUnlocked(stars, 2), isFalse);
    expect(await ProgressService.totalStars(), 2);
    expect(ProgressService.starsForMistakes(0), 3);
    expect(ProgressService.starsForMistakes(2), 2);
    expect(ProgressService.starsForMistakes(5), 1);
  });

  test('Matching game has three levels with existing images', () async {
    final all = await ContentEngine().loadAll();
    final levels = all.where((a) => a.type == 'drag_match').map((a) => a.level);
    expect(levels.toSet(), {1, 2, 3});
    for (final a in all) {
      for (final item in a.items) {
        await rootBundle.load(item.imageAsset);
      }
    }
  });

  testWidgets('Finishing a level celebrates and Next opens the next level',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: LevelsScreen(
        activityKey: 'demo',
        title: 'Demo',
        levels: const [
          LevelInfo(title: 'One', emoji: '1️⃣'),
          LevelInfo(title: 'Two', emoji: '2️⃣'),
        ],
        buildLevel: (_, i, onComplete) => Scaffold(
          body: Center(
            child: ElevatedButton(
              key: ValueKey('finish_$i'),
              onPressed: () => onComplete(3),
              child: Text('Playing level ${i + 1}'),
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    // Level 2 is locked until level 1 is done.
    await tester.tap(find.byKey(const ValueKey('level_2')));
    await settle(tester);
    expect(find.text('Playing level 2'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('level_1')));
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('finish_0')));
    await settle(tester);
    expect(find.byKey(const ValueKey('celebration')), findsOneWidget);
    expect(find.text('Level 1 complete!'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('celebration_next')));
    await settle(tester);
    expect(find.text('Playing level 2'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('finish_1')));
    await settle(tester);
    // Last level: no Next button, only Again / Done.
    expect(find.byKey(const ValueKey('celebration_next')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('celebration_exit')));
    await settle(tester);
    expect(await ProgressService.starsForLevels('demo', 2), [3, 3]);
  });
}

/// Pumps several frames so page and dialog transitions finish (a single
/// long pump leaves a just-pushed route offstage). Can't use
/// pumpAndSettle because the celebration confetti animates forever.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 15; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}
