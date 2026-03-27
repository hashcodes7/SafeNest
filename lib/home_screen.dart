import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'settings_screen.dart';
import 'providers/user_provider.dart';
import 'models/collection.dart';
import 'collection_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _showCollectionDialog(BuildContext context, UserProvider provider, {Collection? collection}) {
    final nameController = TextEditingController(text: collection?.collectionName);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(collection == null ? 'New Collection' : 'Edit Collection'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Collection Name'),
            autofocus: true,
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
                  if (collection == null) {
                    provider.addCollection(name);
                  } else {
                    provider.editCollection(collection.collectionId, name);
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeNest'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: Text(
                'SafeNest',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SettingsScreen()),
                );
              },
            ),
          ],
        ),
      ),
      body: Consumer<UserProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          final user = provider.currentUser;
          if (user == null) {
            return const Center(child: Text('Error loading user data.'));
          }

          final collections = user.collections;

          if (collections.isEmpty) {
            return const Center(
              child: Text(
                'No collections yet.\nTap the + button to create one!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: collections.length,
            itemBuilder: (context, index) {
              final collection = collections[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                clipBehavior: Clip.antiAlias,
                elevation: 2,
                child: Dismissible(
                  key: Key(collection.collectionId),
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
                          title: const Text('Delete Collection'),
                          content: const Text('Are you sure you want to delete this collection and all its fields?'),
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
                        provider.deleteCollection(collection.collectionId);
                      }
                      return delete;
                    } else if (direction == DismissDirection.endToStart) {
                      // Swipe Left -> Edit
                      _showCollectionDialog(context, provider, collection: collection);
                      return false; // Prevent dismiss
                    }
                    return false;
                  },
                  child: ListTile(
                    leading: const Icon(Icons.folder, size: 36),
                    title: Text(collection.collectionName),
                    subtitle: Text('${collection.fields.length} fields'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CollectionScreen(collectionId: collection.collectionId),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Consumer<UserProvider>(
        builder: (context, provider, child) {
          return FloatingActionButton(
            onPressed: () => _showCollectionDialog(context, provider),
            child: const Icon(Icons.add),
          );
        },
      ),
    );
  }
}
