# SafeNest Data Import/Export service Walkthrough

SafeNest provides users with complete ownership of their data through a robust JSON-based import and export system. This document explains the data handling architecture.

## Overview
All user data (Collections, Fields, and User Metadata) is serialized into a standard JSON format. This allows for easy backups, manual auditing, and migration between devices.

## Core Components

### 1. `lib/providers/user_provider.dart`
Contains the core business logic for data handling:
- **`importFromJson()`**: Replaces the entire local vault with the content of the JSON file.
- **`importAndMergeFromJson()`**: A sophisticated merge algorithm that compares incoming collections with local ones by name. It adds new collections, merges overlapping fields (avoiding duplicates based on IDs), and updates lock statuses.
- **`toJson()`**: Generates the complete JSON tree representing the user's data.

### 2. `lib/my_data_screen.dart`
The UI layer for data operations:
- **Export**: Triggers `_exportData()`, which saves the current JSON to a temporary file and uses the system's Share Sheet (`share_plus`) to send it to other apps or cloud storage.
- **Import**: Uses `file_selector` to let users pick a `.json` file from their device and provides a choice between "Merge" and "Replace" strategies.

### 3. `lib/services/user_storage_service.dart`
The persistence layer:
- Handles low-level reading and writing of the `user_data` JSON string to `shared_preferences`.

## Implementation Details

### Data Merging Algorithm (Optimized v1.0.6)
To handle large vaults efficiently, the merge logic uses a Map-based lookup:
1. Load incoming JSON.
2. Index current collections by their lowercased names in a temporary Map.
3. Iterate through incoming collections.
4. If a name match is found, merge fields into the existing collection using a Set of IDs to prevent duplicates.
5. If no match is found, add the entire collection.
6. Persist the final merged state.

## Outside `lib/` (Configuration)

### `pubspec.yaml`
Dependencies used:
- `share_plus`: For system-level sharing of backup files.
- `file_selector`: For cross-platform file picking.
- `uuid`: For generating unique IDs for every collection and field to ensure reliable merging.

## JSON schema
SafeNest uses a simple, nested schema:
```json
{
  "userId": "uuid-v4-string",
  "userName": "string",
  "collections": [
    {
      "collectionId": "uuid-v4-string",
      "collectionName": "string",
      "isLocked": "boolean",
      "iconCodePoint": "int?",
      "fields": [
        {
          "fieldId": "uuid-v4-string",
          "fieldName": "string",
          "url": "string?",
          "description": "string?",
          "thumbnailUrl": "string?"
        }
      ]
    }
  ]
}
```
