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
    // Group releases by version
    final Map<String, List<AppRelease>> groupedReleases = {};
    for (var release in _releases) {
      groupedReleases.putIfAbsent(release.version, () => []).add(release);
    }

    final versions = groupedReleases.keys.toList();

    return ListView.builder(
      itemCount: versions.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final version = versions[index];
        final releases = groupedReleases[version]!;
        return _buildVersionGroup(version, releases);
      },
    );
  }

  Widget _buildVersionGroup(String version, List<AppRelease> releases) {
    // Check if any release in this version is installed
    final isInstalled = releases.any((r) => r.status == UpdateStatus.installed);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        title: Text(
          'v$version',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isInstalled)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'Installed',
                  style: TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          const Divider(height: 1, indent: 16, endIndent: 16),
          ...releases.map((release) => _buildAbiItem(release)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildAbiItem(AppRelease release) {
    final key = release.downloadUrl;
    final isDownloading = _isDownloading[key] ?? false;
    final progress = _downloadProgress[key] ?? 0;

    Color statusColor;
    String statusLabel;
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
        statusLabel = 'Current Version';
        break;
      case UpdateStatus.unsupported:
        statusColor = Colors.grey;
        statusLabel = 'Unsupported';
        isButtonEnabled = false;
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      release.abi,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (isDownloading)
                const SizedBox.shrink() // Progress bar handles actions below
              else
                SizedBox(
                  height: 36,
                  child: ElevatedButton(
                    onPressed: isButtonEnabled
                        ? () {
                            if (release.isDownloaded && release.localPath != null) {
                              _installApk(release.localPath!);
                            } else {
                              _handleDownload(release);
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      elevation: 0,
                      backgroundColor: release.status == UpdateStatus.update
                          ? Colors.green
                          : release.status == UpdateStatus.downgrade
                              ? Colors.orange
                              : Theme.of(context).colorScheme.primaryContainer,
                      foregroundColor: (release.status == UpdateStatus.update ||
                              release.status == UpdateStatus.downgrade)
                          ? Colors.white
                          : Theme.of(context).colorScheme.onPrimaryContainer,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      release.isDownloaded
                          ? 'Install'
                          : release.status == UpdateStatus.installed
                              ? 'Reinstall'
                              : release.status == UpdateStatus.downgrade
                                  ? 'Downgrade'
                                  : 'Get Update',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          if (isDownloading) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: LinearProgressIndicator(
                    value: progress,
                    borderRadius: BorderRadius.circular(8),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _cancelDownload(release),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
