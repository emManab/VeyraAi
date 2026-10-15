# Veyra AI

Veyra AI is a modern Flutter-based AI assistant focused on a clean, privacy-conscious and premium mobile chat experience.

## Overview
Veyra AI allows users to interact with multiple AI providers (including OpenAI, Google Gemini, and custom OpenAI-compatible endpoints) through a beautiful and responsive premium UI. It provides an immediate free-tier experience on first launch and allows advanced users to securely connect their own API keys. 

## Features
- **AI Conversations**: Chat with powerful AI models using a seamless chat interface.
- **Attachments**: Extract text from `.txt`, `.md`, and `.csv` files and send them to the AI, alongside image attachments.
- **Speech-to-Text**: Built-in voice dictation for hands-free prompt input.
- **AI Model / Provider Selection**: Choose between Veyra Free, OpenAI, Google Gemini, and custom providers.
- **Local Persistence**: All conversations, settings, and attachments are saved locally on your device.
- **Profile Customization**: Personalize your display name and profile picture.
- **Privacy & Security Settings**: Full visibility into active permissions, local storage footprint, and the ability to instantly delete all data.
- **Premium UI**: Smooth animations, dynamic dark mode, and a highly polished design system.

## Architecture
Veyra AI strictly follows Clean Architecture principles utilizing the BLoC pattern for state management:
`Presentation -> Bloc -> Use Cases -> Repository Interfaces -> Repository Implementations -> Remote/Local Data Sources`.

Provider abstraction is handled at the repository layer, allowing the UI to remain entirely agnostic to the underlying AI service.

## Tech Stack
- **Framework**: Flutter (Material 3)
- **State Management**: flutter_bloc, get_it
- **Local Storage**: Hive (Conversations/Settings), flutter_secure_storage (API Keys)
- **Networking**: http
- **Routing**: go_router

## Security & API Key Setup
- Veyra AI supports a **Veyra Free** tier that requires no setup.
- If you wish to use OpenAI or Google Gemini, you can securely enter your API keys within the app's Settings screen.
- **Keys are never transmitted anywhere except directly to the provider.** They are stored entirely locally on your device using Android Keystore / iOS Keychain via `flutter_secure_storage`.
- **Never commit your API keys to Git or `.env` files.**

## Setup & Running the App

### Prerequisites
- Flutter SDK (>=3.0.0)
- Android Studio / Xcode

### Installation
```bash
git clone https://github.com/emManab/VeyraAi.git
cd VeyraAi
flutter pub get
flutter run
```

## Building APK/AAB
To build a release APK for Android:
```bash
flutter build apk --release
```

To build a release App Bundle for the Google Play Store:
```bash
flutter build appbundle --release
```
*(Note: Production release builds require configuring local Android signing credentials in `android/key.properties`, which should never be committed to source control.)*

## Roadmap
- Multi-turn conversation branching
- TTS (Text-to-Speech) AI responses
- Web & Desktop support

## License
Currently unlicensed.


## Veyra Wingman

The Wingman screen is available from the home dashboard. It supports importing a screenshot from the device gallery or pasting conversation context, choosing a reply tone, and generating three contextual message suggestions through the selected Veyra AI provider. Replies can be edited and copied; Veyra does not send messages automatically. Analysis history is stored locally in the existing Hive `app_settings` box and can be cleared from the Wingman screen.

### Platform scope and privacy

- **Android:** the current native bridge can open Android's display-over-other-apps permission settings. The draggable cross-app overlay and MediaProjection screenshot capture service are not implemented yet. Use screenshot import to run analysis.
- **iOS and other Flutter targets:** import a screenshot from Photos/Gallery; arbitrary cross-app overlays and unrestricted background screenshots are not supported.
- **Vision models:** Veyra Free is text-only. Screenshot analysis requires a configured Gemini or OpenAI-compatible model that supports image input. Veyra passes the selected screenshot to that provider only after the user taps Analyze.
- Screenshots are not stored in analysis history. History stores the recognized message, summary, reply suggestions, and tone locally. The user can clear this history from the Wingman screen.
- Suggestions are drafts. Veyra never sends a message automatically.

