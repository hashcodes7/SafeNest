enum ReleaseStatus {
  installed,
  upgrade,
  downgrade,
  unsupported,
}

class AppRelease {
  final String version;
  final String abi;
  final String downloadUrl;
  final ReleaseStatus status;
  final bool isSupported;
  final bool downloaded;
  final String? localPath;

  AppRelease({
    required this.version,
    required this.abi,
    required this.downloadUrl,
    required this.status,
    required this.isSupported,
    this.downloaded = false,
    this.localPath,
  });

  AppRelease copyWith({
    String? version,
    String? abi,
    String? downloadUrl,
    ReleaseStatus? status,
    bool? isSupported,
    bool? downloaded,
    String? localPath,
  }) {
    return AppRelease(
      version: version ?? this.version,
      abi: abi ?? this.abi,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      status: status ?? this.status,
      isSupported: isSupported ?? this.isSupported,
      downloaded: downloaded ?? this.downloaded,
      localPath: localPath ?? this.localPath,
    );
  }
}
