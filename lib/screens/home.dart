import 'package:flutter/material.dart';
import 'package:sabang_es/models/emailer_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? savedEmail;
  String? savedCode;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedEmail = prefs.getString('email');
      final encryptedCode = prefs.getString('code');
      if (encryptedCode != null) {
        savedCode = EncryptionHelper.decryptText(encryptedCode);
      }
    });
  }

  void _showSettingsDialog() {
    final emailController = TextEditingController(text: savedEmail ?? '');
    final codeController = TextEditingController(text: savedCode ?? '');

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              savedEmail != null ? 'Update Info' : 'Enter Email and Code',
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: codeController,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Code'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  final email = emailController.text.trim();
                  final code = codeController.text.trim();

                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text('Confirm'),
                          content: const Text(
                            'Do you want to save this information?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('No'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                final prefs =
                                    await SharedPreferences.getInstance();
                                final encryptedCode =
                                    EncryptionHelper.encryptText(code);
                                await prefs.setString('email', email);
                                await prefs.setString('code', encryptedCode);
                                Navigator.pop(context); // close confirm

                                _loadSavedData(); // reload state
                              },
                              child: const Text('Yes'),
                            ),
                          ],
                        ),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
            tooltip: savedEmail != null ? 'Update Info' : 'Enter Info',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/generate'),
              child: const Text('Generate QR Code'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/scan'),
              child: const Text('Scan QR Code'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/list'),
              child: const Text('View QR Codes'),
            ),
          ],
        ),
      ),
    );
  }
}
