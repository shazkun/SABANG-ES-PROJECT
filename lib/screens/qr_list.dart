import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../models/qr_model.dart';
import '../database/database_helper.dart';

class QRListScreen extends StatefulWidget {
  const QRListScreen({super.key});

  @override
  State<QRListScreen> createState() => _QRListScreenState();
}

class _QRListScreenState extends State<QRListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<QRModel> _qrCodes = [];

  @override
  void initState() {
    super.initState();
    _loadQRCodes();
  }

  Future<void> _loadQRCodes() async {
    final qrCodes = await _dbHelper.getQRLogs();
    setState(() {
      _qrCodes = qrCodes.where((qr) => !qr.email.contains('error@')).toList();
    });
  }

  Future<void> _showEditDialog(QRModel qr) async {
    final nameController = TextEditingController(text: qr.name);
    final emailController = TextEditingController(text: qr.email);
    final gradeSectionController = TextEditingController(text: qr.gradeSection);
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Edit QR Code',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) => value!.isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) => value!.isEmpty ? 'Enter email' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: gradeSectionController,
                    decoration: const InputDecoration(
                      labelText: 'Grade Section',
                    ),
                    validator:
                        (value) =>
                            value!.isEmpty ? 'Enter grade section' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Save', style: TextStyle(color: Colors.black)),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final updatedQR = QRModel(
                    id: qr.id,
                    name: nameController.text,
                    email: emailController.text,
                    gradeSection: gradeSectionController.text,
                  );
                  await _dbHelper.insertQRLog(updatedQR);
                  await _loadQRCodes();
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteDialog(QRModel qr) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text(
            'Delete QR Code',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          ),
          content: Text(
            'Are you sure you want to delete ${qr.name}\'s QR code?',
            style: const TextStyle(color: Colors.black),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () async {
                await _dbHelper.database.then(
                  (db) =>
                      db.delete('qr_logs', where: 'id = ?', whereArgs: [qr.id]),
                );
                await _loadQRCodes();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  String _encodeQRData(QRModel qr) {
    // Encode as delimited string: id|name|email|gradeSection
    return '${qr.id}|${qr.name}|${qr.email}|${qr.gradeSection}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('QR Code List')),
      body:
          _qrCodes.isEmpty
              ? const Center(
                child: Text(
                  'No QR codes found',
                  style: TextStyle(color: Colors.black, fontSize: 16),
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: _qrCodes.length,
                itemBuilder: (context, index) {
                  final qr = _qrCodes[index];
                  return Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: Colors.black),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // QR Code Image
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: QrImageView(
                              data: _encodeQRData(qr),
                              version: QrVersions.auto,
                              size: 100.0,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Details and Buttons
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  qr.name,
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Email: ${qr.email}',
                                  style: const TextStyle(color: Colors.black),
                                ),
                                Text(
                                  'Grade: ${qr.gradeSection}',
                                  style: const TextStyle(color: Colors.black),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    IconButton(
                                      icon: const Icon(
                                        Icons.edit,
                                        color: Colors.black,
                                      ),
                                      onPressed: () => _showEditDialog(qr),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.black,
                                      ),
                                      onPressed: () => _showDeleteDialog(qr),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
    );
  }
}
