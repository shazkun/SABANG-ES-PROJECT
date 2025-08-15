import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sabang_es/screens/function/qr_genf.dart';
import 'package:sabang_es/widgets/snackbar.dart';

class QRGenerateScreen extends StatefulWidget {
  const QRGenerateScreen({super.key});

  @override
  State<QRGenerateScreen> createState() => _QRGenerateScreenState();
}

class _QRGenerateScreenState extends State<QRGenerateScreen> {
  final QRGenerateFunctions _functions = QRGenerateFunctions();
  final _formKey = GlobalKey<FormState>();

  String? _lastGeneratedData;

  @override
  void initState() {
    super.initState();
    _functions.initControllers();
  }

  @override
  void dispose() {
    _functions.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter name';
    if (value.trim().length < 2) return 'Name too short';
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter email';
    final emailRegex = RegExp(r'^[\w\.-]+@[\w\.-]+\.\w+$');
    if (!emailRegex.hasMatch(value.trim())) return 'Invalid email format';
    return null;
  }

  String? _validateYear(String? value) {
    if (value == null || value.trim().isEmpty) return 'Enter S.Y.';
    final yearRegex = RegExp(r'^\d{4}-\d{4}$'); // e.g., 2024-2025
    if (!yearRegex.hasMatch(value.trim())) return 'Format: YYYY-YYYY';
    return null;
  }

  Future<void> _handleGenerateQR() async {
    if (_formKey.currentState!.validate()) {
      final name = _functions.nameController.text.trim();
      final email = _functions.emailController.text.trim();
      final year = _functions.yearController.text.trim();

      final qrData = '$name|$email|$year';
      if (qrData == _lastGeneratedData) {
        CustomSnackBar.show(
          context,
          'This QR code was already generated',
          isSuccess: false,
        );
        return;
      }

      final newQR = await _functions.generateQR();
      setState(() {
        _functions.qrModel = newQR;
        _lastGeneratedData = qrData;
      });

      CustomSnackBar.show(
        context,
        'QR code generated successfully',
        isSuccess: true,
      );
    } else {
      CustomSnackBar.show(
        context,
        'Please fix form errors before generating',
        isSuccess: false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Generate QR Code',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                color: Colors.white,
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _functions.nameController,
                          decoration: _inputDecoration('Name'),
                          validator: _validateName,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _functions.emailController,
                          decoration: _inputDecoration('Email'),
                          validator: _validateEmail,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _functions.yearController,
                          decoration: _inputDecoration('School Year'),
                          validator: _validateYear,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _handleGenerateQR,
                                style: _buttonStyle(Colors.blueAccent),
                                child: const Text(
                                  'Generate QR',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () {
                                  _functions.generateBatchQR(context);
                                  CustomSnackBar.show(
                                    context,
                                    'Batch QR generation started',
                                    isSuccess: true,
                                  );
                                },
                                style: _buttonStyle(Colors.blue),
                                child: const Text(
                                  'Batch Generate',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildQRPreview(),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  ButtonStyle _buttonStyle(Color color) {
    return ElevatedButton.styleFrom(
      backgroundColor: color,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      padding: const EdgeInsets.symmetric(vertical: 16),
    );
  }

  Widget _buildQRPreview() {
    return Card(
      elevation: 3,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_qrImage(), const SizedBox(width: 16), _qrDetails()],
        ),
      ),
    );
  }

  Widget _qrImage() {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child:
            _functions.qrModel != null
                ? QrImageView(
                  data: _functions.encodeQRData(_functions.qrModel!),
                  version: QrVersions.auto,
                  size: 120.0,
                  backgroundColor: Colors.white,
                )
                : Container(
                  width: 120.0,
                  height: 120.0,
                  color: Colors.grey[200],
                  child: const Icon(
                    Icons.question_mark,
                    size: 60,
                    color: Colors.grey,
                  ),
                ),
      ),
    );
  }

  Widget _qrDetails() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Details',
            style: TextStyle(
              fontSize: 18,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          _detailLine('Name', _functions.qrModel?.name),
          const SizedBox(height: 8),
          _detailLine('Email', _functions.qrModel?.email),
          const SizedBox(height: 8),
          _detailLine('Grade', _functions.qrModel?.year),
        ],
      ),
    );
  }

  Widget _detailLine(String label, String? value) {
    return Text(
      '$label: ${value ?? '-'}',
      style: const TextStyle(fontSize: 14, color: Colors.black54),
    );
  }
}
