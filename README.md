# LittlehandsGPT

LittlehandsGPT is a cross‑platform mobile application built with Flutter for iOS and Android. It acts as a friendly AI companion for toddlers aged 2–5, offering interactive games, bedtime stories, alphabet rhymes and colour exploration. The app can operate entirely offline using pre‑packaged prompts or connect to OpenAI’s GPT‑4o API for dynamic content if an API key is provided.

## Features

* 🐾 **Animal Sounds** – Teach children what different animals sound like.
* 📖 **Story Time** – Short bedtime stories suitable for young children.
* 🔠 **ABC Rhymes** – Fun rhymes to learn the alphabet.
* 🎨 **Colour Games** – Simple interactions to recognise colours.
* 🎤 **Voice Input** – Listen to a child’s speech and act on simple commands.
* 🔊 **Voice Output** – Read responses aloud using text‑to‑speech.
* 📴 **Offline Mode** – Fully functional without an internet connection.
* 🌐 **Online Mode** – Enhanced content via GPT‑4o when an API key is supplied.
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

### Configuration

Copy `.env.example` to `.env` and paste your OpenAI API key:

```bash
cp .env.example .env
echo "OPENAI_API_KEY=sk-..." >> .env
```

If you don’t provide a key, the app will remain in offline mode and use the included JSON prompts.

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
│   ├── screens/
│   │   └── home_screen.dart # UI and logic for the home screen
│   └── services/
│       └── ai_service.dart  # API client for OpenAI
├── assets/
│   ├── data/offline_prompts.json # Offline content definitions
│   └── animations/mascot.json    # Placeholder Lottie file for mascot
├── .env.example            # Template for environment variables
├── pubspec.yaml            # Flutter dependencies and assets
└── README.md               # This file
```

## Contributing

This project was generated as a proof of concept for an AI‑powered toddler application. Pull requests and improvements are welcome.