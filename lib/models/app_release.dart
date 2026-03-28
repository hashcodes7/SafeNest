enum ReleaseStatus {
  installed,
  upgrade,
  downgrade,
}

class AppRelease {
  final String version;
  final String downloadUrl;
  final ReleaseStatus status;
  final bool downloaded;
  final String? localPath;

  AppRelease({
    required this.version,
    required this.downloadUrl,
    required this.status,
    this.downloaded = false,
    this.localPath,
  });

  AppRelease copyWith({
    String? version,
    String? downloadUrl,
    ReleaseStatus? status,
    bool? downloaded,
    String? localPath,
  }) {
    return AppRelease(
      version: version ?? this.version,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      status: status ?? this.status,
      downloaded: downloaded ?? this.downloaded,
      localPath: localPath ?? this.localPath,
    );
  }
}
