import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pub_semver/pub_semver.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

import 'update_model.dart';
import 'device_abi_service.dart';
import 'apk_downloader.dart';

class UpdateService {
  final Dio _dio = Dio();
  static const String _releasesUrl =
      'https://api.github.com/repos/hashcodes7/SafeNest/releases';

  Future<List<AppRelease>> fetchReleases() async {
    try {
      final response = await _dio.get(_releasesUrl);
      if (response.statusCode == 200) {
        final List<dynamic> releasesJson = response.data;
        final packageInfo = await PackageInfo.fromPlatform();
        final currentVersion = Version.parse(packageInfo.version);
        final deviceAbi = await DeviceAbiService.getDeviceAbi();
        final apkDownloader = ApkDownloader();
        final updateDirPath = await apkDownloader.getUpdateDirectory();

        final List<AppRelease> releases = [];
        // Pattern: safenest_1.4.0_arm64-v8a.apk
        // Capture version and any ABI string
        final regex = RegExp(r'^safenest_(\d+\.\d+\.\d+)_(.*)\.apk$');

        for (var releaseJson in releasesJson) {
          final assets = releaseJson['assets'] as List<dynamic>;
          for (var asset in assets) {
            final name = asset['name'] as String;
            final match = regex.firstMatch(name);
            if (match != null) {
              final versionStr = match.group(1)!;
              final abi = match.group(2)!;
              final downloadUrl = asset['browser_download_url'] as String;
              
              final remoteVersion = Version.parse(versionStr);
              final isSupported = (abi == deviceAbi);
              
              final status = _determineStatus(remoteVersion, currentVersion, isSupported);
              
              final localPath = p.join(updateDirPath, name);
              final isDownloaded = await File(localPath).exists();

              releases.add(
                AppRelease(
                  version: versionStr,
                  abi: abi,
                  downloadUrl: downloadUrl,
                  status: status,
                  isSupported: isSupported,
                  isDownloaded: isDownloaded,
                  localPath: isDownloaded ? localPath : null,
                ),
              );
            }
          }
        }

        // Sort: highest version first
        releases.sort((a, b) {
          final vA = Version.parse(a.version);
          final vB = Version.parse(b.version);
          int cmp = vB.compareTo(vA);
          if (cmp != 0) return cmp;
          return a.abi.compareTo(b.abi);
        });

        return releases;
      }
    } catch (e) {
      // Re-throw or handle error
      rethrow;
    }
    return [];
  }

  UpdateStatus _determineStatus(Version remote, Version current, bool isSupported) {
    if (!isSupported) return UpdateStatus.unsupported;
    if (remote > current) return UpdateStatus.update;
    if (remote == current) return UpdateStatus.installed;
    return UpdateStatus.downgrade;
  }
}
