import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';

class DeviceAbiService {
  static Future<String> getDeviceAbi() async {
    if (!Platform.isAndroid) return 'unknown';

    final deviceInfo = DeviceInfoPlugin();
    final androidInfo = await deviceInfo.androidInfo;
    
    // supportedAbis contains the list of ABIs supported by the device, 
    // sorted by preference (primary ABI is at index 0).
    final abis = androidInfo.supportedAbis;
    
    if (abis.isNotEmpty) {
      final primaryAbi = abis[0].toLowerCase();
      
      // Keep it simple and flexible
      if (primaryAbi.contains('arm64')) return 'arm64-v8a';
      if (primaryAbi.contains('v7')) return 'armeabi-v7a';
      if (primaryAbi.contains('x86_64')) return 'x86_64';
      
      return primaryAbi;
    }
    
    return 'unknown';
  }
}
