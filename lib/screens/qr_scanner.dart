import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
  final Set<String> _processedQRs = {};
  static const int _cooldownSeconds = 10;
  bool _isDialogOpen = false;
  String? savedEmail;
  String? savedCode;
  bool _isCheckInMode = true;

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
    if (savedEmail == null || savedCode == null) {
      throw Exception('Email credentials not set');
    }

    final prefs = await SharedPreferences.getInstance();
    final checkInMsg =
        prefs.getString('checkInMessage') ??
        'Hello {name}, your QR code was scanned for check-in at {datetime}.';
    final checkOutMsg =
        prefs.getString('checkOutMessage') ??
        'Hello {name}, your QR code was scanned for check-out at {datetime}.';

    final nowStr = DateTime.now().toString();
    final messageText = (_isCheckInMode ? checkInMsg : checkOutMsg)
        .replaceAll('{name}', name)
        .replaceAll('{datetime}', nowStr);

    final smtpServer = gmail(savedEmail!, savedCode!);
    final message =
        Message()
          ..from = mailer.Address('your-email@gmail.com', 'QR Scanner')
          ..recipients.add(recipientEmail)
          ..subject =
              _isCheckInMode
                  ? 'QR Check-In Notification'
                  : 'QR Check-Out Notification'
          ..text = messageText;

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
    if (_isDialogOpen) return;
    _isDialogOpen = true;
    await showDialog<void>(
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
    _isDialogOpen = false;
  }

  Future<void> _processQRCode(String rawValue) async {
    try {
      // Extract ID for deduplication
      final parts = rawValue.split('|');
      if (parts.isEmpty || parts[0].isEmpty) {
        throw const FormatException('Invalid QR code format');
      }
      final id = parts[0];

      // Prevent processing the same QR code multiple times during processing
      if (_processedQRs.contains(id)) return;
      _processedQRs.add(id);

      // Log raw value for debugging
      await DatabaseHelper().insertQRLog(
        QRModel(
          id: const Uuid().v4(),
          name: 'Raw Scan',
          email: 'raw_scan@debug.com',
          gradeSection: 'Raw Data: $rawValue',
        ),
      );

      // Validate QR code
      if (rawValue.isEmpty) {
        throw const FormatException('QR code contains no data');
      }
      if (parts.length != 4) {
        throw const FormatException(
          'QR code must contain exactly 4 fields (id|name|email|gradeSection)',
        );
      }
      if (parts[0].isEmpty ||
          parts[1].isEmpty ||
          parts[2].isEmpty ||
          parts[3].isEmpty) {
        throw const FormatException('QR code fields cannot be empty');
      }

      // Extract fields
      final name = parts[1];
      final email = parts[2];
      final gradeSection = parts[3];

      // Check cooldown before logging or sending email
      final now = DateTime.now();
      if (_scanCooldowns.containsKey(id)) {
        final lastScan = _scanCooldowns[id]!;
        final difference = now.difference(lastScan).inSeconds;
        if (difference < _cooldownSeconds) {
          await _showDialog(
            'Cooldown',
            'This QR code was recently scanned. Please wait ${_cooldownSeconds - difference} seconds.',
          );
          _processedQRs.remove(id); // Allow retry after dialog
          return;
        }
      }

      // Log successful scan to database
      await DatabaseHelper().insertQRLog(
        QRModel(id: id, name: name, email: email, gradeSection: gradeSection),
      );

      // Update cooldown and send email
      _scanCooldowns[id] = now;
      await _sendEmail(email, name);
    } catch (e) {
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
      appBar: AppBar(
        centerTitle: true,
        title: const Text('Scan QR Code'),
        actions: [
          Row(
            children: [
              Switch(
                value: _isCheckInMode,
                onChanged: (value) {
                  setState(() {
                    _isCheckInMode = value;
                  });
                },
                activeColor: Colors.green,
                inactiveThumbColor: Colors.red,
              ),
            ],
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Define scan window as a centered square (60% of the smaller dimension)
          final scanSize =
              constraints.maxWidth < constraints.maxHeight
                  ? constraints.maxWidth * 0.6
                  : constraints.maxHeight * 0.6;
          final scanWindow = Rect.fromCenter(
            center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
            width: scanSize,
            height: scanSize,
          );

          return Stack(
            children: [
              MobileScanner(
                controller: cameraController,
                scanWindow: scanWindow,
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
              // Overlay to highlight scan area
              CustomPaint(
                painter: ScannerOverlayPainter(
                  scanWindow: scanWindow,
                  _isCheckInMode,
                ),
                size: Size(constraints.maxWidth, constraints.maxHeight),
              ),
              // Instructions
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    color: Colors.black54,
                    child: Text(
                      _isCheckInMode
                          ? 'Place QR code within the square to check in'
                          : 'Place QR code within the square to check out',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          );
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

// Custom painter for scanner overlay
class ScannerOverlayPainter extends CustomPainter {
  final Rect scanWindow;
  final bool _isCheckInMode;

  ScannerOverlayPainter(this._isCheckInMode, {required this.scanWindow});

  @override
  void paint(Canvas canvas, Size size) {
    final overlayPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.6)
          ..style = PaintingStyle.fill;

    // Draw overlay excluding scan window
    canvas.drawPath(
      Path()
        ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
        ..addRect(scanWindow)
        ..fillType = PathFillType.evenOdd,
      overlayPaint,
    );

    // Draw scan window border
    final borderPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4.0;
    canvas.drawRect(scanWindow, borderPaint);

    // Draw corner markers
    final cornerPaint =
        Paint()
          ..color = _isCheckInMode ? Colors.green : Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8.0;
    const cornerLength = 20.0;
    // Top-left
    canvas.drawLine(
      scanWindow.topLeft,
      scanWindow.topLeft.translate(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanWindow.topLeft,
      scanWindow.topLeft.translate(0, cornerLength),
      cornerPaint,
    );
    // Top-right
    canvas.drawLine(
      scanWindow.topRight,
      scanWindow.topRight.translate(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanWindow.topRight,
      scanWindow.topRight.translate(0, cornerLength),
      cornerPaint,
    );
    // Bottom-left
    canvas.drawLine(
      scanWindow.bottomLeft,
      scanWindow.bottomLeft.translate(cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanWindow.bottomLeft,
      scanWindow.bottomLeft.translate(0, -cornerLength),
      cornerPaint,
    );
    // Bottom-right
    canvas.drawLine(
      scanWindow.bottomRight,
      scanWindow.bottomRight.translate(-cornerLength, 0),
      cornerPaint,
    );
    canvas.drawLine(
      scanWindow.bottomRight,
      scanWindow.bottomRight.translate(0, -cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
