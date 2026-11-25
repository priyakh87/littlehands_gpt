import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

/// Stories, alphabet and colours bundled in assets/data/learning.json.
/// Fully offline — editing that JSON file changes the content, no code needed.
class LearningContent {
  final List<Story> stories;
  final List<AbcEntry> abc;
  final List<ColorEntry> colors;

  LearningContent({
    required this.stories,
    required this.abc,
    required this.colors,
  });

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
