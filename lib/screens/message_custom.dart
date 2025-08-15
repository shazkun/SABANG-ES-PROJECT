import 'package:flutter/material.dart';
import 'package:sabang_es/widgets/snackbar.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomMessageScreen extends StatefulWidget {
  const CustomMessageScreen({super.key});

  @override
  State<CustomMessageScreen> createState() => _CustomMessageScreenState();
}

class _CustomMessageScreenState extends State<CustomMessageScreen> {
  final checkInController = TextEditingController();
  final checkOutController = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  Future<void> loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    checkInController.text =
        prefs.getString('checkInMessage') ??
        'Hello {name}, your QR code was scanned for check-in at {datetime}.';
    checkOutController.text =
        prefs.getString('checkOutMessage') ??
        'Hello {name}, your QR code was scanned for check-out at {datetime}.';
    setState(() {});
  }

  Future<void> saveMessages() async {
    // Validation
    if (checkInController.text.trim().isEmpty ||
        checkOutController.text.trim().isEmpty) {
      CustomSnackBar.show(
        context,
        'Both messages cannot be empty.',
        isSuccess: false,
      );
      return;
    }

    // Placeholder checks
    if (!checkInController.text.contains('{name}') ||
        !checkInController.text.contains('{datetime}')) {
      CustomSnackBar.show(
        context,
        'Check-In message must include {name} and {datetime}.',
        isSuccess: false,
      );
      return;
    }
    if (!checkOutController.text.contains('{name}') ||
        !checkOutController.text.contains('{datetime}')) {
      CustomSnackBar.show(
        context,
        'Check-Out message must include {name} and {datetime}.',
        isSuccess: false,
      );
      return;
    }

    // Confirm save
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Confirm Save'),
            content: const Text('Do you want to save these messages?'),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(context, false),
              ),
              ElevatedButton(
                child: const Text('Save'),
                onPressed: () => Navigator.pop(context, true),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    // Save
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('checkInMessage', checkInController.text.trim());
    await prefs.setString('checkOutMessage', checkOutController.text.trim());

    CustomSnackBar.show(context, 'Messages saved successfully.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customize Email Messages'),
        backgroundColor: const Color(0xFF1976D2),
        centerTitle: true,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Use {name} and {datetime} as placeholders.',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: checkInController,
                decoration: InputDecoration(
                  labelText: 'Check-In Message',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: checkOutController,
                decoration: InputDecoration(
                  labelText: 'Check-Out Message',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: saveMessages,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  backgroundColor: Colors.blueAccent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.black.withOpacity(0.2),
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Messages',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
