import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:metadata_fetch/metadata_fetch.dart';
import 'package:image_picker/image_picker.dart';

import 'models/field.dart';
import 'providers/user_provider.dart';
import 'utils/snackbar_helper.dart';

class CollectionScreen extends StatelessWidget {
  final String collectionId;

  const CollectionScreen({super.key, required this.collectionId});

  void _showFieldDialog(
    BuildContext context,
    UserProvider provider, {
    Field? field,
  }) {
    final nameController = TextEditingController(text: field?.fieldName);
    final urlController = TextEditingController(text: field?.url);
    final descriptionController = TextEditingController(text: field?.description);
    final thumbnailController = TextEditingController(text: field?.thumbnailUrl);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(field == null ? 'New Field' : 'Edit Field', style: const TextStyle(fontWeight: FontWeight.bold)),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Field Name (Required)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlController,
                  decoration: InputDecoration(
                    labelText: 'URL (Optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: thumbnailController,
                  decoration: InputDecoration(
                    labelText: 'Image URL or Gallery File',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.image_outlined),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.attach_file),
                      tooltip: 'Pick image from gallery',
                      onPressed: () async {
                        final picker = ImagePicker();
                        final pickedFile = await picker.pickImage(source: ImageSource.gallery);
                        if (pickedFile != null) {
                          thumbnailController.text = pickedFile.path;
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descriptionController,
                  minLines: 3,
                  maxLines: 6,
                  decoration: InputDecoration(
                    labelText: 'Description (Optional)',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              onPressed: () {
                final name = nameController.text.trim();
                final url = urlController.text.trim().isEmpty
                    ? null
                    : urlController.text.trim();
                final description = descriptionController.text.trim().isEmpty
                    ? null
                    : descriptionController.text.trim();
                final thumbnailUrl = thumbnailController.text.trim().isEmpty
                    ? null
                    : thumbnailController.text.trim();

                if (name.isNotEmpty) {
                  if (field == null) {
                    provider.addField(collectionId, name, url, description, thumbnailUrl: thumbnailUrl);
                    if (context.mounted) {
                      SnackbarHelper.showSuccess(context, 'Created', 'Field $name created successfully!');
                    }
                  } else {
                    provider.editField(
                      collectionId,
                      field.fieldId,
                      name,
                      url,
                      description,
                      newThumbnailUrl: thumbnailUrl,
                    );
                    if (context.mounted) {
                      SnackbarHelper.showInfo(context, 'Updated', 'Field $name updated successfully!');
                    }
                  }
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<UserProvider>(
      builder: (context, provider, child) {
        final user = provider.currentUser;
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final collectionIndex = user.collections.indexWhere(
          (c) => c.collectionId == collectionId,
        );
        if (collectionIndex == -1) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Collection not found.')),
          );
        }

        final collection = user.collections[collectionIndex];
        final fields = collection.fields;

        return Scaffold(
          appBar: AppBar(title: Text(collection.collectionName)),
          body: fields.isEmpty
              ? const Center(child: Text('No fields yet. Create one!'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: fields.length,
                  itemBuilder: (context, index) {
                    final field = fields[index];
                    return _FieldTile(
                      key: Key(field.fieldId),
                      provider: provider,
                      collectionId: collectionId,
                      field: field,
                      onEdit: () => _showFieldDialog(context, provider, field: field),
                    );
                  },
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showFieldDialog(context, provider),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }
}

class _FieldTile extends StatefulWidget {
  final UserProvider provider;
  final String collectionId;
  final Field field;
  final VoidCallback onEdit;

  const _FieldTile({
    super.key,
    required this.provider,
    required this.collectionId,
    required this.field,
    required this.onEdit,
  });

  @override
  State<_FieldTile> createState() => _FieldTileState();
}

class _FieldTileState extends State<_FieldTile> {
  bool _isExpanded = false;

  Widget _buildExpandableText(String text, TextStyle? style) {
    if (text.length <= 200 || _isExpanded) {
      return Text(text, style: style);
    } else {
      return Text('${text.substring(0, 200)}...', style: style);
    }
  }

  @override
  void initState() {
    super.initState();
    _tryFetchThumbnailIfMissing();
  }

  void _tryFetchThumbnailIfMissing() async {
    final field = widget.field;
    if (field.thumbnailUrl == null && field.url != null && field.url!.startsWith('http')) {
      try {
        var data = await MetadataFetch.extract(field.url!);
        if (data != null && data.image != null && mounted) {
          widget.provider.editField(
            widget.collectionId,
            field.fieldId,
            field.fieldName,
            field.url,
            field.description,
            newThumbnailUrl: data.image,
          );
        }
      } catch (e) {
        // Could be offline or invalid metadata. Fails silently as requested.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final field = widget.field;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: Dismissible(
        key: Key(field.fieldId),
        direction: DismissDirection.horizontal,
        background: Container(
          color: Theme.of(context).colorScheme.errorContainer,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Icon(Icons.delete_sweep_rounded, color: Theme.of(context).colorScheme.onErrorContainer, size: 28),
        ),
        secondaryBackground: Container(
          color: Theme.of(context).colorScheme.secondaryContainer,
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Icon(Icons.edit_rounded, color: Theme.of(context).colorScheme.onSecondaryContainer, size: 28),
        ),
        confirmDismiss: (direction) async {
          if (direction == DismissDirection.startToEnd) {
            bool delete = false;
            await showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                title: const Text('Delete Field', style: TextStyle(fontWeight: FontWeight.bold)),
                content: const Text(
                  'Are you sure you want to delete this field?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      delete = true;
                      Navigator.pop(ctx);
                    },
                    child: Text(
                      'Delete',
                      style: TextStyle(color: Theme.of(context).colorScheme.error, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            );
            if (delete) {
              widget.provider.deleteField(widget.collectionId, field.fieldId);
              if (mounted) {
                SnackbarHelper.showError(context, 'Deleted', 'Field deleted safely.');
              }
            }
            return delete;
          } else if (direction == DismissDirection.endToStart) {
            widget.onEdit();
            return false;
          }
          return false;
        },
        child: Column(
          children: [
            if (field.thumbnailUrl != null)
              Stack(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isExpanded = !_isExpanded;
                      });
                    },
                    child: AnimatedCrossFade(
                      duration: const Duration(milliseconds: 300),
                      crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                      firstChild: field.thumbnailUrl!.startsWith('http')
                        ? Image.network(
                            field.thumbnailUrl!,
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox(
                              height: 180,
                              child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                            ),
                          )
                        : Image.file(
                            File(field.thumbnailUrl!),
                            width: double.infinity,
                            height: 180,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const SizedBox(
                              height: 180,
                              child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                            ),
                          ),
                      secondChild: field.thumbnailUrl!.startsWith('http')
                        ? Image.network(
                            field.thumbnailUrl!,
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const SizedBox(
                              height: 180,
                              child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                            ),
                          )
                        : Image.file(
                            File(field.thumbnailUrl!),
                            width: double.infinity,
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => const SizedBox(
                              height: 180,
                              child: Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                            ),
                          ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.white,
                        ),
                        onPressed: () {
                          setState(() {
                            _isExpanded = !_isExpanded;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: ListTile(
                title: _buildExpandableText(field.fieldName, const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (field.url != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          '${field.url}',
                          style: TextStyle(fontSize: 13, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    if (field.description != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: _buildExpandableText(
                          field.description!,
                          TextStyle(fontSize: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ),
                    if (field.fieldName.length > 200 || (field.description?.length ?? 0) > 200)
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _isExpanded = !_isExpanded;
                            });
                          },
                          child: Text(_isExpanded ? 'Show Less' : 'Show More'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
