import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';

import 'settings_screen.dart';
import 'providers/user_provider.dart';
import 'models/collection.dart';
import 'collection_screen.dart';
import 'my_data_screen.dart';
import 'about_creator_screen.dart';
import 'profile_screen.dart';
import 'utils/snackbar_helper.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  final LocalAuthentication _auth = LocalAuthentication();
  String _searchQuery = '';

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

  Future<bool> _authenticate() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) {
        return true; // Bypass if device physically cannot authenticate
      }

      return await _auth.authenticate(
        localizedReason: 'Unlock your collection to proceed',
      );
    } catch (e) {
      return false;
    }
  }

  void _showCollectionDialog(
    BuildContext context,
    UserProvider provider, {
    Collection? collection,
  }) {
    final nameController = TextEditingController(
      text: collection?.collectionName,
    );
    int? selectedIconCodePoint = collection?.iconCodePoint;
    bool isLocked = collection?.isLocked ?? false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                collection == null ? 'New Collection' : 'Edit Collection',
              ),
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
                      if (collection == null) {
                        provider.addCollection(
                          name,
                          iconCodePoint: selectedIconCodePoint,
                          isLocked: isLocked,
                        );
                        if (context.mounted) {
                          SnackbarHelper.showSuccess(
                            context,
                            'Created',
                            'Collection $name created successfully!',
                          );
                        }
                      } else {
                        provider.editCollection(
                          collection.collectionId,
                          name,
                          iconCodePoint: selectedIconCodePoint,
                          isLocked: isLocked,
                        );
                        if (context.mounted) {
                          SnackbarHelper.showInfo(
                            context,
                            'Updated',
                            'Collection updated successfully!',
                          );
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SafeNest')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            Consumer<UserProvider>(
              builder: (context, provider, child) {
                final user = provider.currentUser;
                return DrawerHeader(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.tertiary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimary.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/logo.png',
                          height: 48,
                          errorBuilder: (c, e, s) => const Icon(
                            Icons.security,
                            size: 48,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'SafeNest Vault',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (user != null)
                        Text(
                          'Secured locally for ${user.userName}',
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onPrimary.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.data_object),
              title: const Text('My Data'),
              onTap: () async {
                final authenticated = await _authenticate();
                if (authenticated && context.mounted) {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const MyDataScreen(),
                    ),
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('About the Creator'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutCreatorScreen(),
                  ),
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

          var collections = user.collections;

          // Global Search Logic
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            collections = collections.where((c) {
              final titleMatch = c.collectionName.toLowerCase().contains(query);
              final fieldMatch = c.fields.any(
                (f) =>
                    f.fieldName.toLowerCase().contains(query) ||
                    (f.description?.toLowerCase().contains(query) ?? false) ||
                    (f.url?.toLowerCase().contains(query) ?? false),
              );
              return titleMatch || fieldMatch;
            }).toList();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(
                  'Welcome, ${user.userName}',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  textInputAction: TextInputAction.search,
                  onTapOutside: (event) {
                    FocusManager.instance.primaryFocus?.unfocus();
                  },
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search collections, apps, URLs...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: collections.isEmpty
                    ? const Center(
                        child: Text(
                          'No collections found.\nTap the + button to create one!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 18),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: collections.length,
                        itemBuilder: (context, index) {
                          final collection = collections[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                              side: BorderSide(
                                color: Theme.of(
                                  context,
                                ).colorScheme.outlineVariant.withOpacity(0.5),
                                width: 1,
                              ),
                            ),
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerLow,
                            clipBehavior: Clip.antiAlias,
                            elevation: 0,
                            child: Dismissible(
                              key: Key(collection.collectionId),
                              direction: DismissDirection.horizontal,
                              background: Container(
                                color: Theme.of(
                                  context,
                                ).colorScheme.errorContainer,
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Icon(
                                  Icons.delete_sweep_rounded,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onErrorContainer,
                                  size: 28,
                                ),
                              ),
                              secondaryBackground: Container(
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondaryContainer,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                ),
                                child: Icon(
                                  Icons.edit_rounded,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSecondaryContainer,
                                  size: 28,
                                ),
                              ),
                              confirmDismiss: (direction) async {
                                if (collection.isLocked) {
                                  final authenticated = await _authenticate();
                                  if (!authenticated) return false;
                                }

                                if (direction == DismissDirection.startToEnd) {
                                  bool delete = false;
                                  await showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(24),
                                      ),
                                      title: const Text(
                                        'Delete Collection',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      content: const Text(
                                        'Are you sure you want to delete this collection and all its fields?',
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
                                            style: TextStyle(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.error,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (delete) {
                                    provider.deleteCollection(
                                      collection.collectionId,
                                    );
                                    if (context.mounted) {
                                      SnackbarHelper.showError(
                                        context,
                                        'Deleted',
                                        'Collection deleted successfully.',
                                      );
                                    }
                                  }
                                  return delete;
                                } else if (direction ==
                                    DismissDirection.endToStart) {
                                  _showCollectionDialog(
                                    context,
                                    provider,
                                    collection: collection,
                                  );
                                  return false;
                                }
                                return false;
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.primaryContainer,
                                    child: Icon(
                                      collection.iconCodePoint != null
                                          ? IconData(
                                              collection.iconCodePoint!,
                                              fontFamily: 'MaterialIcons',
                                            )
                                          : Icons.folder_rounded,
                                      size: 28,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                  title: Text(
                                    collection.collectionName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 18,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${collection.fields.length} file${collection.fields.length == 1 ? '' : 's'}',
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  trailing: collection.isLocked
                                      ? Icon(
                                          Icons.lock_rounded,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant
                                              .withOpacity(0.5),
                                        )
                                      : const Icon(Icons.chevron_right_rounded),
                                  onTap: () async {
                                    if (collection.isLocked) {
                                      final authenticated =
                                          await _authenticate();
                                      if (!authenticated) return;
                                    }
                                    if (mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              CollectionScreen(
                                                collectionId:
                                                    collection.collectionId,
                                              ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
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
