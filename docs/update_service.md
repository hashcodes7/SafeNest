# SafeNest Update Service Walkthrough

SafeNest features a robust, ABI-aware update system that fetches releases directly from GitHub. This document explains the architecture and the files involved.

## Overview
The update system uses the GitHub REST API to fetch the latest releases. It identifies the correct APK for the current device based on its CPU architecture (ABI) and handles the download and execution of the installer.

## Core Components

### 1. `lib/update/update_service.dart`
This is the primary orchestrator. It:
- Fetches the JSON list of releases from `https://api.github.com/repos/hashcodes7/SafeNest/releases`.
- Parses the releases into `UpdateModel` objects.
- Uses `DeviceAbiService` to determine which asset matches the user's device.

### 2. `lib/update/apk_downloader.dart`
Handles the networking and storage logic:
- Uses the `Dio` package for downloading with progress tracking.
- Identifies the correct storage path on Android (`/Android/data/<package>/files/updates/`).
- Manages `CancelToken` to allow users to stop a download in progress.

### 3. `lib/update/device_abi_service.dart`
A utility service that reads the device's supported ABIs:
- Uses `package_info_plus` to detect the current installed version.
- Uses `device_info_plus` (or platform channels via `Platform.executable`) to determine the primary CPU architecture (e.g., `arm64-v8a`, `armeabi-v7a`, `x86_64`).

### 4. `lib/update/update_page.dart`
The UI layer:
- Displays available versions (Upgrades, Downgrades, Reinstalls).
- Shows download progress via a linear progress indicator.
- Triggers the Android package installer once the download is complete using `open_file_plus`.

## Outside `lib/` (Configuration)

### `AndroidManifest.xml`
The following permission is required to allow the app to prompt for installation:
```xml
<uses-permission android:name="android.permission.REQUEST_INSTALL_PACKAGES" />
```

### `pubspec.yaml`
Dependencies used:
- `dio`: For downloading APKs.
- `path_provider`: For finding the correct storage directories.
- `open_file_plus`: For launching the APK installer.
- `pub_semver`: For reliable semantic version comparison.
