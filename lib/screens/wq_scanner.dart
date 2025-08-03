import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:sabang_es/util/encryptor.dart';
import 'package:shared_preferences/shared_preferences.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage>
    with SingleTickerProviderStateMixin {
  String qrResult = 'No scan yet';
  Process? _scannerProcess;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  bool _isScanning = false;
  bool _isDialogOpen = false;
  String? savedEmail;
  String? savedCode;
  bool _isCheckInMode = true;
  DateTime? _lastProcessed;

  @override
  void initState() {
    super.initState();
    loadSavedData();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
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
    String dCode = EncryptionHelper.decryptText(savedCode!);
    final smtpServer = gmail(savedEmail!, dCode);
    final message =
        Message()
          ..from = Address(savedEmail!, 'Sabang Elementary School')
          ..recipients.add(recipientEmail)
          ..subject =
              _isCheckInMode
                  ? 'QR Time-In Notification'
                  : 'QR Time-Out Notification'
          ..text = messageText;

    try {
      await send(message, smtpServer);
    } catch (e) {
      await _showDialog(
        'Error',
        ' Email settings not found. Set them up to continue.',
      );
    }
  }

  Future<void> _showDialog(String title, String message) async {
    if (_isDialogOpen) return;
    _isDialogOpen = true;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
            setState(() {
              qrResult = "Empty";
            });
          }
        });

        final isSuccess = title.toLowerCase().contains('success');
        final icon =
            isSuccess
                ? const Icon(Icons.check_circle, color: Colors.green, size: 60)
                : const Icon(Icons.cancel, color: Colors.red, size: 60);

        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(color: Colors.black87, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    ).then((_) {
      _isDialogOpen = false;
    });
  }

  Future<void> _processQRCode(String rawValue) async {
    final now = DateTime.now();

    if (_lastProcessed != null &&
        now.difference(_lastProcessed!).inMilliseconds < 1000) {
      return;
    }
    _lastProcessed = now;

    try {
      final parts = rawValue.split('|');
      if (parts.isEmpty || parts[0].isEmpty) {
        throw const FormatException('Invalid QR code format');
      }

      if (rawValue.isEmpty) {
        throw const FormatException('QR code contains no data');
      }
      if (parts.length != 4) {
        throw const FormatException(
          'QR code must contain exactly 4 fields (id|name|email|year)',
        );
      }
      if (parts[0].isEmpty ||
          parts[1].isEmpty ||
          parts[2].isEmpty ||
          parts[3].isEmpty) {
        throw const FormatException('QR code fields cannot be empty');
      }
      if (savedCode!.isEmpty || savedEmail!.isEmpty) {
        throw const FormatException(
          'Email settings not found. Set them up to continue.',
        );
      }

      final name = parts[1];
      final email = parts[2];
      // final year = parts[3];

      await _sendEmail(email, name);
      await _showDialog('Success', 'Email sent successfully to $email');
    } catch (e) {
      await _showDialog('Invalid QR', 'Please scan a valid QR code.');
    }
  }

  Future<void> toggleScanning() async {
    if (_isScanning) {
      _scannerProcess?.kill();
      _scannerProcess = null;
      setState(() {
        qrResult = 'Scanner stopped.';
        _isScanning = false;
      });
      _animationController.forward(from: 0.0);
    } else {
      setState(() {
        qrResult = 'Scanning...';
        _isScanning = true;
      });
      _animationController.forward(from: 0.0);

      try {
        _scannerProcess = await Process.start('python', ['scan_qr.py']);
        _scannerProcess!.stdout
            .transform(utf8.decoder)
            .transform(const LineSplitter())
            .listen((line) {
              if (line.contains('"result"')) {
                final json = jsonDecode(line);
                setState(() {
                  qrResult = '${json["result"]}';
                  _processQRCode(qrResult);
                });
                _animationController.forward(from: 0.0);
              }
            });

        _scannerProcess!.stderr.transform(utf8.decoder).listen((err) {
          debugPrint("Python stderr: $err");
        });
      } catch (e) {
        debugPrint('Error starting scanner: $e');
        setState(() {
          qrResult = 'Scanner stopped.';
          _isScanning = false;
        });
        _animationController.forward(from: 0.0);
      }
    }
  }

  @override
  void dispose() {
    _scannerProcess?.kill();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'QR Scanner',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _fadeAnimation,
                child: Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      qrResult,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[900],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: 200, // Fixed width for both buttons
                height: 60, // Fixed height for both buttons
                child: ElevatedButton(
                  onPressed: toggleScanning,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isScanning
                            ? Colors.deepOrange[600]
                            : Colors.blueAccent[700],
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isScanning ? Icons.stop : Icons.qr_code_scanner,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isScanning ? 'Stop Scanning' : 'Start Scanning',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 15),
              SizedBox(
                width: 200,
                height: 60,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _isCheckInMode = !_isCheckInMode;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _isCheckInMode ? Colors.green[600] : Colors.red[700],
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isCheckInMode ? Icons.login : Icons.logout,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isCheckInMode ? 'Time-in' : 'Time-out',
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
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
