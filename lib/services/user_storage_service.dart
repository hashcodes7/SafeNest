import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:encrypt/encrypt.dart' as enc;
import '../models/user.dart';

class UserStorageService {
  static const String _key = 'user_data';
  static const _secureStorage = FlutterSecureStorage();
  static const String _aesKeyId = 'safenest_aes_key';

  Future<enc.Key> _getOrCreateKey() async {
    final keyString = await _secureStorage.read(key: _aesKeyId);
    if (keyString != null) {
      return enc.Key.fromBase64(keyString);
    } else {
      final newKey = enc.Key.fromSecureRandom(32);
      await _secureStorage.write(key: _aesKeyId, value: newKey.base64);
      return newKey;
    }
  }

  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(user.toJson());
    
    final key = await _getOrCreateKey();
    final iv = enc.IV.fromSecureRandom(16);
    final encrypter = enc.Encrypter(enc.AES(key));
    
    final encrypted = encrypter.encrypt(jsonString, iv: iv);
    
    // Combine IV and CipherText
    final payload = '${iv.base64}:${encrypted.base64}';
    
    await prefs.setString(_key, payload);
  }

  Future<User?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? rawData = prefs.getString(_key);
    
    if (rawData == null) return null;

    String jsonString = rawData;

    // Check if it's legacy raw JSON mapping or Encrypted
    if (!rawData.trim().startsWith('{')) {
      try {
        final parts = rawData.split(':');
        if (parts.length == 2) {
          final key = await _getOrCreateKey();
          final iv = enc.IV.fromBase64(parts[0]);
          final encrypter = enc.Encrypter(enc.AES(key));
          jsonString = encrypter.decrypt64(parts[1], iv: iv);
        }
      } catch (e) {
        // If decryption fails due to key mismatch or corrupted JSON
        return null;
      }
    } else {
      // It's legacy raw JSON. 
      // We process it now, but calling saveUser() later triggers the permanent encryption swap automatically.
    }

    try {
      final Map<String, dynamic> jsonMap = jsonDecode(jsonString);
      return User.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  Future<void> clearUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
