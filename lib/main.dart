import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme_provider.dart';
import 'home_screen.dart';
import 'first_time_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const SafeNestApp(),
    ),
  );
}

class SafeNestApp extends StatelessWidget {
  const SafeNestApp({super.key});

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
          home: const RootScreen(),
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
    return name != null && name.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: alreadyLoggedin(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.background,
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
