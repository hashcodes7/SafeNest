# SafeNest Theme service Walkthrough

SafeNest features a high-end, customizable theme engine that provides users with total control over the visual identity of the app. This document explains how the theme system is implemented.

## Overview
The theme service is built on top of `ThemeData` and a set of predefined `AppThemeColor` enumerations. It allows users to switch between Light, Dark, and System modes independently from the device's global settings.

## Core Components

### 1. `lib/theme_provider.dart`
The central orchestrator of the theme logic:
- Defines `enum AppThemeColor` (Mocha, Crimson, Lavender, Emerald, etc.) and `Pure Black`.
- Uses `shared_preferences` to persist the user's choices (`_themeMode` and `_themeColor`).
- Dynamically constructs `ThemeData` using `ColorScheme.fromSeed` to generate harmonious color palettes.
- Implements a unique "Very Dark" mode (a deep blend of the theme's primary color with dark grey) for a premium dark experience.

### 2. `lib/settings_screen.dart`
The UI layer for theme management:
- Features a `SegmentedButton` for switching between Light, Dark, and System modes.
- Provides a horizontal `ListView` of "Phone-Mockup" style theme pickers for visual selection of color schemes.

### 3. `lib/main.dart`
Bootstraps the theme system:
- Wraps the entire `MaterialApp` with a `ThemeProvider` consumer.
- Passes `themeProvider.lightTheme` and `themeProvider.darkTheme` to the root widget.

## Special Features

### Pure Black Mode
When a user selects the "Pure Black" theme color and is in Dark Mode, the app strictly uses `#000000` for the scaffold background and surfaces. This is highly beneficial for OLED screens, providing maximum contrast and power savings.

### Dynamic Typography
SafeNest uses the `Outfit` font family via the `google_fonts` package. The typography remains consistent across all themes and adapts its weight and size based on the current `ColorScheme`.

## Implementation Details

### Data Flow
1. User selects a theme in `SettingsScreen`.
2. `ThemeProvider.setThemeMode()` or `setThemeColor()` is called.
3. Preferences are saved to local storage.
4. `notifyListeners()` is triggered.
5. `MaterialApp` rebuilds with the new `ThemeData`.

## Outside `lib/` (Configuration)

### `pubspec.yaml`
Dependencies used:
- `google_fonts`: For consistent, premium typography.
- `shared_preferences`: For persistent theme settings.
