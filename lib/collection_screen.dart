import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


import 'models/field.dart';
import 'providers/user_provider.dart';

class CollectionScreen extends StatelessWidget {
  final String collectionId;

  const CollectionScreen({super.key, required this.collectionId});

  void _showFieldDialog(BuildContext context, UserProvider provider, {Field? field}) {
    final nameController = TextEditingController(text: field?.fieldName);
    final urlController = TextEditingController(text: field?.url);
    final dataController = TextEditingController(text: field?.data);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(field == null ? 'New Field' : 'Edit Field'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Field Name (Required)'),
                ),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(labelText: 'URL (Optional)'),
                ),
                TextField(
                  controller: dataController,
                  decoration: const InputDecoration(labelText: 'Data (Optional)'),
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
                final url = urlController.text.trim().isEmpty ? null : urlController.text.trim();
                final data = dataController.text.trim().isEmpty ? null : dataController.text.trim();

                if (name.isNotEmpty) {
                  if (field == null) {
                    provider.addField(collectionId, name, url, data);
                  } else {
                    provider.editField(collectionId, field.fieldId, name, url, data);
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
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final collectionIndex = user.collections.indexWhere((c) => c.collectionId == collectionId);
        if (collectionIndex == -1) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: const Center(child: Text('Collection not found.')),
          );
        }

        final collection = user.collections[collectionIndex];
        final fields = collection.fields;

        return Scaffold(
          appBar: AppBar(
            title: Text(collection.collectionName),
          ),
          body: fields.isEmpty
              ? const Center(child: Text('No fields yet. Create one!'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: fields.length,
                  itemBuilder: (context, index) {
                    final field = fields[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.antiAlias,
                      elevation: 2,
                      child: Dismissible(
                        key: Key(field.fieldId),
                        direction: DismissDirection.horizontal,
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        secondaryBackground: Container(
                          color: Colors.blue,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.edit, color: Colors.white),
                        ),
                        confirmDismiss: (direction) async {
                          if (direction == DismissDirection.startToEnd) {
                            // Swipe Right -> Delete
                            bool delete = false;
                            await showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Field'),
                                content: const Text('Are you sure you want to delete this field?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                                  TextButton(
                                    onPressed: () {
                                      delete = true;
                                      Navigator.pop(ctx);
                                    },
                                    child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                            if (delete) {
                              provider.deleteField(collectionId, field.fieldId);
                            }
                            return delete;
                          } else if (direction == DismissDirection.endToStart) {
                            // Swipe Left -> Edit
                            _showFieldDialog(context, provider, field: field);
                            return false; // Prevent dismiss, just show dialog
                          }
                          return false;
                        },
                        child: ListTile(
                          title: Text(field.fieldName),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (field.url != null) Text('URL: ${field.url}', style: const TextStyle(fontSize: 12)),
                              if (field.data != null) Text('Data: ${field.data}', style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
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
