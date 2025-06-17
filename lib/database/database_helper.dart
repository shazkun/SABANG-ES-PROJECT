import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/qr_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await initDatabase();
    return _database!;
  }

  Future<Database> initDatabase() async {
    String path = join(await getDatabasesPath(), 'qr_manager.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE qr_logs (
            id TEXT PRIMARY KEY,
            name TEXT,
            email TEXT,
            gradeSection TEXT,
            timestamp TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertQRLog(QRModel qr) async {
    final db = await database;
    await db.insert('qr_logs', {
      ...qr.toJson(),
      'timestamp': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<QRModel>> getQRLogs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('qr_logs');
    return List.generate(maps.length, (i) => QRModel.fromJson(maps[i]));
  }
}
