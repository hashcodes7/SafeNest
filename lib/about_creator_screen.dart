import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutCreatorScreen extends StatelessWidget {
  const AboutCreatorScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  Widget _buildLinkButton(BuildContext context, IconData icon, String label, String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          minimumSize: const Size(double.infinity, 56),
          backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
          foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
        ),
        onPressed: () => _launchUrl(url),
        icon: Icon(icon, size: 28),
        label: Text(
          label, 
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _showImageViewer(BuildContext context, String assetPath, String tag) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          body: Center(
            child: Hero(
              tag: tag,
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.asset(
                  assetPath,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.person, size: 100, color: Colors.white),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About the Creator')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header with images
            Container(
              height: 280,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withAlpha(128),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 24, right: 12, top: 24, bottom: 24),
                      child: GestureDetector(
                        onTap: () => _showImageViewer(context, 'assets/developer1.jpg', 'dev1'),
                        child: Hero(
                          tag: 'dev1',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/developer1.jpg',
                              fit: BoxFit.cover,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 60),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 24, top: 24, bottom: 24),
                      child: GestureDetector(
                        onTap: () => _showImageViewer(context, 'assets/developer2.jpg', 'dev2'),
                        child: Hero(
                          tag: 'dev2',
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Image.asset(
                              'assets/developer2.jpg',
                              fit: BoxFit.cover,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, size: 60),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Harsh', 
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Creator of SafeNest',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Text(
                    'Welcome to SafeNest! I built this application to provide a secure, powerful, and entirely offline solution for tracking your custom collections, lists, and deep-linked internet shares. Let\'s connect!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16, 
                      height: 1.6,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 48),
                  _buildLinkButton(
                    context, 
                    Icons.code, 
                    'GitHub', 
                    'https://github.com/hashcodes7'
                  ),
                  _buildLinkButton(
                    context, 
                    Icons.work_outline, 
                    'LinkedIn', 
                    'https://www.linkedin.com/in/hashcodes7/'
                  ),
                  _buildLinkButton(
                    context, 
                    Icons.developer_mode, 
                    'Google Developer Profile', 
                    'https://g.dev/purplecode'
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
