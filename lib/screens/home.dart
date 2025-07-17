import 'dart:io';

import 'package:flutter/material.dart';

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'QR Attendance Scanner',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1976D2),
        actions: [],
      ),
      body: Container(
        color: const Color(0xFFE0E0E0),
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // _buildActionButton(
            //   Icons.qr_code_scanner,
            //   'Scan QR Code',
            //   () => Navigator.pushNamed(context, '/scan'),
            // ),
            const SizedBox(height: 10),
            _buildActionButton(
              Icons.remove_red_eye,
              'View QR Codes',
              () => Navigator.pushNamed(context, '/list'),
            ),
            const SizedBox(height: 10),
            _buildActionButton(
              Icons.merge_type,
              'Generate QR Code',
              () => Navigator.pushNamed(context, '/generate'),
            ),
            const SizedBox(height: 10),
            _buildActionButton(
              Icons.message,
              'Custom Message',
              () => Navigator.pushNamed(context, '/message'),
            ),
            const SizedBox(height: 10),
            _buildActionButton(
              Icons.settings,
              'Email Settings',
              () => Navigator.pushNamed(context, '/settings'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed:
            () => Navigator.pushNamed(
              context,
              Platform.isAndroid ? '/scan' : '/wqrscanner',
            ),
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
