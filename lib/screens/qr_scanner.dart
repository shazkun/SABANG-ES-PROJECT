import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/qr_model.dart';
import '../database/database_helper.dart';
import 'package:uuid/uuid.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  MobileScannerController cameraController = MobileScannerController();
  final Map<String, DateTime> _scanCooldowns = {};
  static const int _cooldownSeconds = 10;
  String? savedEmail;
  String? savedCode;

  @override
  void initState() {
    super.initState();
    loadSavedData();
  }

  Future<void> loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedEmail = prefs.getString('email');
      savedCode = prefs.getString('code');
    });
  }

  Future<void> _sendEmail(String recipientEmail, String name) async {
    final smtpServer = gmail(savedEmail!, savedCode!);
    final message =
        Message()
          ..from = mailer.Address('your-email@gmail.com', 'QR Scanner')
          ..recipients.add(recipientEmail)
          ..subject = 'QR Scan Notification'
          ..text =
              'Hello $name, your QR code was scanned at ${DateTime.now()}.';

    try {
      await send(message, smtpServer);
      await _showDialog(
        'Success',
        'Email sent successfully to $recipientEmail',
      );
    } catch (e) {
      await DatabaseHelper().insertQRLog(
        QRModel(
          id: const Uuid().v4(),
          name: name,
          email: 'email_error@error.com',
          gradeSection: 'Email Failure: $e',
        ),
      );
      await _showDialog('Error', 'Failed to send email: $e');
    }
  }

  Future<void> _showDialog(String title, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            title,
            style: const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(message, style: const TextStyle(color: Colors.black)),
          actions: [
            TextButton(
              child: const Text('OK', style: TextStyle(color: Colors.black)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _processQRCode(String rawValue) async {
    try {
      // Log raw value for debugging
      await DatabaseHelper().insertQRLog(
        QRModel(
          id: const Uuid().v4(),
          name: 'Raw Scan',
          email: 'raw_scan@debug.com',
          gradeSection: 'Raw Data: $rawValue',
        ),
      );

      // Check if rawValue is empty
      if (rawValue.isEmpty) {
        throw const FormatException('QR code contains no data');
      }

      // Split the raw value by delimiter
      final parts = rawValue.split('|');
      if (parts.length != 4) {
        throw const FormatException(
          'QR code must contain exactly 4 fields (id|name|email|gradeSection)',
        );
      }

      // Validate fields
      if (parts[0].isEmpty ||
          parts[1].isEmpty ||
          parts[2].isEmpty ||
          parts[3].isEmpty) {
        throw const FormatException('QR code fields cannot be empty');
      }

      // Extract fields
      final id = parts[0];
      final name = parts[1];
      final email = parts[2];
      final gradeSection = parts[3];

      // Check cooldown
      if (_scanCooldowns.containsKey(id)) {
        final lastScan = _scanCooldowns[id]!;
        final now = DateTime.now();
        final difference = now.difference(lastScan).inSeconds;
        if (difference < _cooldownSeconds) {
          await _showDialog(
            'Cooldown',
            'This QR code was recently scanned. Please wait ${(_cooldownSeconds - difference)} seconds.',
          );
          return;
        }
      }

      // Log successful scan to database
      await DatabaseHelper().insertQRLog(
        QRModel(id: id, name: name, email: email, gradeSection: gradeSection),
      );

      // Update cooldown
      _scanCooldowns[id] = DateTime.now();

      // Send email using extracted email as recipient
      await _sendEmail(email, name);
    } catch (e) {
      // Log failed scan attempt with error details
      await DatabaseHelper().insertQRLog(
        QRModel(
          id: const Uuid().v4(),
          name: 'Unknown',
          email: 'scan_error@error.com',
          gradeSection: 'Scan Error: $e',
        ),
      );

      await _showDialog('Error', 'Invalid QR code: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scan QR Code')),
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) {
          final List<Barcode> barcodes = capture.barcodes;
          for (final barcode in barcodes) {
            if (barcode.rawValue != null) {
              _processQRCode(barcode.rawValue!);
            } else {
              DatabaseHelper().insertQRLog(
                QRModel(
                  id: const Uuid().v4(),
                  name: 'Unknown',
                  email: 'scan_error@error.com',
                  gradeSection: 'Scan Error: No data in QR code',
                ),
              );
              _showDialog('Error', 'No data found in QR code');
            }
          }
        },
      ),
    );
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }
}
