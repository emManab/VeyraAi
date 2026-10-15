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

On Android, Wingman can run as an explicitly started foreground service. After the user grants display-over-other-apps, Usage Access, and Android screen-capture consent, a draggable V bubble appears over supported apps: WhatsApp, WhatsApp Business, Instagram, Tinder, Bumble, Hinge, Messenger, Telegram, Signal, Snapchat, Discord, Google Messages, Viber, LINE, WeChat, and Skype.

### How the live workflow works

1. Open Veyra AI → Wingman → **Start Wingman**.
2. Grant the three Android permissions when prompted. Return to Wingman and tap Start again after returning from the overlay or Usage Access settings.
3. Open a supported chat app. The floating **V** bubble appears while that app is foregrounded.
4. Tap the bubble to capture the current screen. Capture is user-triggered; the bubble is removed briefly so it does not cover the conversation.
5. On-device ML Kit OCR extracts readable text from the screenshot. Veyra opens its analysis screen and sends the recognized text to the selected AI provider. If a vision-capable Gemini or OpenAI-compatible model is configured, the screenshot is also attached for image understanding.
6. After suggestions are generated, return to the supported chat app to see the floating reply panel. Tap a suggestion to copy it, then review and send it yourself.

### Platform scope, privacy, and limits

- **Android only for the live bubble:** cross-app overlays and MediaProjection capture are not available on iOS. On other platforms, import a screenshot manually.
- **User-triggered capture only:** Veyra does not continuously record or automatically capture chats. Screen capture requires Android's consent dialog for each session.
- **On-device OCR:** OCR runs locally. Recognized text is sent to the configured AI provider when analysis starts. A configured vision-capable provider also receives the screenshot; the text-only Veyra Free provider receives OCR text, not the image.
- **Protected content:** Android apps that mark their screen as secure may appear black in captures. Veyra does not bypass protected-content restrictions.
- **Supported package IDs:** `com.whatsapp`, `com.whatsapp.w4b`, `com.instagram.android`, `com.tinder`, `com.bumble.app`, `co.hinge.app`, `com.facebook.orca`, `org.telegram.messenger`, `org.thoughtcrime.securesms`, `com.snapchat.android`, `com.discord`, `com.google.android.apps.messaging`, `com.viber.voip`, `jp.naver.line.android`, `com.tencent.mm`, and `com.skype.raider`. App package IDs can vary by region or app version.
- Screenshots are not stored in analysis history; captured images are temporary files in the app cache. Local analysis history stores recognized text and suggested replies and can be cleared in Wingman.
- Suggestions are drafts. Veyra never sends a message automatically.
