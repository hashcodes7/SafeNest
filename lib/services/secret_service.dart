import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecretService {
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _secretKey = 'app_master_secret';

  /// Save or overwrite the App Secret
  static Future<void> saveSecret(String secret) async {
    await _storage.write(key: _secretKey, value: secret);
  }

  /// Retrieve the current App Secret
  static Future<String?> getSecret() async {
    return await _storage.read(key: _secretKey);
  }

  /// Check if an App Secret has been set yet
  static Future<bool> hasSecret() async {
    final secret = await getSecret();
    return secret != null && secret.isNotEmpty;
  }

  /// Verify a given guess against the stored App Secret
  static Future<bool> verifySecret(String guess) async {
    final stored = await getSecret();
    if (stored == null) return false;
    return stored == guess;
  }
}
