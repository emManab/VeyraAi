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

Veyra Wingman is an Android-first texting coach. It offers a user-triggered floating bubble for screen analysis and a custom keyboard fallback for apps that block screenshots.

### Screenshot workflow

1. Open Veyra AI → Wingman → **Start Wingman**.
2. Grant display-over-other-apps, Usage Access, and Android's screen-capture consent.
3. Open a supported messaging or dating app and tap the floating **V** bubble.
4. Veyra captures one frame, runs OCR locally, and preserves reading order plus approximate left/right text positions. When a vision-capable Gemini or OpenAI-compatible model is selected, the screenshot is also sent with the OCR text.
5. Veyra generates three concise, context-aware next-message options. Review and copy the one you want; Veyra never sends messages automatically.

### Veyra Keyboard fallback

Some apps use protected screens or otherwise block screenshots. For those apps:

1. Copy the last few messages from the conversation (include who said each message if possible).
2. In Wingman, tap **Enable keyboard** and enable **Veyra Keyboard** in Android settings. Then tap **Select keyboard** and choose Veyra Keyboard.
3. Return to the chat, switch to Veyra Keyboard, and tap **Paste chat → Analyze**.
4. **Stay in the same chat app.** Analyze runs inside the keyboard's background Flutter engine; it does not open the Veyra app. A row of categories (Best, Playful, Flirty, Funny, Casual, Confident, Romantic) appears above the keys. Tap a category to preview that reply, then tap **Insert** to place it in the focused message field. Review and send it yourself.

The keyboard uses a larger, Gboard-inspired QWERTY layout with comfortable key targets, shift, backspace (long-press deletes more), symbols, punctuation, space, enter, and a keyboard-switch key. The keyboard only reads clipboard content after the user taps **Paste chat**. It does not scrape the current app's message field or capture screens in the background. Selected conversation text is sent to the configured AI provider when **Analyze** is tapped. Analysis runs in a dedicated background Flutter engine that reads the saved provider and API key from secure storage without opening the main app or its Hive history database.

### Improving reply quality

- For screenshot understanding, configure a vision-capable Gemini or OpenAI-compatible model in Settings. Text-only models use OCR and pasted conversation text; a retry without the image is attempted if a vision endpoint rejects the attachment.
- The prompt reconstructs recent turns, identifies the latest inbound message, mirrors the conversation language (including Hinglish), generates distinct concise options, and asks the model to acknowledge uncertainty rather than invent missing context.
- For best results, copy the last 4–10 messages with speaker labels, for example `Them: ... / Me: ... / Them: ...`.

### Platform scope and privacy

- The floating overlay, MediaProjection capture, and custom keyboard are Android-only. On iOS and other platforms, import a screenshot or paste conversation text in Wingman.
- Screen capture is explicitly user-triggered and requires Android's consent. Apps that mark content secure may appear black; Veyra does not bypass protected-content restrictions.
- OCR runs on-device. Recognized text is sent to the configured AI provider when analysis starts. A configured vision-capable provider also receives the screenshot. The text-only Veyra Free provider receives text, not the image.
- Screenshots are temporary files in app cache; they are not stored in analysis history. Local history stores recognized text and suggested replies and can be cleared in Wingman.
- Supported app detection is based on package IDs and may vary by app version or region. Veyra does not auto-send messages.
