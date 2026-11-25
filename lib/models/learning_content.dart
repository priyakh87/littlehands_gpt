import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Stories, alphabet and colours bundled in assets/data/learning.json.
/// Fully offline — editing that JSON file changes the content, no code needed.
class LearningContent {
  final List<Story> stories;
  final List<AbcEntry> abc;
  final List<ColorEntry> colors;
  final List<ColorLevel> colorLevels;
  final List<AbcLevel> abcLevels;

  LearningContent({
    required this.stories,
    required this.abc,
    required this.colors,
    required this.colorLevels,
    required this.abcLevels,
  });

  ColorEntry color(String name) => colors.firstWhere((c) => c.name == name);

  static LearningContent? _cache;

  static Future<LearningContent> load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString('assets/data/learning.json');
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _cache = LearningContent(
      stories: (json['stories'] as List)
          .map((s) => Story.fromJson(s as Map<String, dynamic>))
          .toList(),
      abc: (json['abc'] as List)
          .map((a) => AbcEntry.fromJson(a as Map<String, dynamic>))
          .toList(),
      colors: (json['colors'] as List)
          .map((c) => ColorEntry.fromJson(c as Map<String, dynamic>))
          .toList(),
      colorLevels: (json['color_levels'] as List)
          .map((l) => ColorLevel.fromJson(l as Map<String, dynamic>))
          .toList(),
      abcLevels: (json['abc_levels'] as List)
          .map((l) => AbcLevel.fromJson(l as Map<String, dynamic>))
          .toList(),
    );
    return _cache!;
  }
}

class Story {
  final String id;
  final String title;
  final String emoji;
  final List<String> pages;

  Story({
    required this.id,
    required this.title,
    required this.emoji,
    required this.pages,
  });

  factory Story.fromJson(Map<String, dynamic> json) => Story(
        id: json['id'] as String,
        title: json['title'] as String,
        emoji: json['emoji'] as String,
        pages: (json['pages'] as List).cast<String>(),
      );
}

class AbcEntry {
  final String letter;
  final String word;
  final String emoji;

  AbcEntry({required this.letter, required this.word, required this.emoji});

  factory AbcEntry.fromJson(Map<String, dynamic> json) => AbcEntry(
        letter: json['letter'] as String,
        word: json['word'] as String,
        emoji: json['emoji'] as String,
      );
}

class ColorEntry {
  final String name;
  final int argb;
  final String fact;

  ColorEntry({required this.name, required this.argb, required this.fact});

  factory ColorEntry.fromJson(Map<String, dynamic> json) => ColorEntry(
        name: json['name'] as String,
        argb: 0xFF000000 |
            int.parse((json['hex'] as String).replaceFirst('#', ''), radix: 16),
        fact: json['fact'] as String,
      );
}

/// One Color Game level. mode is 'color' ("Find red!") or 'shape_color'
/// ("Find the red star!").
class ColorLevel {
  final int level;
  final String title;
  final String emoji;
  final String mode;
  final List<String> colors;
  final List<String> shapes;
  final int choices;
  final int rounds;

  ColorLevel({
    required this.level,
    required this.title,
    required this.emoji,
    required this.mode,
    required this.colors,
    required this.shapes,
    required this.choices,
    required this.rounds,
  });

  bool get usesShapes => mode == 'shape_color';

  factory ColorLevel.fromJson(Map<String, dynamic> json) => ColorLevel(
        level: json['level'] as int,
        title: json['title'] as String,
        emoji: json['emoji'] as String,
        mode: json['mode'] as String,
        colors: (json['colors'] as List).cast<String>(),
        shapes: ((json['shapes'] as List?) ?? const ['circle']).cast<String>(),
        choices: json['choices'] as int,
        rounds: json['rounds'] as int,
      );
}

/// One ABC level. mode is 'explore' (tap every letter from..to) or
/// 'quiz' ("Find the letter B!").
class AbcLevel {
  final int level;
  final String title;
  final String emoji;
  final String mode;
  final String from;
  final String to;
  final int choices;
  final int rounds;

  AbcLevel({
    required this.level,
    required this.title,
    required this.emoji,
    required this.mode,
    required this.from,
    required this.to,
    required this.choices,
    required this.rounds,
  });

  bool get isQuiz => mode == 'quiz';

  factory AbcLevel.fromJson(Map<String, dynamic> json) => AbcLevel(
        level: json['level'] as int,
        title: json['title'] as String,
        emoji: json['emoji'] as String,
        mode: json['mode'] as String,
        from: (json['from'] as String?) ?? 'A',
        to: (json['to'] as String?) ?? 'Z',
        choices: (json['choices'] as int?) ?? 4,
        rounds: (json['rounds'] as int?) ?? 6,
      );
}
