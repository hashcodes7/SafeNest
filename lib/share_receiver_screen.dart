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
  bool _isTextExpanded = false;

  Widget _buildExpandableText(String text, TextStyle? style) {
    if (text.length <= 200 || _isTextExpanded) {
      return Text(text, style: style);
    } else {
      return Text('${text.substring(0, 200)}...', style: style);
    }
  }

  static const List<IconData> predefinedIcons = [
    Icons.folder,
    Icons.star,
    Icons.favorite,
    Icons.work,
    Icons.home,
    Icons.music_note,
    Icons.camera,
    Icons.book,
    Icons.pets,
    Icons.flight,
    Icons.train,
    Icons.directions_car,
    Icons.shopping_cart,
    Icons.restaurant,
    Icons.local_cafe,
    Icons.local_bar,
    Icons.lock,
    Icons.shield,
    Icons.key,
    Icons.wallet,
    Icons.notes,
    Icons.article,
    Icons.code,
    Icons.build,
  ];

  void _showCollectionDialog(BuildContext context, UserProvider provider) {
    final nameController = TextEditingController();
    int? selectedIconCodePoint;
    bool isLocked = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('New Collection'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Collection Name',
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Vault Lock (Biometric)',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Switch(
                          value: isLocked,
                          onChanged: (val) {
                            setState(() {
                              isLocked = val;
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Select an Icon (Optional)',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Flexible(
                      child: GridView.builder(
                        shrinkWrap: true,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 6,
                              crossAxisSpacing: 8,
                              mainAxisSpacing: 8,
                            ),
                        itemCount: predefinedIcons.length,
                        itemBuilder: (context, index) {
                          final iconData = predefinedIcons[index];
                          final isSelected =
                              selectedIconCodePoint == iconData.codePoint;
                          return InkWell(
                            onTap: () {
                              setState(() {
                                selectedIconCodePoint = iconData.codePoint;
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(
                                        context,
                                      ).colorScheme.primaryContainer
                                    : null,
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected
                                    ? Border.all(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        width: 2,
                                      )
                                    : null,
                              ),
                              child: Icon(
                                iconData,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      provider.addCollection(
                        name,
                        iconCodePoint: selectedIconCodePoint,
                        isLocked: isLocked,
                      );
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

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
        r'(?:(?:https?|ftp):\/\/)?[\w/\-?=%.]+\.[\w/\-?=%.]+',
      );
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
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Save Shared Link')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: Theme.of(
                        context,
                      ).colorScheme.primaryContainer.withOpacity(0.3),
                    ),
                    child: Column(
                      children: [
                        if (_thumbnailUrl != null)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(16),
                            ),
                            child: Image.network(
                              _thumbnailUrl!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  const SizedBox(
                                    height: 200,
                                    child: Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        size: 50,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildExpandableText(
                                _title,
                                const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 8),
                              if (_description.isNotEmpty)
                                _buildExpandableText(_description, null),
                              const SizedBox(height: 8),
                              if (_url.isNotEmpty)
                                Text(
                                  _url,
                                  style: const TextStyle(color: Colors.blue),
                                ),
                              if (_title.length > 200 ||
                                  _description.length > 200)
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _isTextExpanded = !_isTextExpanded;
                                      });
                                    },
                                    child: Text(
                                      _isTextExpanded
                                          ? 'Show Less'
                                          : 'Show More',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: const Text(
                      'Select Collection to Save to:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Consumer<UserProvider>(
                    builder: (context, provider, child) {
                      final collections =
                          provider.currentUser?.collections ?? [];

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: collections.length + 1,
                        itemBuilder: (context, index) {
                          // LAST ITEM → ADD COLLECTION BUTTON
                          if (index == collections.length) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: InkWell(
                                onTap: () =>
                                    _showCollectionDialog(context, provider),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.4),
                                      style: BorderStyle.solid,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add_circle,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Create New Collection",
                                        style: TextStyle(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }

                          // NORMAL COLLECTION TILE
                          final collection = collections[index];

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Icon(
                                collection.iconCodePoint != null
                                    ? IconData(
                                        collection.iconCodePoint!,
                                        fontFamily: 'MaterialIcons',
                                      )
                                    : Icons.folder,
                                size: 32,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              title: Text(collection.collectionName),
                              onTap: () =>
                                  _saveToCollection(collection.collectionId),
                              trailing: const Icon(Icons.chevron_right),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }
}
