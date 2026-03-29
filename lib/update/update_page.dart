import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:open_filex/open_filex.dart';
import 'package:permission_handler/permission_handler.dart';

import 'update_model.dart';
import 'update_service.dart';
import 'apk_downloader.dart';

class UpdatePage extends StatefulWidget {
  const UpdatePage({super.key});

  @override
  State<UpdatePage> createState() => _UpdatePageState();
}

class _UpdatePageState extends State<UpdatePage> {
  final UpdateService _updateService = UpdateService();
  final ApkDownloader _apkDownloader = ApkDownloader();
  
  List<AppRelease> _releases = [];
  bool _isLoading = true;
  String? _error;

  // Track download progress for each release
  // Key: downloadUrl (or unique version+abi)
  final Map<String, double> _downloadProgress = {};
  final Map<String, bool> _isDownloading = {};

  @override
  void initState() {
    super.initState();
    _loadReleases();
  }

  Future<void> _loadReleases() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final releases = await _updateService.fetchReleases();
      setState(() {
        _releases = releases;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to fetch updates: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _handleDownload(AppRelease release) async {
    final key = release.downloadUrl;

    setState(() {
      _isDownloading[key] = true;
      _downloadProgress[key] = 0;
    });

    final fileName = "safenest_${release.version}_${release.abi}.apk";

    await _apkDownloader.download(
      url: release.downloadUrl,
      fileName: fileName,
      onProgress: (progress) {
        setState(() {
          _downloadProgress[key] = progress;
        });
      },
      onComplete: (path) async {
        setState(() {
          _isDownloading[key] = false;
          _downloadProgress.remove(key);
        });
        
        // Refresh releases to update 'isDownloaded' and 'localPath'
        await _loadReleases();
        
        // Trigger installation
        await _installApk(path);
      },
      onError: (error) {
        setState(() {
          _isDownloading[key] = false;
          _downloadProgress.remove(key);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Download failed: $error'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      },
    );
  }

  Future<void> _installApk(String path) async {
    // Check permission
    if (await Permission.requestInstallPackages.request().isGranted) {
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Installation failed: ${result.message}')),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Permission to install packages denied.')),
        );
      }
    }
  }

  void _cancelDownload(AppRelease release) {
    _apkDownloader.cancel();
    setState(() {
      final key = release.downloadUrl;
      _isDownloading[key] = false;
      _downloadProgress.remove(key);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Check for Updates',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadReleases,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildErrorState()
              : _releases.isEmpty
                  ? _buildEmptyState()
                  : _buildReleaseList(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 60, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Text(_error!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _loadReleases, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.update_disabled, size: 60, color: Colors.grey),
          SizedBox(height: 16),
          Text('No releases found in the repository.'),
        ],
      ),
    );
  }

  Widget _buildReleaseList() {
    return ListView.builder(
      itemCount: _releases.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final release = _releases[index];
        return _buildReleaseItem(release);
      },
    );
  }

  Widget _buildReleaseItem(AppRelease release) {
    final key = release.downloadUrl;
    final isDownloading = _isDownloading[key] ?? false;
    final progress = _downloadProgress[key] ?? 0;

    Color statusColor;
    String statusLabel;
    bool showButton = true;
    bool isButtonEnabled = true;

    switch (release.status) {
      case UpdateStatus.update:
        statusColor = Colors.green;
        statusLabel = 'Update Available';
        break;
      case UpdateStatus.downgrade:
        statusColor = Colors.orange;
        statusLabel = 'Downgrade';
        break;
      case UpdateStatus.installed:
        statusColor = Colors.blue;
        statusLabel = 'Installed';
        break;
      case UpdateStatus.unsupported:
        statusColor = Colors.grey;
        statusLabel = 'Unsupported';
        isButtonEnabled = false;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'v${release.version}',
                      style: GoogleFonts.outfit(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      release.abi,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            if (isDownloading) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: LinearProgressIndicator(
                      value: progress,
                      borderRadius: BorderRadius.circular(8),
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text('${(progress * 100).toStringAsFixed(0)}%'),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _cancelDownload(release),
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel Download'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ] else if (showButton) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isButtonEnabled
                      ? () {
                          if (release.isDownloaded && release.localPath != null) {
                            _installApk(release.localPath!);
                          } else {
                            _handleDownload(release);
                          }
                        }
                      : null,
                  icon: Icon(
                    release.isDownloaded
                        ? Icons.install_mobile
                        : release.status == UpdateStatus.installed
                            ? Icons.refresh
                            : Icons.download,
                  ),
                  label: Text(
                    release.isDownloaded
                        ? 'Install'
                        : release.status == UpdateStatus.installed
                            ? 'Reinstall'
                            : release.status == UpdateStatus.downgrade
                                ? 'Downgrade'
                                : 'Update Now',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    backgroundColor: release.status == UpdateStatus.update
                        ? Colors.green
                        : release.status == UpdateStatus.downgrade
                            ? Colors.orange
                            : null,
                    foregroundColor: (release.status == UpdateStatus.update || release.status == UpdateStatus.downgrade)
                        ? Colors.white
                        : null,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
