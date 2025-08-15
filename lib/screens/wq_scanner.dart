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
  bool _isCheckInMode = true;

  String? savedEmail;
  String? savedCode;
  String? checkInMsg;
  String? checkOutMsg;

  DateTime? _lastProcessed;

  @override
  void initState() {
    super.initState();
    _initData();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  Future<void> _initData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      savedEmail = prefs.getString('email');
      savedCode = prefs.getString('code');
      checkInMsg =
          prefs.getString('checkInMessage') ??
          'Hello {name}, your QR code was scanned for check-in at {datetime}.';
      checkOutMsg =
          prefs.getString('checkOutMessage') ??
          'Hello {name}, your QR code was scanned for check-out at {datetime}.';
    });
  }

  Future<void> _sendEmail(String recipientEmail, String name) async {
    final nowStr = DateTime.now().toString();
    final messageText = (_isCheckInMode ? checkInMsg! : checkOutMsg!)
        .replaceAll('{name}', name)
        .replaceAll('{datetime}', nowStr);

    final smtpServer = gmail(
      savedEmail!,
      EncryptionHelper.decryptText(savedCode!),
    );
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
      await _showDialog('Success', 'Email sent to $recipientEmail');
    } catch (_) {
      await _showDialog('Error', 'Failed to send email.');
    }
  }

  Future<void> _showDialog(String title, String message) async {
    if (_isDialogOpen) return;
    _isDialogOpen = true;

    final isSuccess = title.toLowerCase().contains('success');
    final icon = Icon(
      isSuccess ? Icons.check_circle : Icons.cancel,
      color: isSuccess ? Colors.green : Colors.red,
      size: 60,
    );

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        Future.delayed(const Duration(seconds: 2), () {
          if (Navigator.of(context).canPop()) Navigator.of(context).pop();
          setState(() => qrResult = "Empty");
        });

        return AlertDialog(
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
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    ).then((_) => _isDialogOpen = false);
  }

  Future<void> _processQRCode(String rawValue) async {
    final now = DateTime.now();
    if (_lastProcessed != null &&
        now.difference(_lastProcessed!).inMilliseconds < 1000) {
      return;
    }
    _lastProcessed = now;

    final parts = rawValue.split('|');
    if (parts.length != 4 || parts.any((p) => p.isEmpty)) {
      await _showDialog('Invalid QR', 'Please scan a valid QR code.');
      return;
    }

    final name = parts[1];
    final email = parts[2];
    await _sendEmail(email, name);
  }

  Future<void> toggleScanning() async {
    if (_isScanning) {
      _scannerProcess?.kill();
      _scannerProcess = null;
      setState(() {
        qrResult = 'Scanner stopped.';
        _isScanning = false;
      });
      return;
    }

    setState(() {
      qrResult = 'Scanning...';
      _isScanning = true;
    });

    try {
      _scannerProcess = await Process.start('python', ['scan_qr.py']);
      _scannerProcess!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen((line) {
            if (line.contains('"result"')) {
              final json = jsonDecode(line);
              final result = json["result"]?.toString() ?? '';
              setState(() => qrResult = result);
              _processQRCode(result);
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
    }
  }

  @override
  void dispose() {
    _scannerProcess?.kill();
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 200,
      height: 60,
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 24),
        label: Text(label, style: const TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: onPressed,
      ),
    );
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
              _buildActionButton(
                label: _isScanning ? 'Stop Scanning' : 'Start Scanning',
                color:
                    _isScanning
                        ? Colors.deepOrange[600]!
                        : Colors.blueAccent[700]!,
                icon: _isScanning ? Icons.stop : Icons.qr_code_scanner,
                onPressed: toggleScanning,
              ),
              const SizedBox(height: 15),
              _buildActionButton(
                label: _isCheckInMode ? 'Time-in' : 'Time-out',
                color: _isCheckInMode ? Colors.green[600]! : Colors.red[700]!,
                icon: _isCheckInMode ? Icons.login : Icons.logout,
                onPressed:
                    () => setState(() => _isCheckInMode = !_isCheckInMode),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
