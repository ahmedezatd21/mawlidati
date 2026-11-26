
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
      version: 5,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE generators ADD COLUMN amp_price REAL DEFAULT 0',
          );
        }

        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE payments (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              invoice_id INTEGER NOT NULL,
              amount REAL NOT NULL,
              date TEXT NOT NULL,
              notes TEXT,
              created_at TEXT NOT NULL,
              FOREIGN KEY (invoice_id)
                REFERENCES invoices(id)
                ON DELETE CASCADE
            )
          ''');
        }

        if (oldVersion < 5) {
          await db.execute('''
            CREATE TABLE app_license (
              id INTEGER PRIMARY KEY CHECK (id = 1),
              owner_id TEXT NOT NULL,
              license_token TEXT NOT NULL,
              expiry_date TEXT NOT NULL,
              last_verified_at TEXT NOT NULL,
              status TEXT NOT NULL
            )
          ''');
        }
      },
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE generators (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        location TEXT,
        capacity TEXT,
        amp_price REAL DEFAULT 0,
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

    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (invoice_id)
          REFERENCES invoices(id)
          ON DELETE CASCADE
      )
    ''');

    // جدول ترخيص التطبيق
    await db.execute('''
      CREATE TABLE app_license (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        owner_id TEXT NOT NULL,
        license_token TEXT NOT NULL,
        expiry_date TEXT NOT NULL,
        last_verified_at TEXT NOT NULL,
        status TEXT NOT NULL
      )
    ''');
  }

  // =========================
  // المولدات
  // =========================

  Future<int> insertGenerator(Map<String, dynamic> data) async {
    final db = await database;
    data['created_at'] ??= DateTime.now().toIso8601String();
    return db.insert('generators', data);
  }

  Future<List<Map<String, dynamic>>> getGenerators() async {
    final db = await database;
    return db.query('generators', orderBy: 'id DESC');
  }

  Future<int> updateGenerator(
    int id,
    Map<String, dynamic> data,
  ) async {
    final db = await database;
    return db.update(
      'generators',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteGenerator(int id) async {
    final db = await database;
    return db.delete(
      'generators',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================
  // المشتركون
  // =========================

  Future<int> insertSubscriber(Map<String, dynamic> data) async {
    final db = await database;
    data['created_at'] ??= DateTime.now().toIso8601String();
    return db.insert('subscribers', data);
  }

  Future<List<Map<String, dynamic>>> getSubscribers() async {
    final db = await database;
    return db.query('subscribers', orderBy: 'id DESC');
  }

  Future<int> updateSubscriber(
    int id,
    Map<String, dynamic> data,
  ) async {
    final db = await database;
    return db.update(
      'subscribers',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteSubscriber(int id) async {
    final db = await database;
    return db.delete(
      'subscribers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================
  // الفواتير
  // =========================

  Future<int> insertInvoice(Map<String, dynamic> data) async {
    final db = await database;
    data['created_at'] ??= DateTime.now().toIso8601String();
    data['paid_amount'] ??= 0;
    data['status'] ??= 'غير مدفوع';
    return db.insert('invoices', data);
  }

  Future<List<Map<String, dynamic>>> getInvoices() async {
    final db = await database;
    return db.query(
      'invoices',
      orderBy: 'year DESC, month DESC, id DESC',
    );
  }

  Future<int> updateInvoice(
    int id,
    Map<String, dynamic> data,
  ) async {
    final db = await database;
    return db.update(
      'invoices',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteInvoice(int id) async {
    final db = await database;
    return db.delete(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // إنشاء الفواتير الشهرية ومنع التكرار
  Future<int> createMonthlyInvoices({
    required int month,
    required int year,
    int? generatorId,
  }) async {
    final db = await database;

    return db.transaction((txn) async {
      final subscribers = await txn.query(
        'subscribers',
        where: generatorId == null
            ? null
            : 'generator_id = ?',
        whereArgs: generatorId == null ? null : [generatorId],
      );

      int createdCount = 0;

      for (final subscriber in subscribers) {
        final subscriberId = subscriber['id'] as int;
        final amount =
            (subscriber['monthly_fee'] as num?)?.toDouble() ?? 0;

        if (amount <= 0) continue;

        final existing = await txn.query(
          'invoices',
          where: 'subscriber_id = ? AND month = ? AND year = ?',
          whereArgs: [subscriberId, month, year],
          limit: 1,
        );

        if (existing.isNotEmpty) continue;

        await txn.insert('invoices', {
          'subscriber_id': subscriberId,
          'month': month,
          'year': year,
          'amount': amount,
          'paid_amount': 0,
          'status': 'غير مدفوع',
          'created_at': DateTime.now().toIso8601String(),
        });

        createdCount++;
      }

      return createdCount;
    });
  }

  // =========================
  // الدفعات
  // =========================

  String _invoiceStatus(double amount, double paid) {
    if (paid <= 0) return 'غير مدفوع';
    if (paid >= amount) return 'مدفوع';
    return 'مدفوع جزئياً';
  }

  Future<int> recordPayment(Map<String, dynamic> data) async {
    final db = await database;

    return db.transaction((txn) async {
      final invoiceId = data['invoice_id'] as int;
      final paymentAmount = (data['amount'] as num).toDouble();

      if (paymentAmount <= 0) {
        throw Exception('مبلغ الدفعة يجب أن يكون أكبر من صفر');
      }

      final invoices = await txn.query(
        'invoices',
        where: 'id = ?',
        whereArgs: [invoiceId],
        limit: 1,
      );

      if (invoices.isEmpty) {
        throw Exception('الفاتورة غير موجودة');
      }

      final invoice = invoices.first;
      final total = (invoice['amount'] as num).toDouble();
      final paid =
          (invoice['paid_amount'] as num?)?.toDouble() ?? 0;
      final remaining = total - paid;

      if (paymentAmount > remaining + 0.001) {
        throw Exception('مبلغ الدفعة أكبر من المبلغ المتبقي');
      }

      final newPaid = paid + paymentAmount;

      data['created_at'] ??= DateTime.now().toIso8601String();
      data['date'] ??= DateTime.now().toIso8601String();

      final paymentId = await txn.insert('payments', data);

      await txn.update(
        'invoices',
        {
          'paid_amount': newPaid,
          'status': _invoiceStatus(total, newPaid),
        },
        where: 'id = ?',
        whereArgs: [invoiceId],
      );

      return paymentId;
    });
  }

  Future<int> insertPayment(Map<String, dynamic> data) {
    return recordPayment(data);
  }

  Future<List<Map<String, dynamic>>> getPayments() async {
    final db = await database;
    return db.query('payments', orderBy: 'id DESC');
  }

  Future<List<Map<String, dynamic>>> getInvoicePayments(
    int invoiceId,
  ) async {
    final db = await database;
    return db.query(
      'payments',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
      orderBy: 'id DESC',
    );
  }

  Future<int> deletePayment(int id) async {
    final db = await database;

    return db.transaction((txn) async {
      final payments = await txn.query(
        'payments',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (payments.isEmpty) return 0;

      final payment = payments.first;
      final invoiceId = payment['invoice_id'] as int;
      final paymentAmount = (payment['amount'] as num).toDouble();

      final result = await txn.delete(
        'payments',
        where: 'id = ?',
        whereArgs: [id],
      );

      final invoices = await txn.query(
        'invoices',
        where: 'id = ?',
        whereArgs: [invoiceId],
        limit: 1,
      );

      if (invoices.isNotEmpty) {
        final invoice = invoices.first;
        final total = (invoice['amount'] as num).toDouble();
        final oldPaid =
            (invoice['paid_amount'] as num?)?.toDouble() ?? 0;

        final newPaid = (oldPaid - paymentAmount).clamp(0.0, total);

        await txn.update(
          'invoices',
          {
            'paid_amount': newPaid,
            'status': _invoiceStatus(total, newPaid),
          },
          where: 'id = ?',
          whereArgs: [invoiceId],
        );
      }

      return result;
    });
  }

  // =========================
  // المصاريف
  // =========================

  Future<int> insertExpense(Map<String, dynamic> data) async {
    final db = await database;
    data['created_at'] ??= DateTime.now().toIso8601String();
    data['date'] ??= DateTime.now().toIso8601String();
    return db.insert('expenses', data);
  }

  Future<List<Map<String, dynamic>>> getExpenses() async {
    final db = await database;
    return db.query('expenses', orderBy: 'date DESC, id DESC');
  }

  Future<int> updateExpense(
    int id,
    Map<String, dynamic> data,
  ) async {
    final db = await database;
    return db.update(
      'expenses',
      data,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await database;
    return db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // =========================
  // ترخيص تطبيق مولدتي
  // =========================

  Future<Map<String, dynamic>?> getLicense() async {
    final db = await database;

    final result = await db.query(
      'app_license',
      where: 'id = ?',
      whereArgs: [1],
      limit: 1,
    );

    if (result.isEmpty) return null;

    return result.first;
  }

  Future<void> saveLicense(Map<String, dynamic> data) async {
    final db = await database;

    await db.insert(
      'app_license',
      {
        'id': 1,
        'owner_id': data['owner_id'],
        'license_token': data['license_token'],
        'expiry_date': data['expiry_date'],
        'last_verified_at': data['last_verified_at'],
        'status': data['status'],
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> deleteLicense() async {
    final db = await database;

    return db.delete(
      'app_license',
      where: 'id = ?',
      whereArgs: [1],
    );
  }
}
