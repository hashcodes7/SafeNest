# SafeNest

SafeNest is a Flutter application focusing on a highly secure, offline-first approach to user data persistence using a structured JSON pattern via SharedPreferences.

## Features

- **Decoupled Architecture**: Mimics a powerful backend response format perfectly structured as a JSON tree (User -> Collections -> Fields).
- **Offline Data**: Stored deeply in SharedPreferences without needing bulky database solutions like Hive or SQLite, but optimized perfectly for a drop-in API replacement in the future.
- **Swipe Interactions**: Natively integrated swipe gestures for intuitive list mutations across the whole app.
  - Swipe **Right** to **Delete** items smoothly.
  - Swipe **Left** to **Edit** your entries rapidly.
- **Provider-based Global State**: Instantaneous UI refreshes using standard `ChangeNotifierProvider` connected flawlessly with deep local storage saves.

## Getting Started

1. Get dependencies:
```bash
flutter pub get
```

2. Run the application:
```bash
flutter run
```

*Designed with Flutter and ♥ for scalable data.*
