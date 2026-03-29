import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:package_info_plus/package_info_plus.dart';

class InstallPermissionService {
  /// Checks if the "Install Unknown Apps" permission is granted on Android.
  static Future<bool> isInstallPermissionGranted() async {
    if (!Platform.isAndroid) return true;

    // requestInstallPackages corresponds to the 
    // android.permission.REQUEST_INSTALL_PACKAGES permission.
    final status = await Permission.requestInstallPackages.status;
    return status.isGranted;
  }

  /// Opens the Android settings page for "Install Unknown Apps" for this app.
  static Future<void> openInstallSettings() async {
    if (!Platform.isAndroid) return;
    
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final packageName = packageInfo.packageName;

      final intent = AndroidIntent(
        action: 'android.settings.MANAGE_UNKNOWN_APP_SOURCES',
        data: 'package:$packageName',
      );
      
      await intent.launch();
    } catch (_) {
      // Fallback to general app settings if the specific intent fails
      await openAppSettings();
    }
  }
}
