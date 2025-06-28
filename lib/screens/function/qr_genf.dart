import 'package:flutter/material.dart';
import 'package:sabang_es/database/database_helper.dart';
import 'package:sabang_es/models/qr_model.dart';
import 'package:uuid/uuid.dart';
import 'package:file_picker/file_picker.dart';
import 'package:csv/csv.dart';
import 'dart:io';
import 'package:excel/excel.dart';

class QRGenerateFunctions {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final gradeSectionController = TextEditingController();
  QRModel? qrModel;

  void initControllers() {
    nameController.clear();
    emailController.clear();
    gradeSectionController.clear();
    qrModel = null;
  }

  void dispose() {
    nameController.dispose();
    emailController.dispose();
    gradeSectionController.dispose();
  }

  Future<void> generateQR(BuildContext context) async {
    final qr = QRModel(
      id: const Uuid().v4(),
      name: nameController.text,
      email: emailController.text,
      gradeSection: gradeSectionController.text,
    );
    await DatabaseHelper().insertQRLog(qr);
    qrModel = qr;
  }

  String encodeQRData(QRModel qr) {
    return '${qr.id}|${qr.name}|${qr.email}|${qr.gradeSection}';
  }

  Future<List<QRModel>> generateBatchQR(BuildContext context) async {
    List<QRModel> generatedQRs = [];

    try {
      // Pick CSV or Excel file
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx'],
      );

      if (result == null || result.files.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No file selected')));
        return generatedQRs;
      }

      final file = File(result.files.single.path!);
      final extension = result.files.single.extension?.toLowerCase();

      if (extension == 'csv') {
        // Process CSV file
        final input = await file.readAsString();
        final csvRows = const CsvToListConverter().convert(input);

        // Skip header row and process data
        for (var row in csvRows.skip(1)) {
          if (row.length >= 3) {
            final qr = QRModel(
              id: const Uuid().v4(),
              name: row[0]?.toString() ?? '',
              email: row[1]?.toString() ?? '',
              gradeSection: row[2]?.toString() ?? '',
            );
            await DatabaseHelper().insertQRLog(qr);
            generatedQRs.add(qr);
          }
        }
      } else if (extension == 'xlsx') {
        // Process Excel file
        final bytes = await file.readAsBytes();
        final excel = Excel.decodeBytes(bytes);

        // Assume data is in the first sheet
        final sheet = excel.tables.keys.first;
        final rows = excel.tables[sheet]!.rows;

        // Skip header row and process data
        for (var row in rows.skip(1)) {
          if (row.length >= 3) {
            final qr = QRModel(
              id: const Uuid().v4(),
              name: row[0]?.value?.toString() ?? '',
              email: row[1]?.value?.toString() ?? '',
              gradeSection: row[2]?.value?.toString() ?? '',
            );
            await DatabaseHelper().insertQRLog(qr);
            generatedQRs.add(qr);
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Generated ${generatedQRs.length} QR codes')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error processing file: $e')));
    }

    return generatedQRs;
  }
}
