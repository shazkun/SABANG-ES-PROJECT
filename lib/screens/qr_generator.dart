import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/qr_model.dart';
import '../database/database_helper.dart';

class QRGenerateScreen extends StatefulWidget {
  const QRGenerateScreen({super.key});

  @override
  State<QRGenerateScreen> createState() => _QRGenerateScreenState();
}

class _QRGenerateScreenState extends State<QRGenerateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _gradeSectionController = TextEditingController();
  QRModel? _qrModel;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _gradeSectionController.dispose();
    super.dispose();
  }

  void _generateQR() async {
    if (_formKey.currentState!.validate()) {
      final qr = QRModel(
        id: const Uuid().v4(),
        name: _nameController.text,
        email: _emailController.text,
        gradeSection: _gradeSectionController.text,
      );
      await DatabaseHelper().insertQRLog(qr);
      setState(() {
        _qrModel = qr;
      });
    }
  }

  String _encodeQRData(QRModel qr) {
    return '${qr.id}|${qr.name}|${qr.email}|${qr.gradeSection}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate QR Code')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Name'),
                      validator:
                          (value) => value!.isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                      validator:
                          (value) => value!.isEmpty ? 'Enter email' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _gradeSectionController,
                      decoration: const InputDecoration(
                        labelText: 'Grade Section',
                      ),
                      validator:
                          (value) =>
                              value!.isEmpty ? 'Enter grade section' : null,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _generateQR,
                      child: const Text('Generate QR'),
                    ),
                  ],
                ),
              ),
              if (_qrModel != null) ...[
                const SizedBox(height: 24),
                Center(
                  child: QrImageView(
                    data: _encodeQRData(_qrModel!),
                    version: QrVersions.auto,
                    size: 200.0,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'QR Code Details:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ID: ${_qrModel!.id}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Name: ${_qrModel!.name}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Email: ${_qrModel!.email}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Grade Section: ${_qrModel!.gradeSection}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
