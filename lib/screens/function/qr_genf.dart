import 'package:flutter/material.dart';
import 'package:sabang_es/database/database_helper.dart';
import 'package:sabang_es/models/qr_model.dart';
import 'package:uuid/uuid.dart';

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
}
