# AI Usage and Security Model

This document details how the AI Chat Assistant handles API keys, credentials, and AI provider integration.

## Security Architecture

### API Key Storage

**Storage mechanism**: `flutter_secure_storage` backed by Android Keystore

- API keys are **never** stored in plain text
- Keys are encrypted at rest using Android's hardware-backed Keystore
- Keys are isolated per provider (OpenAI, Gemini, OpenAI-compatible)
- Keys never appear in logs, error messages, or repository files

### Security Guarantees

✅ **What we do:**
- Store API keys in Android Keystore with hardware encryption
- Validate API keys only by attempting actual API calls (no client-side regex)
- Transmit keys only over HTTPS to configured endpoints
- Wipe keys from memory after use
- Mask keys in the settings UI after initial entry

❌ **What we don't do:**
- Never log API keys or Authorization headers
- Never commit secrets to version control
- Never display keys in error messages
- Never transmit keys to third parties (only to configured AI provider endpoints)

### Threat Model

**Client-side key storage tradeoffs:**

This app stores API keys **on-device** rather than proxying through a backend. This design choice means:

**✅ Advantages:**
- Zero backend infrastructure or hosting costs
- No single point of compromise (each user's keys are isolated)
- Works offline for conversation browsing
- User has full control over their credentials

**⚠️ Limitations:**
- Keys can be extracted by malware with root access or device compromise
- No rate limiting across users (each key's quota is provider-enforced)
- No centralized key rotation or revocation
- Users must obtain and manage their own API keys

**Suitable for:**
- Personal use, demos, prototypes, internal tools
- Educational projects and internship assessments
- Scenarios where users trust their device security

**Not suitable for:**
- Production apps distributed to untrusted users
- Enterprise scenarios requiring centralized key management
- Apps needing backend rate limiting or usage analytics

## AI Provider Integration

### Provider Abstraction

All AI providers implement the `AIRepository` interface:

```dart
abstract class AIRepository {
  Future<(String?, AppError?)> sendMessage({
    required List<Message> history,
    required String userMessage,
    required AIProviderConfig config,
    required String apiKey,
  });
}
```

### Supported Providers

#### OpenAI
- **Endpoint**: `https://api.openai.com/v1/chat/completions`
- **Authentication**: `Authorization: Bearer sk-...`
- **Models**: `gpt-4o-mini`, `gpt-4o`, `gpt-3.5-turbo`, etc.
- **Message format**: OpenAI Chat Completions API
- **Error handling**: Maps OpenAI-specific error codes to `AppError` types

#### Google Gemini
- **Endpoint**: `https://generativelanguage.googleapis.com/v1beta/models/{model}:generateContent`
- **Authentication**: `?key=<api-key>` (query parameter)
- **Models**: `gemini-1.5-flash`, `gemini-1.5-pro`, `gemini-2.0-flash-exp`, etc.
- **Message format**: Gemini REST API format (converted from OpenAI-style messages)
- **Error handling**: Maps Gemini-specific errors to `AppError` types

#### OpenAI-Compatible Endpoints
- **Endpoint**: User-configured (e.g., `http://localhost:1234/v1/chat/completions`)
- **Authentication**: Configurable (can be empty for local endpoints)
- **Models**: User-specified
- **Message format**: OpenAI Chat Completions API
- **Examples**: LM Studio, LocalAI, Ollama with OpenAI shim, vLLM, text-generation-webui

### Network Security

- All production endpoints use **HTTPS only** (HTTP allowed only for `localhost` and `127.0.0.1`)
- TLS certificate validation enforced by `http` package
- Timeout: 60 seconds per request
- No request retries (user can manually retry from error state)

### Error Handling

Errors are mapped to domain-level `AppError` sealed classes:

- `NetworkError`: No internet connection
- `TimeoutError`: Request exceeded 60s
- `AuthError`: 401/403 (invalid/expired API key)
- `RateLimitError`: 429 (quota exceeded)
- `InvalidResponseError`: Malformed JSON, unexpected schema
- `StorageError`: Hive/secure storage failures
- `UnknownError`: Uncategorized failures

## Configuration Persistence

### Provider Configuration Storage

Stored in **Hive** (unencrypted, as it contains no secrets):

```dart
class AIProviderConfig {
  final AIProvider provider;     // enum: openai, gemini, openaiCompatible
  final String baseUrl;          // e.g., https://api.openai.com/v1
  final String modelName;        // e.g., gpt-4o-mini
}
```

### API Key Storage

Stored in **flutter_secure_storage** (encrypted):

- Keys stored per provider: `api_key_openai`, `api_key_gemini`, `api_key_openaiCompatible`
- Retrieved on-demand when sending messages
- Never cached in memory beyond the duration of a single send operation

## Best Practices for Users

### For Personal Use

1. **Obtain API keys** from official provider dashboards:
   - OpenAI: https://platform.openai.com/api-keys
   - Gemini: https://aistudio.google.com/apikey

2. **Set usage limits** in your provider dashboard to prevent unexpected charges

3. **Rotate keys** if you suspect compromise:
   - Revoke old key in provider dashboard
   - Update key in app settings

4. **Use least-privilege keys** where available (read-only keys where supported)

### For Local Development

- Use OpenAI-compatible mode with local models (LM Studio, Ollama) to avoid API costs
- Leave API key blank for local endpoints that don't require authentication

## Extending to Production

If adapting this architecture for a production app, consider:

1. **Backend proxy**: Move API key storage to a secure backend, never ship keys to client
2. **Rate limiting**: Implement per-user quotas server-side
3. **Monitoring**: Track usage and costs per user
4. **Key rotation**: Centralized key management and automatic rotation
5. **Audit logging**: Log all API requests for security and compliance
6. **User authentication**: Require sign-in before allowing AI access

---

## Engineering Decisions & AI Tooling Record

### Tools & Models Used
- **Agent System**: Antigravity Assistant (Google DeepMind advanced agentic framework)
- **Primary Model**: Gemini 2.5 Flash / Claude 3.5 Sonnet architecture analysis
- **Static Analysis**: Dart Analyzer 10.0.1 / Flutter SDK 3.41.6
- **Device Emulation / Testing**: Physical Android Device `24115RA8EI` (Android 16 API 36)

### Key Architectural Refactorings Executed
1. **Prompt Duplication Bug Remediation**:
   - `SendChatMessage` previously passed `historyWithUser` containing `userMsg`, while clients appended `userMessage` again. Cleaned contract so `history` passes only historical context.
2. **Chat List Anchoring**:
   - Replaced fragile forward `AnimatedList` with standard `ListView.builder(reverse: true)` to ensure zero-jitter keyboard handling, natural bottom anchoring, and zero index out-of-bound errors.
3. **Optimistic UI Updates**:
   - `ChatBloc` now dispatches temporary user messages immediately to state, ensuring instant visual feedback while awaiting AI response.
4. **Design System Unification**:
   - Standardized typography across all 4 screens to Google Fonts `Inter`.
   - Replaced scattered raw hex colors with centralized `AppTheme` palette constants.
5. **Android 11+ Queries Package Visibility**:
   - Added `https` intent query in `AndroidManifest.xml` to fix `canLaunchUrl` runtime blocks.
6. **Automated Test Coverage**:
   - Added unit and bloc tests verifying `SendChatMessage`, `ChatBloc`, and `ConversationBloc`.

