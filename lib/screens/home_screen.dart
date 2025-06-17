import 'package:flutter/material.dart';
import 'package:sabang_es/screens/qr_generator.dart';
import 'package:sabang_es/screens/qr_import.dart';
import 'package:sabang_es/screens/qr_scanner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Manager')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const QRGenerateScreen(),
                  ),
                );
              },
              child: const Text('Generate QR Code'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const QRScanScreen()),
                );
              },
              child: const Text('Scan QR Code'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BulkImportScreen(),
                  ),
                );
              },
              child: const Text('Bulk Import'),
            ),
          ],
        ),
      ),
    );
  }
}
