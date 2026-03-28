import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../services/secret_service.dart';

class AuthHelper {
  static final LocalAuthentication _auth = LocalAuthentication();

  /// Prompts biometric auth. If absent/fails, falls back to a Secret Dialog.
  static Future<bool> authenticate(BuildContext context) async {
    bool authenticated = false;

    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (canAuthenticate) {
        authenticated = await _auth.authenticate(
          localizedReason: 'Unlock SafeNest',
        );
      }
    } catch (e) {
      debugPrint('Biometric Error: $e');
    }

    if (authenticated) return true;

    // Target check for user setting password. If no secret is configured, they cannot bypass biometrics yet.
    final bool hasSecret = await SecretService.hasSecret();
    if (!hasSecret) return false;

    // Fallback if biometric auth failed or isn't available
    if (context.mounted) {
      return await _showSecretDialog(context) ?? false;
    }
    
    return false;
  }

  static Future<bool?> _showSecretDialog(BuildContext context) {
    final TextEditingController secretController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isVerifying = false;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('App Secret Required'),
              content: Form(
                key: formKey,
                child: TextFormField(
                  controller: secretController,
                  obscureText: true,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Enter App Secret',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) {
                    if (val == null || val.isEmpty) {
                      return 'Secret cannot be empty';
                    }
                    return null;
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying ? null : () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isVerifying
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() => isVerifying = true);
                            final guess = secretController.text.trim();
                            final success = await SecretService.verifySecret(guess);
                            
                            if (success && context.mounted) {
                              Navigator.pop(context, true);
                            } else {
                              setState(() => isVerifying = false);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Invalid App Secret!', style: TextStyle(color: Colors.white)), 
                                    backgroundColor: Theme.of(context).colorScheme.error,
                                  ),
                                );
                              }
                            }
                          }
                        },
                  child: isVerifying
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('Unlock'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
