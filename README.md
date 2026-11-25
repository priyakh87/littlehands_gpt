# LittlehandsGPT

LittlehandsGPT is a cross‑platform mobile application built with Flutter for iOS and Android. It is a friendly learning companion for toddlers aged 2–5, offering interactive games, bedtime stories, alphabet rhymes and colour exploration. The app is fully offline: no network calls, no API keys, no microphone and no child data leaves the device.

## Features

* 🐾 **Animal Sounds** – Teach children what different animals sound like.
* 📖 **Story Time** – Short bedtime stories suitable for young children.
* 🔠 **ABC Rhymes** – Fun rhymes to learn the alphabet.
* 🎨 **Colour Games** – Simple interactions to recognise colours.
* 🧩 **Matching Game** – Drag-and-drop activities driven by JSON files in `assets/data/activities/`.
* 🔊 **Narration** – On-device text‑to‑speech in English and Arabic.
* 📴 **Offline Mode** – Fully functional without an internet connection.
* 🧸 **Animated Mascot** – A friendly character engages children on the home screen.

## Getting Started

### Prerequisites

This project requires a Flutter development environment. Follow these steps on your MacBook Air M1:

1. **Install Homebrew** (if not already installed):
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   ```
2. **Install Flutter**:
   ```bash
   brew install --cask flutter
   ```
   After installation, add Flutter to your path and run `flutter doctor` to set up dependencies.
3. **Install Xcode** via the Mac App Store to build for iOS.
4. **Install Android Studio** from [developer.android.com](https://developer.android.com/studio) and follow the setup wizard to install Android SDKs.
5. **Set up emulators/simulators** via Xcode’s Simulator and Android Studio’s AVD Manager.

### Cloning the Project

Clone or download this repository, then install dependencies:

```bash
git clone <repo_url>
cd littlehands_gpt
flutter pub get
```

### Adding activities

Activities are data, not code. To add one, drop a JSON file into `assets/data/activities/` (see `animals_match.json` for the format) and list its filename in `assets/data/activities/manifest.json`.

### Running the App

To run on an iOS simulator (e.g., iPhone 14):

```bash
flutter run -d ios
```

To run on an Android emulator:

```bash
flutter run -d android
```

### Building for Production

To build an iOS simulator app bundle:

```bash
flutter build ios --simulator
```

To build an Android APK for testing:

```bash
flutter build apk --debug
```

For App Store and Play Store releases, consult the official Flutter documentation on [code signing](https://docs.flutter.dev/deployment/ios) and [app bundles](https://docs.flutter.dev/deployment/android) or use the included PDF setup guide.

## Structure

The project follows a clear structure:

```text
littlehands_gpt/
├── lib/
│   ├── main.dart            # App entry point
│   ├── models/activity.dart       # Activity data model
│   ├── screens/
│   │   ├── home_screen.dart       # Home screen
│   │   ├── animal_screen.dart     # Animal sounds
│   │   └── activities/
│   │       └── drag_match_screen.dart # Drag-and-drop matching
│   └── services/
│       ├── content_engine.dart    # Loads bundled activity JSON
│       └── tts_service.dart       # On-device narration
├── assets/
│   ├── data/activities/           # Activity definitions + manifest
│   ├── data/offline_prompts.json  # Stories, rhymes, colours
│   └── animations/mascot.json     # Lottie mascot
├── pubspec.yaml            # Flutter dependencies and assets
└── README.md               # This file
```

## Contributing

This project was generated as a proof of concept for a toddler learning application. Pull requests and improvements are welcome.