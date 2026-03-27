import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'theme_provider.dart';
import 'home_screen.dart';
import 'first_time_screen.dart';
import 'providers/user_provider.dart';
import 'share_receiver_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
      ],
      child: const SafeNestApp(),
    ),
  );
}

class SafeNestApp extends StatefulWidget {
  const SafeNestApp({super.key});

  @override
  State<SafeNestApp> createState() => _SafeNestAppState();
}

class _SafeNestAppState extends State<SafeNestApp> {
  late StreamSubscription _intentDataStreamSubscription;
  List<SharedMediaFile>? _sharedFiles;

  @override
  void initState() {
    super.initState();
    // Listen to media sharing incoming links while the app is in the memory (Background)
    _intentDataStreamSubscription = ReceiveSharingIntent.instance
        .getMediaStream()
        .listen((List<SharedMediaFile> value) {
          if (value.isNotEmpty) {
            setState(() {
              _sharedFiles = value;
            });
          }
        }, onError: (err) {});

    // Get the media sharing incoming intent if app is opened fresh from closed state
    ReceiveSharingIntent.instance.getInitialMedia().then((
      List<SharedMediaFile> value,
    ) {
      if (value.isNotEmpty) {
        setState(() {
          _sharedFiles = value;
        });
      }
    });
  }

  @override
  void dispose() {
    _intentDataStreamSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'SafeNest',
          themeMode: themeProvider.themeMode,
          theme: themeProvider.lightTheme,
          darkTheme: themeProvider.darkTheme,
          home: _sharedFiles != null && _sharedFiles!.isNotEmpty
              ? ShareReceiverScreen(sharedFiles: _sharedFiles!)
              : const RootScreen(),
        );
      },
    );
  }
}

class RootScreen extends StatelessWidget {
  const RootScreen({super.key});

  Future<bool> alreadyLoggedin() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name');
    final isLoggedIn = prefs.getBool('is_logged_in') ?? true;

    if (!isLoggedIn) return false;
    return name != null && name.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: alreadyLoggedin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) {
          return const HomeScreen();
        } else {
          return const FirstTimeScreen();
        }
      },
    );
  }
}
