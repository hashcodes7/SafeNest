

enum UpdateStatus {
  installed,
  update,
  downgrade,
  unsupported,
}

class AppRelease {
  final String version;
  final String abi;
  final String downloadUrl;
  final UpdateStatus status;
  final bool isSupported;
  final bool isDownloaded;
  final String? localPath;

  AppRelease({
    required this.version,
    required this.abi,
    required this.downloadUrl,
    required this.status,
    required this.isSupported,
    this.isDownloaded = false,
    this.localPath,
  });

  AppRelease copyWith({
    String? version,
    String? abi,
    String? downloadUrl,
    UpdateStatus? status,
    bool? isSupported,
    bool? isDownloaded,
    String? localPath,
  }) {
    return AppRelease(
      version: version ?? this.version,
      abi: abi ?? this.abi,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      status: status ?? this.status,
      isSupported: isSupported ?? this.isSupported,
      isDownloaded: isDownloaded ?? this.isDownloaded,
      localPath: localPath ?? this.localPath,
    );
  }
}
