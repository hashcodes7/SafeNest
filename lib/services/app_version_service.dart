import 'package:package_info_plus/package_info_plus.dart';

class AppVersionService {
  static Future<String> getInstalledVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final versionName = packageInfo.version; // e.g., "1.2.0" or "safenest 1.2"

    // Extract only the numeric part (e.g., "1.2" from "safenest 1.2" or "1.2.0" from "1.2.0")
    // The requirement says "returned version must be only the numeric version, for example: 1.0, 1.1, 1.2"
    final regex = RegExp(r'(\d+\.\d+(\.\d+)?)');
    final match = regex.firstMatch(versionName);
    
    if (match != null) {
      return match.group(1)!;
    }
    
    return versionName;
  }
}
