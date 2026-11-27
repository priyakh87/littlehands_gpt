# LittleHands

LittleHands is a Flutter learning app for toddlers aged 2–5, for iOS and Android.

It works **offline**: no accounts, ads or tracking, and no microphone. All content ships inside the app, narration uses the phone's own text-to-speech, and profiles, stars and play time are stored only on the device. The only network use is for buying and checking a Premium subscription (App Store / Google Play via RevenueCat).

## Activities

| Activity | What the child does | Levels |
|---|---|---|
| 🧩 **Matching Game** | Drag each animal picture onto its shadow | 1: 3 animals · 2: 4 animals · 3: 6 animals |
| 🎨 **Color Game** | "Can you find red?" — tap the right colour | 1: Basic colors · 2: More colors · 3: Shapes & colors ("Find the red star!") |
| 🔠 **ABC Rhymes** | Tap letters to hear "A is for Apple" | 1: A–M · 2: N–Z · 3: "Find the letter" quiz |
| 📖 **Story Time** | Short bedtime stories, read aloud page by page | — |
| 🐾 **Animal Sounds** | Tap an animal to hear its name and sound | — |

- Each level unlocks after the previous one is completed.
- Stars per level: 3 with no mistakes, 2 with up to two mistakes, otherwise 1. The home screen shows the child's total.
- Finishing a level or a story shows a celebration: confetti, stars and a spoken cheer, with **Again / Levels / Next**.
- Wrong answers get gentle, non-punitive feedback ("Let's try again!").

## Grown-ups, profiles and Premium

- **Parent PIN** created on first launch; the ⚙️ parent area (children, daily play time, Premium, PIN) is behind it.
- **Child profiles** with their own stars and age; a **daily play limit** shows a calm "time for a break" screen.
- **Free:** Level 1 of every activity, the first story and Animal Sounds. **Premium** unlocks everything else; children only see "ask a grown-up", the paywall is behind the PIN.
- Store and RevenueCat setup: see [docs/SUBSCRIPTIONS.md](docs/SUBSCRIPTIONS.md).

## Getting started

Requirements: Flutter (stable), Xcode for iOS, Android Studio / Android SDK for Android. Run `flutter doctor` to check your setup.

```bash
flutter pub get
flutter run            # pick a connected device or simulator
```

To enable purchases, add the RevenueCat keys at build time (see [docs/SUBSCRIPTIONS.md](docs/SUBSCRIPTIONS.md)):

```bash
flutter run --dart-define=REVENUECAT_IOS_KEY=appl_xxx --dart-define=REVENUECAT_ANDROID_KEY=goog_xxx
```

Checks:

```bash
flutter analyze
flutter test
```

On iOS, CocoaPods is also required (`brew install cocoapods`).

## Adding content

Content is data, not code:

- **Matching levels** — add a JSON file to `assets/data/activities/` (copy `animals_match.json`, set `"level"`), then list it in `assets/data/activities/manifest.json`.
- **Stories, letters, colours and their levels** — edit `assets/data/learning.json` (`stories`, `abc`, `colors`, `color_levels`, `abc_levels`).

Images and sounds go in `assets/animals/` and `assets/sounds/`.

## Project structure

```text
lib/
├── main.dart
├── models/
│   ├── activity.dart            # Matching activity model
│   └── learning_content.dart    # Stories, letters, colours, levels
├── screens/
│   ├── home_screen.dart
│   ├── levels_screen.dart       # Shared level picker + celebrate/next flow
│   ├── animal_screen.dart
│   ├── activities/
│   │   └── drag_match_screen.dart
│   └── learn/
│       ├── abc_screen.dart
│       ├── color_screen.dart
│       └── story_screen.dart
├── services/
│   ├── content_engine.dart      # Loads matching activities from assets
│   ├── progress_service.dart    # Stars saved on device (shared_preferences)
│   └── tts_service.dart         # On-device narration (English / Arabic)
└── widgets/
    ├── celebration.dart         # Confetti + stars "wow" screen
    └── shape_view.dart          # Circle, square, triangle, star, heart
assets/
├── animals/  sounds/  animations/
└── data/
    ├── learning.json
    └── activities/
test/
└── widget_test.dart
```

## Releasing

See the Flutter guides for [iOS](https://docs.flutter.dev/deployment/ios) and [Android](https://docs.flutter.dev/deployment/android). Before the first store release, set a real bundle / application ID (currently `com.example.littlehands_gpt`) and configure signing. Never commit signing keys — they are git-ignored.
