import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Appearance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return Column(
                children: [
                  ListTile(
                    title: const Text('Theme Mode'),
                    subtitle: Text(
                      themeProvider.themeMode.name.capitalize(),
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showThemeModeDialog(context, themeProvider),
                  ),
                  const Divider(),
                  ListTile(
                    title: const Text('App Color Theme'),
                    subtitle: Text(themeProvider.themeColor.name),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => _showThemeColorDialog(context, themeProvider),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showThemeModeDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select Theme Mode'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: ThemeMode.values.map((mode) {
              return RadioListTile<ThemeMode>(
                title: Text(mode.name.capitalize()),
                value: mode,
                groupValue: themeProvider.themeMode,
                onChanged: (value) {
                  if (value != null) {
                    themeProvider.setThemeMode(value);
                  }
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showThemeColorDialog(BuildContext context, ThemeProvider themeProvider) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Select App Color Theme'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: AppThemeColor.values.map((colorTheme) {
                return RadioListTile<AppThemeColor>(
                  title: Text(colorTheme.name),
                  value: colorTheme,
                  groupValue: themeProvider.themeColor,
                  secondary: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colorTheme.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  onChanged: (value) {
                    if (value != null) {
                      themeProvider.setThemeColor(value);
                    }
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
