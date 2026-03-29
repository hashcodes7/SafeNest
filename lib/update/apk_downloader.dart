import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ApkDownloader {
  final Dio _dio = Dio();
  CancelToken? _cancelToken;

  Future<String> getUpdateDirectory() async {
    // Attempt to use Android-specific external storage directories
    if (Platform.isAndroid) {
      final List<Directory>? dirs = await getExternalStorageDirectories();
      if (dirs != null && dirs.isNotEmpty) {
        final updateDir = Directory(p.join(dirs[0].path, 'updates'));
        if (!await updateDir.exists()) {
          await updateDir.create(recursive: true);
        }
        return updateDir.path;
      }
    }
    
    // Fallback to internal storage for other platforms or if external is unavailable
    final appDir = await getApplicationSupportDirectory();
    final updateDir = Directory(p.join(appDir.path, 'updates'));
    if (!await updateDir.exists()) {
      await updateDir.create(recursive: true);
    }
    return updateDir.path;
  }

  Future<void> download({
    required String url,
    required String fileName,
    required Function(double progress) onProgress,
    required Function(String path) onComplete,
    required Function(dynamic error) onError,
  }) async {
    try {
      _cancelToken = CancelToken();
      final dirPath = await getUpdateDirectory();
      final savePath = p.join(dirPath, fileName);

      await _dio.download(
        url,
        savePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
        cancelToken: _cancelToken,
      );

      onComplete(savePath);
    } catch (e) {
      if (CancelToken.isCancel(e as DioException)) {
        // Silently handle cancellation
      } else {
        onError(e);
      }
    }
  }

  void cancel() {
    _cancelToken?.cancel('User cancelled download');
  }
}
