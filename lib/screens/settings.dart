import 'package:flutter/material.dart';
import 'package:sabang_es/util/encryptor.dart';
import 'package:sabang_es/widgets/snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String? savedEmail;
  String? savedCode;

  @override
  void initState() {
    super.initState();
    _loadSavedData();
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString('email');
    final storedCode = prefs.getString('code');

    setState(() {
      savedEmail = storedEmail;
      if (storedCode != null) {
        try {
          savedCode = EncryptionHelper.decryptText(storedCode);
        } catch (e) {
          savedCode = '';
          CustomSnackBar.show(
            context,
            'Failed to decrypt saved code.',
            isSuccess: false,
          );
        }
      }
    });
  }

  void _showCodeHelpDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'How to Get App Password',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: const Color(0xFF1976D2),
            content: const Text(
              'To generate a code (App Password):\n\n'
              '1. Go to your Google Account.\n'
              '2. Open the "Security" tab.\n'
              '3. Under "Signing in to Google", choose "App Passwords".\n'
              '4. Sign in again if needed.\n'
              '5. Select "Mail" as the app and your device, then click "Generate".\n'
              '6. Copy the 16-digit code and paste it in the Code field.',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showInputDialog({
    required String title,
    required String label,
    required bool isCode,
    required Function(String) onSave,
  }) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: const Color(0xFF1976D2),
            content: TextField(
              controller: controller,
              obscureText: isCode,
              style: const TextStyle(color: Colors.black, fontSize: 16),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: Color(0xFF4CAF50),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                errorText: null,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  final input = controller.text.trim();
                  if (input.isEmpty) {
                    CustomSnackBar.show(
                      context,
                      'Input cannot be empty.',
                      isSuccess: false,
                    );

                    return;
                  }
                  if (!isCode && !_isValidEmail(input)) {
                    CustomSnackBar.show(
                      context,
                      'Please enter a valid email address.',
                      isSuccess: false,
                    );

                    return;
                  }
                  if (input.length < 16) {
                    CustomSnackBar.show(
                      context,
                      'Code must be exactly 16 characters long.',
                      isSuccess: false,
                    );

                    return;
                  }

                  onSave(input);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4CAF50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Save',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }

  Future<void> _saveData(String? email, String? code) async {
    final prefs = await SharedPreferences.getInstance();
    if (email != null) {
      await prefs.setString('email', email);
    }
    if (code != null) {
      final encryptedCode = EncryptionHelper.encryptText(code);
      await prefs.setString('code', encryptedCode);
    }
    await _loadSavedData();
    CustomSnackBar.show(context, 'Data saved successfully.', isSuccess: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          savedEmail != null ? 'Update Info' : 'Enter Email and Code',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: Container(
        decoration: const BoxDecoration(color: Color(0xFFE0E0E0)),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed:
                      () => _showInputDialog(
                        title:
                            savedEmail != null ? 'Update Email' : 'Enter Email',
                        label: 'Email',
                        isCode: false,
                        onSave: (value) {
                          setState(() {
                            savedEmail = value;
                          });
                          _saveData(value, null);
                        },
                      ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Text(
                    savedEmail ?? 'Set Email',
                    style: TextStyle(
                      color:
                          savedEmail != null ? Colors.black : Colors.grey[700],
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed:
                      () => _showInputDialog(
                        title: savedCode != null ? 'Update Code' : 'Enter Code',
                        label: 'Code',
                        isCode: true,
                        onSave: (value) {
                          setState(() {
                            savedCode = value;
                          });
                          _saveData(null, value);
                        },
                      ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        savedCode != null ? Icons.check_circle : Icons.cancel,
                        color: savedCode != null ? Colors.green : Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        savedCode != null ? 'Code Set' : 'Set Code',
                        style: TextStyle(
                          color:
                              savedCode != null
                                  ? Colors.black
                                  : Colors.grey[700],
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.remove('email');
                    await prefs.remove('code');
                    setState(() {
                      savedEmail = null;
                      savedCode = null;
                    });
                    CustomSnackBar.show(
                      context,
                      'Data cleared successfully.',
                      isSuccess: true,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Clear Data',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: _showCodeHelpDialog,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text(
                      'How to Get Code',
                      style: TextStyle(
                        color: Color(0xFF1976D2),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
