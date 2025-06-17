import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/qr_model.dart';

class BulkImportScreen extends StatefulWidget {
  const BulkImportScreen({super.key});

  @override
  State<BulkImportScreen> createState() => _BulkImportScreenState();
}

class _BulkImportScreenState extends State<BulkImportScreen> {
  void _importCSV() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      final input = file.openRead();
      final fields =
          await input
              .transform(utf8.decoder)
              .transform(const CsvToListConverter())
              .toList();

      for (var row in fields.skip(1)) {
        // Assuming CSV format: name,email,gradeSection
        if (row.length >= 3) {
          final qr = QRModel(
            id: const Uuid().v4(),
            name: row[0].toString(),
            email: row[1].toString(),
            gradeSection: row[2].toString(),
          );
          await DatabaseHelper().insertQRLog(qr);
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('CSV imported successfully')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bulk Import')),
      body: Center(
        child: ElevatedButton(
          onPressed: _importCSV,
          child: const Text('Import CSV'),
        ),
      ),
    );
  }
}
