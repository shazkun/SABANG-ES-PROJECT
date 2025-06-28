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
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white,
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: emailController,
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.black),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF4CAF50)),
                    ),
                  ),
                ),
                const SizedBox(height: 15),
                TextField(
                  controller: codeController,
                  obscureText: true,
                  style: TextStyle(color: Colors.black),
                  decoration: InputDecoration(
                    labelText: 'Code',
                    labelStyle: TextStyle(color: Colors.black),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.black),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF4CAF50)),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: Colors.black),
                ),
              ),
              TextButton(
                onPressed: _showCodeHelpDialog,
                child: const Text(
                  'How to Get Code',
                  style: TextStyle(color: Color(0xFF1976D2)),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final email = emailController.text.trim();
                  final code = codeController.text.trim();

                  showDialog(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text(
                            'Confirm',
                            style: TextStyle(color: Colors.white),
                          ),
                          backgroundColor: Color(0xFF1976D2),
                          content: const Text(
                            'Do you want to save this information?',
                            style: TextStyle(color: Colors.white),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'No',
                                style: TextStyle(color: Colors.white),
                              ),
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
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF4CAF50),
                              ),
                              child: const Text(
                                'Yes',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4CAF50),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );
  }

  void _showCodeHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'How to Get App Password',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF1976D2),
            content: const Text(
              'To generate a code (App Password):\n\n'
              '1. Go to your Google Account.\n'
              '2. Open the "Security" tab.\n'
              '3. Under "Signing in to Google", choose "App Passwords".\n'
              '4. Sign in again if needed.\n'
              '5. Select "Mail" as the app and your device, then click "Generate".\n'
              '6. Copy the 16-digit code and paste it in the Code field.',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Attendance Scanner',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1976D2),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: _showSettingsDialog,
            tooltip: savedEmail != null ? 'Update Info' : 'Enter Info',
          ),
        ],
      ),
      body: Container(
        color: const Color(0xFFE0E0E0),
        padding: const EdgeInsets.all(16.0),
        child: GridView.count(
          crossAxisCount: 3,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1,
          children: [
            _buildActionButton(
              Icons.qr_code_scanner,
              'Scan QR Code',
              () => Navigator.pushNamed(context, '/scan'),
            ),
            _buildActionButton(
              Icons.remove_red_eye,
              'View QR Codes',
              () => Navigator.pushNamed(context, '/list'),
            ),
            _buildActionButton(
              Icons.merge_type,
              'Generate QR Code',
              () => Navigator.pushNamed(context, '/generate'),
            ),
            _buildActionButton(
              Icons.message,
              'Custom Message',
              () => Navigator.pushNamed(context, '/message'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, '/scan'),
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: Colors.white,
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Color(0xFF1976D2), size: 30),
              const SizedBox(height: 5),
              Text(
                label,
                style: TextStyle(color: Color(0xFF1976D2), fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
