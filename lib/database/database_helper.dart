import 'dart:io';
import 'package:dart_duckdb/dart_duckdb.dart';
import 'package:dart_duckdb/open.dart';
import '../models/qr_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  Database? _db;
  Connection? _conn;

  /// Getter to match old sqflite style
  Future<Connection> get database async {
    if (_conn != null) return _conn!;
    await initDatabase();
    return _conn!;
  }

  /// Initialize DuckDB database file
  Future<void> initDatabase({String dbFile = 'qr_manager.duckdb'}) async {
    // Android: load libduckdb.so from jniLibs
    if (Platform.isAndroid) {
      open.overrideFor(OperatingSystem.android, 'libduckdb.so');
    }

    _db = await duckdb.open(dbFile);
    _conn = await duckdb.connect(_db!);

    // Create table if not exists
    await _conn!.execute('''
      CREATE TABLE IF NOT EXISTS qr_logs (
        id TEXT PRIMARY KEY,
        name TEXT,
        email TEXT,
        year TEXT
      )
    ''');
  }

  /// Reset (delete) database file
  Future<void> resetDatabase({String dbFile = 'qr_manager.duckdb'}) async {
    await close();
    final file = File(dbFile);
    if (file.existsSync()) {
      file.deleteSync();
    }
    await initDatabase(dbFile: dbFile);
  }

  /// Insert or replace a QR log
  Future<void> insertQRLog(QRModel qr) async {
    final conn = await database;
    print('Inserting QRLog: ${qr.toMap()}');
    await conn.execute('''
      INSERT OR REPLACE INTO qr_logs (id, name, email, year)
      VALUES ('${qr.id}', '${qr.name}', '${qr.email}', '${qr.year}')
    ''');
  }

  /// Get all QR logs
  Future<List<QRModel>> getQRLogs() async {
    final conn = await database;
    final rs = await conn.query('SELECT id, name, email, year FROM qr_logs');
    final rows = rs.fetchAll();

    return rows.map((row) {
      return QRModel(
        id: row[0] as String,
        name: row[1] as String,
        email: row[2] as String,
        year: row[3] as String,
      );
    }).toList();
  }

  /// Update a QR log
  Future<void> updateQRLog(QRModel qr) async {
    final conn = await database;
    print('Updating QRLog: ${qr.toMap()}');
    await conn.execute('''
      UPDATE qr_logs
      SET name='${qr.name}', email='${qr.email}', year='${qr.year}'
      WHERE id='${qr.id}'
    ''');
  }

  /// Delete a QR log
  Future<void> deleteQRLog(String id) async {
    final conn = await database;
    print('Deleting QRLog with ID: $id');
    await conn.execute('DELETE FROM qr_logs WHERE id = \'$id\'');
  }

  /// Close connection and database
  Future<void> close() async {
    await _conn?.dispose();
    await _db?.dispose();
    _conn = null;
    _db = null;
  }
}
