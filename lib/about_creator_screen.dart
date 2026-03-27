import 'package:flutter/material.dart';

class AboutCreatorScreen extends StatelessWidget {
  const AboutCreatorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About the Creator')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person_pin, size: 60, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              'Harsh', 
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'Welcome to SafeNest! This application was built to provide a secure, powerful, and entirely offline solution for tracking your custom collections, lists, and deep-linked internet shares.\n\n'
              'More details about the creator will be added here soon.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
