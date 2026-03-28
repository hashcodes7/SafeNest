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

  @override
  void initState() {
    super.initState();
    _loadReleases();
  }

  Future<void> _loadReleases() async {
    setState(() => _isLoading = true);
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
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleAction(AppRelease release) async {
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
    });

    _updateService.downloadApk(
      url: release.downloadUrl,
      version: release.version,
      onProgress: (progress) {
        setState(() => _downloadProgress = progress);
      },
      onComplete: (path) async {
        setState(() => _isDownloading = false);
        await _loadReleases(); // Refresh status
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
        SnackbarHelper.showError(context, 'Error', 'Could not open installer: $e');
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
                          const Icon(Icons.update_disabled, size: 64, color: Colors.grey),
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
                  : ListView.builder(
                      itemCount: _releases.length,
                      padding: const EdgeInsets.all(16),
                      itemBuilder: (context, index) {
                        final release = _releases[index];
                        return _buildReleaseItem(release);
                      },
                    ),
        ),
        if (_isDownloading) _buildDownloadOverlay(),
      ],
    );
  }

  Widget _buildReleaseItem(AppRelease release) {
    Color statusColor;
    String statusText;
    String buttonText;
    IconData buttonIcon;

    switch (release.status) {
      case ReleaseStatus.upgrade:
        statusColor = Colors.green;
        statusText = 'New Update Available';
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
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'SafeNest ${release.version}',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (release.downloaded)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _startDownload(release),
                      icon: const Icon(Icons.redo),
                      label: const Text('Re-download'),
                    ),
                  ),
                if (release.downloaded) const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _handleAction(release),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: release.status == ReleaseStatus.upgrade
                          ? Colors.green
                          : release.status == ReleaseStatus.downgrade
                              ? Colors.red
                              : null,
                      foregroundColor: release.status != ReleaseStatus.installed
                          ? Colors.white
                          : null,
                    ),
                    icon: Icon(buttonIcon),
                    label: Text(buttonText),
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
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
