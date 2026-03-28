import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';

class DeviceArchitectureService {
  static Future<String> getDeviceAbi() async {
    if (!Platform.isAndroid) return 'unknown';

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    
    // supportedAbis contains the list of ABIs supported by the device, 
    // sorted by preference (primary ABI is at index 0).
    final abis = androidInfo.supportedAbis;
    
    if (abis.isNotEmpty) {
      // Map common Android ABIs to our naming scheme if necessary, 
      // though they usually match exactly (arm64-v8a, armeabi-v7a, x86_64).
      final primaryAbi = abis[0].toLowerCase();
      
      if (primaryAbi.contains('arm64')) return 'arm64-v8a';
      if (primaryAbi.contains('v7')) return 'armeabi-v7a';
      if (primaryAbi.contains('x86_64')) return 'x86_64';
      
      return primaryAbi;
    }
    
    return 'unknown';
  }
}
