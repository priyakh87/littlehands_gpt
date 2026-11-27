import 'subscription_service.dart';

/// What is free and what needs LittleHands Premium. Change these rules in
/// one place.
///
/// Free: Level 1 of every activity, the first story and Animal Sounds.
/// Premium: every other level and story.
class AccessPolicy {
  static bool isFreeLevel(int index) => index == 0;
  static bool isFreeStory(int index) => index == 0;

  static bool canPlayLevel(int index) =>
      isFreeLevel(index) || SubscriptionService.isPremium.value;

  static bool canReadStory(int index) =>
      isFreeStory(index) || SubscriptionService.isPremium.value;
}
