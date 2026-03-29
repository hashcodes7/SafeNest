import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_selector/file_selector.dart';

import 'providers/user_provider.dart';
import 'utils/snackbar_helper.dart';
import 'utils/auth_helper.dart';
import 'home_screen.dart';

class MyDataScreen extends StatefulWidget {
  const MyDataScreen({super.key});

  @override
  State<MyDataScreen> createState() => _MyDataScreenState();
}

class _MyDataScreenState extends State<MyDataScreen> {
  String _jsonData = '';
  bool _isLoading = true;
  bool _isEditing = false;
  final TextEditingController _textController = TextEditingController();

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

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
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/safenest_backup.json');
      await file.writeAsString(_jsonData);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'SafeNest Backup Export',
      );
      if (mounted) {
        SnackbarHelper.showInfo(context, 'Exported', 'Data prepared for export!');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Export Failed', e.toString());
      }
    }
  }

  Future<void> _importJsonFromFile() async {
    try {
      const XTypeGroup typeGroup = XTypeGroup(
        label: 'json',
        extensions: <String>['json'],
      );
      final XFile? result = await openFile(acceptedTypeGroups: <XTypeGroup>[typeGroup]);
      
      if (result != null) {
        final String jsonContent = await result.readAsString();
        
        if (mounted) {
           _showImportOptions(jsonContent);
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.showError(context, 'Import Failed', 'Could not read file: $e');
      }
    }
  }

  void _showImportOptions(String jsonContent) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Import JSON'),
        content: const Text('How would you like to import this vault data?'),
        actions: [
          TextButton(
             onPressed: () => Navigator.pop(ctx),
             child: const Text('Cancel'),
          ),
          TextButton(
             onPressed: () async {
                final navigator = Navigator.of(context);
                final provider = Provider.of<UserProvider>(context, listen: false);
                if (await AuthHelper.authenticate(context)) {
                  if (!mounted) return;
                  try {
                    await provider.importAndMergeFromJson(jsonContent);
                    if (!mounted) return;
                    SnackbarHelper.showInfo(context, 'Imported', 'Vaults safely merged!');
                    navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
                  } catch (e) {
                    if (!mounted) return;
                    SnackbarHelper.showError(context, 'Invalid Data', e.toString().split('\n').first);
                    navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
                  }
                } else {
                  if (!mounted) return;
                  navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
                }
             },
             child: const Text('Merge'),
          ),
          ElevatedButton(
             style: ElevatedButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.errorContainer),
             onPressed: () async {
                final navigator = Navigator.of(context);
                final provider = Provider.of<UserProvider>(context, listen: false);
                if (await AuthHelper.authenticate(context)) {
                  if (!mounted) return;
                  try {
                    await provider.importFromJson(jsonContent);
                    if (!mounted) return;
                    SnackbarHelper.showInfo(context, 'Replaced', 'Full vault successfully replaced!');
                    navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
                  } catch (e) {
                    if (!mounted) return;
                    SnackbarHelper.showError(context, 'Invalid Data', e.toString().split('\n').first);
                    navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
                  }
                } else {
                  if (!mounted) return;
                  navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const HomeScreen()), (route) => false);
                }
             },
             child: Text('Replace', style: TextStyle(color: Theme.of(ctx).colorScheme.onErrorContainer)),
          ),
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Data'),
        actions: [
          if (!_isLoading && !_isEditing)
             IconButton(
               icon: const Icon(Icons.file_upload),
               tooltip: 'Import JSON',
               onPressed: _importJsonFromFile,
             ),
          if (!_isLoading)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              tooltip: _isEditing ? 'Cancel Editing' : 'Edit JSON',
              onPressed: () async {
                if (_isEditing) {
                  setState(() {
                    _isEditing = false;
                  });
                } else {
                  if (await AuthHelper.authenticate(context)) {
                    setState(() {
                      _textController.text = _jsonData;
                      _isEditing = true;
                    });
                  }
                }
              },
            ),
        ],
      ),
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
            child: _isEditing
                ? TextField(
                    controller: _textController,
                    maxLines: null,
                    expands: true,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    decoration: const InputDecoration(border: InputBorder.none),
                  )
                : SingleChildScrollView(
                    child: SelectableText(
                      _jsonData,
                      style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                    ),
                  ),
          ),
      floatingActionButton: _isLoading
          ? null
          : _isEditing
              ? FloatingActionButton.extended(
                  onPressed: () async {
                    try {
                      final provider = Provider.of<UserProvider>(context, listen: false);
                      await provider.importFromJson(_textController.text);
                      if (!mounted) return;
                      SnackbarHelper.showInfo(context, 'Data Saved', 'Data updated & reloaded successfully!');
                      setState(() {
                        _jsonData = _textController.text;
                        _isEditing = false;
                      });
                    } catch (e) {
                      if (context.mounted) {
                        SnackbarHelper.showError(context, 'Invalid JSON', e.toString().split('\n').first);
                      }
                    }
                  },
                  icon: const Icon(Icons.save),
                  label: const Text('Save & Reload'),
                )
              : FloatingActionButton.extended(
                  onPressed: _exportData,
                  icon: const Icon(Icons.download),
                  label: const Text('Export JSON'),
                ),
    );
  }
}
