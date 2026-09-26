# Security Policy

## Supported Versions

Only the latest `main` branch is actively supported for security updates.

## Reporting a Vulnerability

Security takes priority in Veyra AI. If you discover a security vulnerability within this project (such as potential credential leaks, insecure storage implementations, or unauthorized data transmission), please do not report it in public GitHub issues.

Instead, please privately report it to the repository maintainer or use the GitHub Security Advisory "Report a Vulnerability" feature if enabled on the repository.

### Guidelines
- **Never commit API keys, signing keys, or `.env` files.**
- Ensure you have reviewed `.gitignore` prior to pushing any local configurations.
- All external API credentials must be managed via `flutter_secure_storage`.
- Do not store plaintext secrets in `SharedPreferences` or `Hive`.
