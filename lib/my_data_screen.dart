import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';

import 'package:local_auth/local_auth.dart';

import 'providers/user_provider.dart';

class MyDataScreen extends StatefulWidget {
  const MyDataScreen({super.key});

  @override
  State<MyDataScreen> createState() => _MyDataScreenState();
}

class _MyDataScreenState extends State<MyDataScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  String _jsonData = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final user = Provider.of<UserProvider>(context, listen: false).currentUser;
    if (user != null) {
      final jsonMap = user.toJson();
      const encoder = JsonEncoder.withIndent('  ');
      final jsonString = encoder.convert(jsonMap);
      
      setState(() {
        _jsonData = jsonString;
        _isLoading = false;
      });
    } else {
      setState(() {
        _jsonData = '{}';
        _isLoading = false;
      });
    }
  }

  Future<void> _exportData() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (canAuthenticate) {
        final authenticated = await _auth.authenticate(
          localizedReason: 'Please verify your identity to export secure data',
        );
        if (!authenticated) return;
      }

      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/safenest_backup.json');
      await file.writeAsString(_jsonData);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'SafeNest Backup Export',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error exporting data: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Data')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SingleChildScrollView(
              child: SelectableText(
                _jsonData,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _exportData,
        icon: const Icon(Icons.download),
        label: const Text('Export JSON'),
      ),
    );
  }
}
