# SafeNest Biometric service Walkthrough

SafeNest ensures high security with a multi-layered authentication system. This document explains the biometric and fallback mechanism.

## Overview
SafeNest uses a "Biometric-First" approach. If biometrics (Face ID, Fingerprint, etc.) fail or are unavailable, the app falls back to a custom-defined "App Secret" master key.

## Core Components

### 1. `lib/utils/auth_helper.dart`
This is the primary utility for triggering authentication:
- Uses `local_auth` to check for available biometric hardware.
- Prompts the user with `authenticate()`.
- If biometrics fail, it automatically shows a UI dialog (`_showSecretDialog`) via `SecretService`.

### 2. `lib/services/secret_service.dart`
Provides a secure storage layer for the master key:
- Uses `flutter_secure_storage` to encrypt the secret at the OS level (EncryptedSharedPreferences on Android, Keychain on iOS).
- Methods include `saveSecret()`, `getSecret()`, and `verifySecret()`.

### 3. `lib/profile_screen.dart` / `lib/first_time_screen.dart`
Manages the user's secret:
- Users are prompted to set an "App Secret" during the first-time setup as a fallback.
- The secret can be updated later from the Profile screen after verifying the current identity.

### 4. `lib/providers/user_provider.dart`
Controls access to sensitive data (Vaults):
- Integrated with `AuthHelper` so that any attempt to open a "Locked Collection" requires a successful biometric/secret challenge.

## Implementation Details

### Data Flow
1. User taps a locked collection.
2. `AuthHelper.authenticate()` is called.
3. `local_auth` triggers the OS biometric prompt.
4. If successful, access is granted.
5. If denied/unavailable, a dialog appears asking for the "App Secret".
6. `SecretService.verifySecret()` checks the guess against the encrypted storage.

## Outside `lib/` (Configuration)

### `AndroidManifest.xml`
The following permissions and activity configurations are necessary for biometrics:
```xml
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
```
*Note: Some newer versions of Android use a specific FragmentActivity, which is already handled in the `MainActivity.kt` of this project.*

### `pubspec.yaml`
Dependencies used:
- `local_auth`: For system biometric interaction.
- `flutter_secure_storage`: For encrypted master key storage.
