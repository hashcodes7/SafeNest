import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

import 'providers/user_provider.dart';
import 'home_screen.dart'; 

class ShareReceiverScreen extends StatefulWidget {
  final List<SharedMediaFile> sharedFiles;

  const ShareReceiverScreen({super.key, required this.sharedFiles});

  @override
  State<ShareReceiverScreen> createState() => _ShareReceiverScreenState();
}

class _ShareReceiverScreenState extends State<ShareReceiverScreen> {
  bool _isLoading = true;
  String _url = '';
  String _title = 'Discovered Link';
  String _description = '';
  String? _thumbnailUrl;

  @override
  void initState() {
    super.initState();
    _parseIntent();
  }

  Future<void> _parseIntent() async {
    if (widget.sharedFiles.isNotEmpty) {
      final sharedItem = widget.sharedFiles.first;
      String rawText = sharedItem.path; 

      final RegExp urlRegExp = RegExp(
          r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+');
      Iterable<RegExpMatch> matches = urlRegExp.allMatches(rawText);
      
      if (matches.isNotEmpty) {
        _url = rawText.substring(matches.first.start, matches.first.end);
        if (!_url.startsWith('http')) {
          _url = 'https://$_url';
        }
        
        try {
          var data = await MetadataFetch.extract(_url);
          if (data != null) {
            _title = data.title ?? 'Discovered Link';
            _description = data.description ?? '';
            _thumbnailUrl = data.image;
          }
        } catch (e) {
          // completely offline or error catching gracefully natively
          _title = rawText;
        }
      } else {
        _title = rawText;
      }
    }
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _saveToCollection(String collectionId) {
    Provider.of<UserProvider>(context, listen: false).addField(
      collectionId,
      _title,
      _url.isNotEmpty ? _url : null,
      _description.isNotEmpty ? _description : null,
      thumbnailUrl: _thumbnailUrl,
    );
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()), 
      (route) => false
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Save Shared Link')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                ),
                child: Column(
                  children: [
                    if (_thumbnailUrl != null)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(
                          _thumbnailUrl!,
                          width: double.infinity,
                          height: 200,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox(
                            height: 200,
                            child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 8),
                          if (_description.isNotEmpty)
                            Text(_description, maxLines: 2, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          if (_url.isNotEmpty)
                            Text(_url, style: const TextStyle(color: Colors.blue)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Select Collection to Save to:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Consumer<UserProvider>(
                  builder: (context, provider, child) {
                    final collections = provider.currentUser?.collections ?? [];
                    if (collections.isEmpty) {
                      return const Center(child: Text("You don't have any collections yet. Please create one in the app first."));
                    }
                    return ListView.builder(
                      itemCount: collections.length,
                      itemBuilder: (context, index) {
                        final collection = collections[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: Icon(
                              collection.iconCodePoint != null
                                  ? IconData(collection.iconCodePoint!, fontFamily: 'MaterialIcons')
                                  : Icons.folder,
                              size: 32,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            title: Text(collection.collectionName),
                            onTap: () => _saveToCollection(collection.collectionId),
                            trailing: const Icon(Icons.chevron_right),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
        ),
    );
  }
}
