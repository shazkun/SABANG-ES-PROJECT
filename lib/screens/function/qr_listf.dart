import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sabang_es/database/database_helper.dart';
import 'package:sabang_es/models/qr_model.dart';
import 'package:sabang_es/widgets/snackbar.dart';

class QRListFunctions {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<QRModel> qrCodes = [];
  List<QRModel> filteredQRCodes = [];
  Set<QRModel> selectedQRs = {};

  Future<void> loadQRCodes(
    void Function(List<QRModel>, Set<QRModel>) callback,
  ) async {
    final qrCodes = await _dbHelper.getQRLogs();
    this.qrCodes = qrCodes.where((qr) => !qr.email.contains('error@')).toList();
    filteredQRCodes = this.qrCodes;
    selectedQRs.clear();
    callback(this.qrCodes, selectedQRs);
  }

  void filterQRCodes(String query) {
    if (query.isEmpty) {
      filteredQRCodes = qrCodes;
    } else {
      filteredQRCodes =
          qrCodes
              .where(
                (qr) =>
                    qr.name.toLowerCase().contains(query.toLowerCase()) ||
                    qr.email.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
    }
  }

  void toggleSelection(QRModel qr) {
    if (selectedQRs.contains(qr)) {
      selectedQRs.remove(qr);
    } else {
      selectedQRs.add(qr);
    }
  }

  void selectAll(bool select) {
    if (select) {
      selectedQRs.addAll(filteredQRCodes);
    } else {
      selectedQRs.clear();
    }
  }

  String encodeQRData(QRModel qr) {
    return '${qr.id}|${qr.name}|${qr.email}|${qr.year}';
  }

  Future<void> generateQRTablePdf(BuildContext context) async {
    if (selectedQRs.isEmpty) {
      CustomSnackBar.show(
        context,
        'Please select at least one QR code',

        isSuccess: false,
      );

      return;
    }

    final pdf = pw.Document();

    List<pw.TableRow> tableRows = [
      pw.TableRow(
        children: [
          pw.Text(
            'QR Code',
            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
          ),
          pw.Text('Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    ];

    for (final qr in selectedQRs) {
      try {
        final qrPainter = QrPainter(
          data: encodeQRData(qr),
          version: QrVersions.auto,
          gapless: true,
          color: Colors.black,
          emptyColor: Colors.white,
        );

        final picData = await qrPainter.toImageData(
          150,
          format: ui.ImageByteFormat.png,
        );
        final Uint8List pngBytes = picData!.buffer.asUint8List();

        final qrImage = pw.MemoryImage(pngBytes);

        tableRows.add(
          pw.TableRow(
            children: [
              pw.Container(
                height: 100,
                child: pw.Image(qrImage),
                padding: const pw.EdgeInsets.all(4),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(8.0),
                child: pw.Text(qr.name),
              ),
            ],
          ),
        );
      } catch (e) {
        // You can log the error if needed
      }
    }

    pdf.addPage(
      pw.MultiPage(
        build:
            (context) => [
              pw.Text('QR Code Table', style: pw.TextStyle(fontSize: 24)),
              pw.SizedBox(height: 20),
              pw.Table(border: pw.TableBorder.all(), children: tableRows),
            ],
      ),
    );

    final outputDir = await getApplicationDocumentsDirectory();
    final file = File("${outputDir.path}/QR_Code_Table.pdf");

    await file.writeAsBytes(await pdf.save());

    CustomSnackBar.show(
      context,
      'QR Code PDF saved to ${file.path}',
      isSuccess: true,
    );
  }

  Future<void> generateQRImages(BuildContext context) async {
    if (selectedQRs.isEmpty) {
      CustomSnackBar.show(
        context,
        'Please select at least one QR code',
        isSuccess: false,
      );

      return;
    }

    var status = await Permission.storage.request();
    if (!status.isGranted) {
      CustomSnackBar.show(
        context,
        'Storage permission is required',
        isSuccess: false,
      );

      return;
    }

    final baseDir = await getApplicationDocumentsDirectory();
    final qrFolder = Directory('${baseDir.path}/QR_Codes');

    // Create the folder if it doesn't exist
    if (!await qrFolder.exists()) {
      await qrFolder.create(recursive: true);
    }

    int successCount = 0;
    int failCount = 0;

    for (final qr in selectedQRs) {
      try {
        final qrPainter = QrPainter(
          data: encodeQRData(qr),
          version: QrVersions.auto,
          gapless: true,
          color: Colors.black,
          emptyColor: Colors.white,
        );

        final picData = await qrPainter.toImageData(
          300,
          format: ui.ImageByteFormat.png,
        );

        final sanitizedName = qr.name.replaceAll(RegExp(r'[^\w\s-]'), '_');
        final sanitizedSection = qr.year.replaceAll(RegExp(r'[^\w\s-]'), '_');
        final fileName = '${sanitizedName}_${sanitizedSection}.png';

        final file = File('${qrFolder.path}/$fileName');
        await file.writeAsBytes(picData!.buffer.asUint8List());
        successCount++;
      } catch (e) {
        failCount++;
      }
    }

    CustomSnackBar.show(
      context,
      'Saved $successCount QR code${successCount != 1 ? 's' : ''} to /QR_Codes/. ${failCount > 0 ? '$failCount failed.' : ''}',
      isSuccess: failCount == 0,
      backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
    );
  }

  Future<void> deleteSelectedQRCodes(
    BuildContext context,
    void Function(void Function()) setState,
  ) async {
    if (selectedQRs.isEmpty) {
      CustomSnackBar.show(
        context,
        'Please select at least one QR code to delete',
        isSuccess: false,
      );

      return;
    }

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete Selected QR Codes',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          content: Text(
            'Are you sure you want to delete ${selectedQRs.length} QR code${selectedQRs.length != 1 ? 's' : ''}?',
            style: const TextStyle(color: Colors.black54),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black54),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                try {
                  int successCount = 0;
                  int failCount = 0;
                  for (final qr in selectedQRs.toList()) {
                    try {
                      await _dbHelper.deleteQRLog(qr.id);
                      successCount++;
                    } catch (e) {
                      failCount++;
                    }
                  }
                  await loadQRCodes((qrCodes, selectedQRs) {
                    setState(() {
                      this.qrCodes = qrCodes;
                      this.selectedQRs = selectedQRs;
                      filterQRCodes('');
                    });
                  });

                  Navigator.of(context).pop();
                  CustomSnackBar.show(
                    context,
                    'Deleted $successCount QR code${successCount != 1 ? 's' : ''} successfully. ${failCount > 0 ? '$failCount failed.' : ''}',
                    isSuccess: failCount == 0,
                    backgroundColor:
                        failCount > 0 ? Colors.orange : Colors.green,
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  CustomSnackBar.show(
                    context,
                    'Failed to delete QR codes: $e',
                    isSuccess: false,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> showEditDialog(
    BuildContext context,
    QRModel qr,
    void Function(void Function()) setState,
  ) async {
    final nameController = TextEditingController(text: qr.name);
    final emailController = TextEditingController(text: qr.email);
    final yearController = TextEditingController(text: qr.year);
    final formKey = GlobalKey<FormState>();

    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Edit QR Code',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    validator: (value) => value!.isEmpty ? 'Enter name' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: emailController,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    validator: (value) => value!.isEmpty ? 'Enter email' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: yearController,
                    decoration: InputDecoration(
                      labelText: 'Year',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                    validator: (value) => value!.isEmpty ? 'Enter Year' : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black54),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final updatedQR = QRModel(
                    id: qr.id,
                    name: nameController.text,
                    email: emailController.text,
                    year: yearController.text,
                  );
                  try {
                    await _dbHelper.updateQRLog(updatedQR);
                    await loadQRCodes((qrCodes, selectedQRs) {
                      setState(() {
                        this.qrCodes = qrCodes;
                        this.selectedQRs = selectedQRs;
                        filterQRCodes('');
                      });
                    });
                    Navigator.of(context).pop();
                    CustomSnackBar.show(
                      context,
                      'QR code updated successfully',
                      isSuccess: true,
                    );
                  } catch (e) {
                    Navigator.of(context).pop();
                    CustomSnackBar.show(
                      context,
                      'Failed to update QR code: $e',
                      isSuccess: false,
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

  Future<void> showDeleteDialog(
    BuildContext context,
    QRModel qr,
    void Function(void Function()) setState,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Delete QR Code',
            style: TextStyle(
              color: Colors.black87,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          content: Text(
            'Are you sure you want to delete ${qr.name}\'s QR code?',
            style: const TextStyle(color: Colors.black54),
          ),
          actions: [
            TextButton(
              child: const Text(
                'Cancel',
                style: TextStyle(color: Colors.black54),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () async {
                try {
                  await _dbHelper.deleteQRLog(qr.id);
                  await loadQRCodes((qrCodes, selectedQRs) {
                    setState(() {
                      this.qrCodes = qrCodes;
                      this.selectedQRs = selectedQRs;
                      filterQRCodes('');
                    });
                  });

                  Navigator.of(context).pop();
                  CustomSnackBar.show(
                    context,
                    'QR code deleted successfully',
                    isSuccess: true,
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  CustomSnackBar.show(
                    context,
                    'Failed to delete QR code: $e',
                    isSuccess: false,
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }
}
