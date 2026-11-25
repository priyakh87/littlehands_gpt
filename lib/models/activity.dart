/// Describes one activity, loaded from a JSON file in assets/data/activities/.
/// Adding new content = adding a new JSON file + assets, never new Dart code.
class Activity {
  final String id;
  final String type; // 'drag_match', 'trace', 'sort', 'tap_reveal', etc.
  final String titleEn;
  final String titleAr;
  final int minAge;
  final int maxAge;
  final List<ActivityItem> items;

  Activity({
    required this.id,
    required this.type,
    required this.titleEn,
    required this.titleAr,
    required this.minAge,
    required this.maxAge,
    required this.items,
  });

  factory Activity.fromJson(Map<String, dynamic> json) {
    return Activity(
      id: json['id'] as String,
      type: json['type'] as String,
      titleEn: json['title_en'] as String,
      titleAr: json['title_ar'] as String,
      minAge: json['min_age'] as int,
      maxAge: json['max_age'] as int,
      items: (json['items'] as List)
          .map((i) => ActivityItem.fromJson(i as Map<String, dynamic>))
          .toList(),
    );
  }
}

/// One matchable pair/piece within an activity — e.g. a "lion" image
/// that should be dragged onto the "lion" outline target.
class ActivityItem {
  final String id;
  final String imageAsset;
  final String labelEn;
  final String labelAr;
  final String matchTargetId; // id of the target it belongs to

  ActivityItem({
    required this.id,
    required this.imageAsset,
    required this.labelEn,
    required this.labelAr,
    required this.matchTargetId,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) {
    return ActivityItem(
      id: json['id'] as String,
      imageAsset: json['image_asset'] as String,
      labelEn: json['label_en'] as String,
      labelAr: json['label_ar'] as String,
      matchTargetId: json['match_target_id'] as String,
    );
  }
}
