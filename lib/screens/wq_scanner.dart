import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/mailer.dart' as mailer;
import 'package:mailer/smtp_server/gmail.dart';
import 'package:sabang_es/database/database_helper.dart';
import 'package:sabang_es/models/qr_model.dart';
// import 'package:sabang_es/soundplayer/audio_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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
  final Map<String, DateTime> _scanCooldowns = {};
  // final Set<String> _processedQRs = {};
  static const int _cooldownSeconds = 1;
  bool _isDialogOpen = false;
  String? savedEmail;
  String? savedCode;
  bool _isCheckInMode = true;
  // final audioHelper = AudioHelper();

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

    final smtpServer = gmail(savedEmail!, savedCode!);
    final message =
        Message()
          ..from = mailer.Address('your-email@gmail.com', 'QR Scanner')
          ..recipients.add(recipientEmail)
          ..subject =
              _isCheckInMode
                  ? 'QR Time-In Notification'
                  : 'QR Time-Out Notification'
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
          year: 'Email Failure: $e',
        ),
      );
      await _showDialog('Error', 'Failed to send email: $e');
    }
  }

  Future<void> _showDialog(String title, String message) async {
    if (_isDialogOpen) return;
    _isDialogOpen = true;

    // Show the dialog
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // Start timer to auto-close
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop(); // Auto close
          }
        });

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
        );
      },
    ).then((_) {
      _isDialogOpen = false;
    });
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
      // if (_processedQRs.contains(id)) return;
      // _processedQRs.add(id);

      // Log raw value for debugging
      await DatabaseHelper().insertQRLog(
        QRModel(
          id: const Uuid().v4(),
          name: 'Raw Scan',
          email: 'raw_scan@debug.com',
          year: 'Raw Data: $rawValue',
        ),
      );

      // Validate QR code
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

      // Extract fields
      final name = parts[1];
      final email = parts[2];
      final year = parts[3];

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
          // _processedQRs.remove(id); // Allow retry after dialog
          return;
        }
      }

      // Log successful scan to database
      await DatabaseHelper().insertQRLog(
        QRModel(id: id, name: name, email: email, year: year),
      );

      // Update cooldown and send email
      _scanCooldowns[id] = now;
      // audioHelper.playSuccess();
      await _sendEmail(email, name);
    } catch (e) {
      await DatabaseHelper().insertQRLog(
        QRModel(
          id: const Uuid().v4(),
          name: 'Unknown',
          email: 'scan_error@error.com',
          year: 'Scan Error: $e',
        ),
      );
      //await audioHelper.playFailed();
      await _showDialog('Error', 'Invalid QR code: $e');
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

        // Listen to stdout stream
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

        // Handle stderr in case of Python errors
        _scannerProcess!.stderr.transform(utf8.decoder).listen((err) {
          debugPrint("Python stderr: $err");
          // Do not update qrResult to keep errors off the screen
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
        backgroundColor: Colors.blue[800],
        elevation: 0,
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue[800]!, Colors.blue[600]!],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
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
              ElevatedButton(
                onPressed: toggleScanning,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      _isScanning
                          ? Colors.deepOrange[600]
                          : Colors.blueAccent[700],
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: Text(_isScanning ? 'Stop Scanning' : 'Start Scanning'),
              ),
              SizedBox(height: 15),
              ElevatedButton(
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                ),
                child: Text(_isCheckInMode ? 'Time-in' : 'Time-out'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
