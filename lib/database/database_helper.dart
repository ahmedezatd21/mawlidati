

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('mawlidati.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE generators (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        location TEXT,
        capacity TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE subscribers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        phone TEXT,
        ampere REAL DEFAULT 0,
        generator_id INTEGER,
        monthly_fee REAL DEFAULT 0,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (generator_id)
          REFERENCES generators(id)
          ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        subscriber_id INTEGER,
        month INTEGER NOT NULL,
        year INTEGER NOT NULL,
        amount REAL DEFAULT 0,
        paid_amount REAL DEFAULT 0,
        status TEXT DEFAULT 'غير مدفوع',
        created_at TEXT NOT NULL,
        FOREIGN KEY (subscriber_id)
          REFERENCES subscribers(id)
          ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        notes TEXT,
        date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');
  }

  // المولدات

  Future<int> insertGenerator(Map<String, dynamic> data) async {
    final db = await database;
    data['created_at'] ??= DateTime.now().toIso8601String();
    return await db.insert('generators', data);
  }

  Future<List<Map<String, dynamic>>> getGenerators() async {
    final db = await database;
    return await db.query('generators', orderBy: 'id DESC');
  }

  Future<int> updateGenerator(
    int id,
    Map<String, dynamic> data,
  ) async {
    final db = await database;
    return await db.update(
      'generators',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteGenerator(int id) async {
    final db = await database;
    return await db.delete(
      'generators',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // المشتركون

  Future<int> insertSubscriber(Map<String, dynamic> data) async {
    final db = await database;
    data['created_at'] ??= DateTime.now().toIso8601String();
    return await db.insert('subscribers', data);
  }

  Future<List<Map<String, dynamic>>> getSubscribers() async {
    final db = await database;
    return await db.query('subscribers', orderBy: 'id DESC');
  }

  Future<int> updateSubscriber(
    int id,
    Map<String, dynamic> data,
  ) async {
    final db = await database;
    return await db.update(
      'subscribers',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSubscriber(int id) async {
    final db = await database;
    return await db.delete(
      'subscribers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // الفواتير

  Future<int> insertInvoice(Map<String, dynamic> data) async {
    final db = await database;
    data['created_at'] ??= DateTime.now().toIso8601String();
    return await db.insert('invoices', data);
  }

  Future<List<Map<String, dynamic>>> getInvoices() async {
    final db = await database;
    return await db.query('invoices', orderBy: 'id DESC');
  }

  Future<int> updateInvoice(
    int id,
    Map<String, dynamic> data,
  ) async {
    final db = await database;
    return await db.update(
      'invoices',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteInvoice(int id) async {
    final db = await database;
    return await db.delete(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // المصاريف

  Future<int> insertExpense(Map<String, dynamic> data) async {
    final db = await database;
    data['created_at'] ??= DateTime.now().toIso8601String();
    data['date'] ??= DateTime.now().toIso8601String();

    return await db.insert('expenses', data);
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    final db = await database;
    return await db.query('expenses', orderBy: 'id DESC');
  }

  Future<int> updateExpense(
    int id,
    Map<String, dynamic> data,
  ) async {
    final db = await database;
    return await db.update(
      'expenses',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
