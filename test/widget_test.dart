import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:littlehands_gpt/models/activity.dart';
import 'package:littlehands_gpt/models/learning_content.dart';
import 'package:littlehands_gpt/screens/activities/drag_match_screen.dart';
import 'package:littlehands_gpt/screens/learn/abc_screen.dart';
import 'package:littlehands_gpt/screens/learn/color_screen.dart';
import 'package:littlehands_gpt/screens/learn/story_screen.dart';
import 'package:littlehands_gpt/services/content_engine.dart';
import 'package:littlehands_gpt/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // flutter_tts talks to a platform channel; stub it out in tests.
  setUp(() {
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
    expect(c.colors.length, greaterThanOrEqualTo(4));
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

  testWidgets('ABC tile selects its letter', (tester) async {
    final letters = [
      AbcEntry(letter: 'A', word: 'Apple', emoji: '🍎'),
      AbcEntry(letter: 'B', word: 'Ball', emoji: '⚽'),
    ];
    await tester.pumpWidget(MaterialApp(home: AbcScreen(letters: letters)));
    await tester.tap(find.byKey(const ValueKey('abc_B')));
    await tester.pump();
    expect(find.text('Bb'), findsOneWidget);
    expect(find.text('Ball'), findsOneWidget);
  });

  testWidgets('Color game: right colour earns one star, wrong does not',
      (tester) async {
    final colors = [
      ColorEntry(name: 'Red', argb: 0xFFFF0000, fact: 'red fact'),
      ColorEntry(name: 'Blue', argb: 0xFF0000FF, fact: 'blue fact'),
    ];
    await tester.pumpWidget(MaterialApp(home: ColorGameScreen(colors: colors)));
    final prompt =
        tester.widget<Text>(find.byKey(const ValueKey('color_prompt'))).data!;
    final target = prompt.contains('Red') ? 'Red' : 'Blue';
    final wrong = target == 'Red' ? 'Blue' : 'Red';

    await tester.tap(find.byKey(ValueKey('color_$wrong')));
    await tester.pump();
    expect(find.text('0'), findsOneWidget);

    await tester.tap(find.byKey(ValueKey('color_$target')));
    await tester.pump();
    // Extra taps during the celebration must not add stars.
    await tester.tap(find.byKey(ValueKey('color_$target')));
    await tester.pump();
    expect(find.text('1'), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}
