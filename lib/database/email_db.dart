import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/emailer_model.dart';

class EmailerDatabaseHelper {
  static final EmailerDatabaseHelper _instance =
      EmailerDatabaseHelper._internal();
  factory EmailerDatabaseHelper() => _instance;
  EmailerDatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB();
    return _database!;
  }

  Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'emailer.db');

    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE emailers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL,
            code TEXT NOT NULL
          )
        ''');
      },
    );
  }

  Future<int> insertEmailer(EmailerModel model) async {
    final db = await database;
    return await db.insert('emailers', model.toMap());
  }

  Future<List<EmailerModel>> getAllEmailers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('emailers');

    return List.generate(maps.length, (i) => EmailerModel.fromMap(maps[i]));
  }

  Future<void> deleteEmailer(int id) async {
    final db = await database;
    await db.delete('emailers', where: 'id = ?', whereArgs: [id]);
  }
}
