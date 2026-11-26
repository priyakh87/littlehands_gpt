/// One child using the app. Stored on the device only.
class ChildProfile {
  final String id;
  final String name;
  final String avatar; // an emoji, e.g. '🐻'
  final int age;

  /// Daily play limit in minutes; 0 means no limit.
  final int dailyLimitMinutes;

  const ChildProfile({
    required this.id,
    required this.name,
    required this.avatar,
    required this.age,
    this.dailyLimitMinutes = 0,
  });

  static const avatars = [
    '🐻',
    '🐰',
    '🦁',
    '🐼',
    '🐸',
    '🦊',
    '🐯',
    '🐵',
    '🐨',
    '🦄',
    '🐶',
    '🐱'
  ];
  static const ages = [2, 3, 4, 5, 6];
  static const limitOptions = [0, 15, 30, 45, 60, 90];

  ChildProfile copyWith({
    String? name,
    String? avatar,
    int? age,
    int? dailyLimitMinutes,
  }) =>
      ChildProfile(
        id: id,
        name: name ?? this.name,
        avatar: avatar ?? this.avatar,
        age: age ?? this.age,
        dailyLimitMinutes: dailyLimitMinutes ?? this.dailyLimitMinutes,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'avatar': avatar,
        'age': age,
        'daily_limit_minutes': dailyLimitMinutes,
      };

  factory ChildProfile.fromJson(Map<String, dynamic> json) => ChildProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        avatar: json['avatar'] as String,
        age: json['age'] as int,
        dailyLimitMinutes: (json['daily_limit_minutes'] as int?) ?? 0,
      );
}
