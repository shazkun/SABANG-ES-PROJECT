import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/qr_model.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  MobileScannerController cameraController = MobileScannerController();

  Future<void> _sendEmail(String email) async {
    final smtpServer = gmail('seanwiltonr@gmail.com', 'utfn xubd cnkf bdxs');
    final message =
        Message()
          ..from = mailer.Address('your-email@gmail.com', 'QR Scanner')
          ..recipients.add(email)
          ..subject = 'QR Scan Notification'
          ..text = 'Your QR code has been scanned at ${DateTime.now()}.';

    try {
      await send(message, smtpServer);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Email sent successfully')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to send email: $e')));
    }
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

      // Log successful scan to database
      await DatabaseHelper().insertQRLog(
        QRModel(id: id, name: name, email: email, gradeSection: gradeSection),
      );

      // Send email using extracted email as recipient
      await _sendEmail(email);
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

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Invalid QR code: $e')));
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No data found in QR code')),
              );
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
