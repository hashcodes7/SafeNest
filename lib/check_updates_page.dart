import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/app_release.dart';
import '../services/update_service.dart';
import '../utils/snackbar_helper.dart';

class CheckUpdatesPage extends StatefulWidget {
  const CheckUpdatesPage({super.key});

  @override
  State<CheckUpdatesPage> createState() => _CheckUpdatesPageState();
}

class _CheckUpdatesPageState extends State<CheckUpdatesPage> {
  final UpdateService _updateService = UpdateService();
  List<AppRelease> _releases = [];
  bool _isLoading = true;
  double _downloadProgress = 0;
  bool _isDownloading = false;
  String _downloadingVersion = "";
  String _downloadingAbi = "";

  @override
  void initState() {
    super.initState();
    _loadReleases();
  }

  Future<void> _loadReleases() async {
    setState(() {
      _isLoading = true;
      _releases = [];
    });
    try {
      final releases = await _updateService.fetchReleases();
      setState(() {
        _releases = releases;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Error',
          'Failed to check for updates: $e',
        );
        debugPrint('Error: $e');
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAction(AppRelease release) async {
    if (!release.isSupported) return;

    if (release.downloaded && release.localPath != null) {
      if (File(release.localPath!).existsSync()) {
        await _installApk(release.localPath!);
        return;
      }
    }

    _startDownload(release);
  }

  void _startDownload(AppRelease release) {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
      _downloadingVersion = release.version;
      _downloadingAbi = release.abi;
    });

    _updateService.downloadApk(
      release: release,
      onProgress: (progress) {
        setState(() => _downloadProgress = progress);
      },
      onComplete: (path) async {
        setState(() => _isDownloading = false);
        await _loadReleases(); // Refresh download status logic
        await _installApk(path);
      },
      onError: (error) {
        setState(() => _isDownloading = false);
        SnackbarHelper.showError(context, 'Download Error', error);
      },
    );
  }

  Future<void> _installApk(String path) async {
    try {
      final result = await OpenFilex.open(path);
      if (result.type != ResultType.done) {
        if (mounted) {
          SnackbarHelper.showError(
            context,
            'Installation Error',
            result.message,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(
          context,
          'Error',
          'Could not open installer: $e',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('Check for Updates'),
            actions: [
              IconButton(
                onPressed: _loadReleases,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _releases.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.update_disabled,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          const Text('No updates found in the repository.'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadReleases,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _buildReleaseList(),
        ),
        if (_isDownloading) _buildDownloadOverlay(),
      ],
    );
  }

  Widget _buildReleaseList() {
    // Grouping logic for versions
    Map<String, List<AppRelease>> groupedReleases = {};
    for (var release in _releases) {
      if (!groupedReleases.containsKey(release.version)) {
        groupedReleases[release.version] = [];
      }
      groupedReleases[release.version]!.add(release);
    }

    final sortedVersions = groupedReleases.keys.toList();

    return ListView.builder(
      itemCount: sortedVersions.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final version = sortedVersions[index];
        final versionReleases = groupedReleases[version]!;
        
        // Determine if this version is currently installed
        final isInstalled = versionReleases.any(
            (release) => release.status == ReleaseStatus.installed);

        return Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            title: Text(
              'Version $version',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            trailing: isInstalled 
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.5)),
                  ),
                  child: const Text(
                    'Installed',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                )
              : null,
            childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
            initiallyExpanded: index == 0, // Expand latest version by default
            children: versionReleases.map((release) => _buildReleaseItem(release)).toList(),
          ),
        );
      },
    );
  }

  Widget _buildReleaseItem(AppRelease release) {
    Color statusColor;
    String statusText;
    String buttonText;
    IconData buttonIcon;
    bool isEnabled = true;

    switch (release.status) {
      case ReleaseStatus.upgrade:
        statusColor = Colors.green;
        statusText = 'Supported Update';
        buttonText = release.downloaded ? 'Install' : 'Update';
        buttonIcon = release.downloaded ? Icons.install_mobile : Icons.download;
        break;
      case ReleaseStatus.installed:
        statusColor = Colors.grey;
        statusText = 'Installed';
        buttonText = release.downloaded ? 'Install' : 'Reinstall';
        buttonIcon = release.downloaded ? Icons.install_mobile : Icons.refresh;
        break;
      case ReleaseStatus.downgrade:
        statusColor = Colors.red;
        statusText = 'Older Version';
        buttonText = release.downloaded ? 'Install' : 'Downgrade';
        buttonIcon = release.downloaded ? Icons.install_mobile : Icons.history;
        break;
      case ReleaseStatus.unsupported:
        statusColor = Colors.grey;
        statusText = 'Unsupported';
        buttonText = 'Unsupported';
        buttonIcon = Icons.error_outline;
        isEnabled = false;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: isEnabled ? 1 : 0,
      color: isEnabled ? null : Colors.grey.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      release.abi,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isEnabled ? null : Colors.grey,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                if (release.downloaded && isEnabled)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _startDownload(release),
                      icon: const Icon(Icons.redo, size: 18),
                      label: const Text(
                        'Re-download',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                if (release.downloaded && isEnabled) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isEnabled ? () => _handleAction(release) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: release.status == ReleaseStatus.upgrade
                          ? Colors.green
                          : release.status == ReleaseStatus.downgrade
                              ? Colors.red
                              : null,
                      foregroundColor:
                          isEnabled && release.status != ReleaseStatus.installed
                              ? Colors.white
                              : null,
                    ),
                    icon: Icon(buttonIcon, size: 18),
                    label: Text(
                      buttonText,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadOverlay() {
    return Container(
      color: Colors.black54,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(32),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Downloading SafeNest $_downloadingVersion',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'ABI: $_downloadingAbi',
                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 24),
                LinearProgressIndicator(value: _downloadProgress),
                const SizedBox(height: 16),
                Text('${(_downloadProgress * 100).toStringAsFixed(1)} %'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
