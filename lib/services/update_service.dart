import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_release.dart';
import 'app_version_service.dart';

class UpdateService {
  static const String _githubApiUrl =
      'https://api.github.com/repos/hashcodes7/SafeNest/contents/updates';
  static const String _downloadedVersionsKey = 'downloaded_versions';

  final Dio _dio = Dio();

  Future<List<AppRelease>> fetchReleases() async {
    try {
      final response = await _dio.get(_githubApiUrl);
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final installedVersion = await AppVersionService.getInstalledVersion();
        final prefs = await SharedPreferences.getInstance();
        final downloadedVersions = _getDownloadedVersions(prefs);

        List<AppRelease> releases = [];

        for (var item in data) {
          final String name = item['name'];
          final String downloadUrl = item['download_url'];

          // Pattern: safenest_<version>.apk
          final regExp = RegExp(r'safenest_(.*)\.apk');
          final match = regExp.firstMatch(name);

          if (match != null) {
            final version = match.group(1)!;
            final status = _compareVersions(version, installedVersion);
            final localPath = downloadedVersions[version];

            releases.add(
              AppRelease(
                version: version,
                downloadUrl: downloadUrl,
                status: status,
                downloaded: localPath != null && File(localPath).existsSync(),
                localPath: localPath,
              ),
            );
          }
        }

        // Sort versions highest to lowest
        releases.sort((a, b) => _compareSemantic(b.version, a.version));

        return releases;
      }
    } catch (e) {
      rethrow;
    }
    return [];
  }

  ReleaseStatus _compareVersions(String remote, String installed) {
    int comparison = _compareSemantic(remote, installed);
    if (comparison > 0) return ReleaseStatus.upgrade;
    if (comparison == 0) return ReleaseStatus.installed;
    return ReleaseStatus.downgrade;
  }

  int _compareSemantic(String v1, String v2) {
    List<int> v1Parts = v1.split('.').map(int.parse).toList();
    List<int> v2Parts = v2.split('.').map(int.parse).toList();

    int length = v1Parts.length > v2Parts.length ? v1Parts.length : v2Parts.length;

    for (int i = 0; i < length; i++) {
      int p1 = i < v1Parts.length ? v1Parts[i] : 0;
      int p2 = i < v2Parts.length ? v2Parts[i] : 0;

      if (p1 > p2) return 1;
      if (p1 < p2) return -1;
    }
    return 0;
  }

  Map<String, String> _getDownloadedVersions(SharedPreferences prefs) {
    final String? jsonString = prefs.getString(_downloadedVersionsKey);
    if (jsonString != null) {
      return Map<String, String>.from(jsonDecode(jsonString));
    }
    return {};
  }

  Future<void> _saveDownloadedVersion(String version, String path) async {
    final prefs = await SharedPreferences.getInstance();
    final downloaded = _getDownloadedVersions(prefs);
    downloaded[version] = path;
    await prefs.setString(_downloadedVersionsKey, jsonEncode(downloaded));
  }

  Future<void> downloadApk({
    required String url,
    required String version,
    required Function(double progress) onProgress,
    required Function(String path) onComplete,
    required Function(String error) onError,
  }) async {
    try {
      final directory = await getExternalStorageDirectory();
      if (directory == null) {
        onError("Storage directory not found");
        return;
      }

      final filePath = '${directory.path}/safenest_$version.apk';
      
      await _dio.download(
        url,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );

      await _saveDownloadedVersion(version, filePath);
      onComplete(filePath);
    } catch (e) {
      onError(e.toString());
    }
  }
}
