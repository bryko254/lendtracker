import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LendDatabase {
  LendDatabase._();

  static final LendDatabase instance = LendDatabase._();

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) {
      return existing;
    }
    final db = await _initDb();
    _database = db;
    return db;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'lendtracker.db');
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE borrowers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phone TEXT,
            notes TEXT,
            created_at INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE loans (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            borrower_id INTEGER NOT NULL,
            principal_minor INTEGER NOT NULL,
            lent_date INTEGER NOT NULL,
            due_date INTEGER,
            notes TEXT,
            status TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            FOREIGN KEY (borrower_id) REFERENCES borrowers(id) ON DELETE CASCADE
          )
        ''');
        await db.execute('''
          CREATE TABLE repayments (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            loan_id INTEGER NOT NULL,
            amount_minor INTEGER NOT NULL,
            date INTEGER NOT NULL,
            method TEXT,
            notes TEXT,
            created_at INTEGER NOT NULL,
            FOREIGN KEY (loan_id) REFERENCES loans(id) ON DELETE CASCADE
          )
        ''');
      },
    );
  }
}
