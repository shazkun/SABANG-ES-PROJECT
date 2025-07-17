import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/qr_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _database;

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
            year TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertQRLog(QRModel qr) async {
    final db = await database;
    print('Inserting QRLog: ${qr.toMap()}'); // Debug log
    await db.insert(
      'qr_logs',
      qr.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<QRModel>> getQRLogs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('qr_logs');
    // print('Fetched QRLogs: $maps'); // Debug log
    return List.generate(maps.length, (i) {
      return QRModel.fromMap(maps[i]);
    });
  }

  Future<void> updateQRLog(QRModel qr) async {
    final db = await database;
    print('Updating QRLog: ${qr.toMap()}'); // Debug log
    int rowsAffected = await db.update(
      'qr_logs',
      qr.toMap(),
      where: 'id = ?',
      whereArgs: [qr.id],
    );
    print('Rows affected by update: $rowsAffected'); // Debug log
    if (rowsAffected == 0) {
      print('No rows updated for ID: ${qr.id}');
    }
  }

  Future<void> deleteQRLog(String id) async {
    final db = await database;
    print('Deleting QRLog with ID: $id'); // Debug log
    int rowsAffected = await db.delete(
      'qr_logs',
      where: 'id = ?',
      whereArgs: [id],
    );
    print('Rows affected by delete: $rowsAffected'); // Debug log
  }
}
