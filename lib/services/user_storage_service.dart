import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class UserStorageService {
  static const String _key = 'user_data';

  Future<void> saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();
    final String jsonString = jsonEncode(user.toJson());
    await prefs.setString(_key, jsonString);
  }

  Future<User?> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonString = prefs.getString(_key);
    
    if (jsonString == null) {
      return null;
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
