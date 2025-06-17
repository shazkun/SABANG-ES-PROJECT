import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

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
  final Set<QRModel> _selectedQRs = {};

  @override
  void initState() {
    super.initState();
    _loadQRCodes();
  }

  Future<void> _loadQRCodes() async {
    final qrCodes = await _dbHelper.getQRLogs();
    setState(() {
      _qrCodes = qrCodes.where((qr) => !qr.email.contains('error@')).toList();
      _selectedQRs.clear();
    });
  }

  void _toggleSelection(QRModel qr) {
    setState(() {
      if (_selectedQRs.contains(qr)) {
        _selectedQRs.remove(qr);
      } else {
        _selectedQRs.add(qr);
      }
    });
  }

  String _encodeQRData(QRModel qr) {
    return qr.id;
  }

  Future<void> generatePDFWithQRImages() async {
    if (_selectedQRs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one QR code')),
      );
      return;
    }

    final pdf = pw.Document();

    for (final qr in _selectedQRs) {
      final qrPainter = QrPainter(
        data: qr.id,
        version: QrVersions.auto,
        gapless: true,
        color: Colors.black,
        emptyColor: Colors.white,
      );

      final picData = await qrPainter.toImageData(
        300,
        format: ui.ImageByteFormat.png,
      );
      final image = pw.MemoryImage(picData!.buffer.asUint8List());

      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(child: pw.Image(image, width: 150, height: 150)),
                pw.SizedBox(height: 10),
                pw.Text("ID: ${qr.id}"),
                pw.Text("Name: ${qr.name}"),
                pw.Text("Email: ${qr.email}"),
                pw.Text("Grade Section: ${qr.gradeSection}"),
                pw.Divider(),
              ],
            );
          },
        ),
      );
    }

    var status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Storage permission is required')),
      );
      return;
    }

    final directory = await getApplicationDocumentsDirectory();
    final path = "${directory!.path}/qr_list.pdf";
    final file = File(path);
    await file.writeAsBytes(await pdf.save());

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('PDF saved to $path')));
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
              onPressed: () => Navigator.of(context).pop(),
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
                  try {
                    await _dbHelper.updateQRLog(updatedQR);
                    await _loadQRCodes();
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('QR code updated successfully'),
                      ),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update QR code: $e')),
                    );
                  }
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
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.black),
              ),
              onPressed: () async {
                try {
                  await _dbHelper.deleteQRLog(qr.id);
                  await _loadQRCodes();
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('QR code deleted successfully'),
                    ),
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to delete QR code: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('QR Code List'),
        actions: [
          if (_selectedQRs.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.print, color: Colors.white),
              tooltip: 'Export PDF',
              onPressed: generatePDFWithQRImages,
            ),
        ],
      ),
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
                  final isSelected = _selectedQRs.contains(qr);
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
                          Checkbox(
                            value: isSelected,
                            onChanged: (bool? value) {
                              _toggleSelection(qr);
                            },
                            activeColor: Colors.black,
                          ),
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
