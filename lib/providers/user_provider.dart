import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/collection.dart';
import '../models/field.dart';
import '../models/user.dart';
import '../services/user_storage_service.dart';

class UserProvider extends ChangeNotifier {
  final UserStorageService _storageService = UserStorageService();
  User? _currentUser;
  bool _isLoading = true;

  User? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  UserProvider() {
    _init();
  }

  Future<void> _init() async {
    _currentUser = await _storageService.loadUser();

    // Fallback if the user_data key doesn't exist, but 'name' does from FirstTimeScreen
    if (_currentUser == null) {
      final prefs = await SharedPreferences.getInstance();
      final name = prefs.getString('name') ?? 'Guest';

      _currentUser = User(
        userId: const Uuid().v4(),
        userName: name,
        collections: [],
      );
      await _save();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _save() async {
    if (_currentUser != null) {
      await _storageService.saveUser(_currentUser!);
      notifyListeners();
    }
  }

  Future<void> updateUserName(String newName) async {
    if (_currentUser == null || newName.isEmpty) return;
    _currentUser!.userName = newName;
    await _save();
    
    // Legacy mapping syncing for first-load RootScreen checks
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', newName);

    notifyListeners();
  }

  Future<void> importFromJson(String jsonStr) async {
    try {
      final Map<String, dynamic> jsonMap = json.decode(jsonStr);
      final importedUser = User.fromJson(jsonMap);
      _currentUser = importedUser;
      await _save();
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('name', importedUser.userName);
      
      notifyListeners();
    } catch (e) {
      throw Exception('Failed to load JSON: $e');
    }
  }

  // --- Collection Methods ---

  Future<void> addCollection(String name, {int? iconCodePoint, bool isLocked = false}) async {
    if (_currentUser == null) return;
    final newCollection = Collection(
      collectionId: const Uuid().v4(),
      collectionName: name,
      iconCodePoint: iconCodePoint,
      isLocked: isLocked,
      fields: [],
    );
    _currentUser!.collections.add(newCollection);
    await _save();
  }

  Future<void> editCollection(String id, String newName, {int? iconCodePoint, bool isLocked = false}) async {
    if (_currentUser == null) return;
    final index = _currentUser!.collections.indexWhere((c) => c.collectionId == id);
    if (index != -1) {
      final old = _currentUser!.collections[index];
      _currentUser!.collections[index] = Collection(
        collectionId: old.collectionId,
        collectionName: newName,
        iconCodePoint: iconCodePoint,
        isLocked: isLocked,
        fields: old.fields,
      );
      await _save();
    }
  }

  Future<void> deleteCollection(String id) async {
    if (_currentUser == null) return;
    _currentUser!.collections.removeWhere((c) => c.collectionId == id);
    await _save();
  }

  // --- Field Methods ---

  Future<void> addField(String collectionId, String fieldName, String? url, String? description, {String? thumbnailUrl}) async {
    if (_currentUser == null) return;
    final index = _currentUser!.collections.indexWhere((c) => c.collectionId == collectionId);
    if (index != -1) {
      final newField = Field(
        fieldId: const Uuid().v4(),
        fieldName: fieldName,
        url: url,
        description: description,
        thumbnailUrl: thumbnailUrl,
      );
      _currentUser!.collections[index].fields.add(newField);
      await _save();
    }
  }

  Future<void> editField(String collectionId, String fieldId, String newName, String? newUrl, String? newDescription, {String? newThumbnailUrl}) async {
    if (_currentUser == null) return;
    final cIndex = _currentUser!.collections.indexWhere((c) => c.collectionId == collectionId);
    if (cIndex != -1) {
      final fIndex = _currentUser!.collections[cIndex].fields.indexWhere((f) => f.fieldId == fieldId);
      if (fIndex != -1) {
        final oldField = _currentUser!.collections[cIndex].fields[fIndex];
        _currentUser!.collections[cIndex].fields[fIndex] = Field(
          fieldId: fieldId,
          fieldName: newName,
          url: newUrl,
          description: newDescription,
          thumbnailUrl: newThumbnailUrl ?? oldField.thumbnailUrl,
        );
        await _save();
      }
    }
  }

  Future<void> deleteField(String collectionId, String fieldId) async {
    if (_currentUser == null) return;
    final index = _currentUser!.collections.indexWhere((c) => c.collectionId == collectionId);
    if (index != -1) {
      _currentUser!.collections[index].fields.removeWhere((f) => f.fieldId == fieldId);
      await _save();
    }
  }
}
