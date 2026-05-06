import 'package:sqlite3/sqlite3.dart' as sql;
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

/// Global database path. Set once at startup.
late String _dbPath;

/// The UUID generator.
final _uuid = Uuid();

/// Opens a fresh SQLite connection. Caller must call .dispose() when done.
sql.Database openDatabase() {
  final db = sql.sqlite3.open(_dbPath);
  db.execute('PRAGMA foreign_keys=ON');
  return db;
}

/// Hash a password with a salt using SHA-256.
String hashPassword(String password) {
  final bytes = utf8.encode(password + 'pho_saigon_1975_salt');
  return sha256.convert(bytes).toString();
}

/// Generate a UUID v4.
String generateId() => _uuid.v4();

/// Initialize database: create tables, ensure admin exists.
void initializeDatabase(String path) {
  _dbPath = path;
  final db = sql.sqlite3.open(path);
  db.execute('PRAGMA journal_mode=WAL');
  db.execute('PRAGMA foreign_keys=ON');

  db.execute('''
    CREATE TABLE IF NOT EXISTS admin_users (
      id TEXT PRIMARY KEY,
      username TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    )
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS sessions (
      token TEXT PRIMARY KEY,
      user_id TEXT NOT NULL,
      expires_at TEXT NOT NULL,
      FOREIGN KEY (user_id) REFERENCES admin_users(id)
    )
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS categories (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      sort_order INTEGER NOT NULL DEFAULT 0
    )
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS menu_items (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      description TEXT DEFAULT '',
      price INTEGER NOT NULL,
      image_url TEXT DEFAULT '',
      category_id TEXT NOT NULL,
      is_popular INTEGER NOT NULL DEFAULT 0,
      is_available INTEGER NOT NULL DEFAULT 1,
      sort_order INTEGER NOT NULL DEFAULT 0,
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      FOREIGN KEY (category_id) REFERENCES categories(id)
    )
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS orders (
      id TEXT PRIMARY KEY,
      table_number INTEGER NOT NULL,
      customer_name TEXT NOT NULL DEFAULT 'Khach',
      status TEXT NOT NULL DEFAULT 'pending',
      total INTEGER NOT NULL DEFAULT 0,
      note TEXT DEFAULT '',
      created_at TEXT NOT NULL DEFAULT (datetime('now')),
      updated_at TEXT NOT NULL DEFAULT (datetime('now'))
    )
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS order_items (
      id TEXT PRIMARY KEY,
      order_id TEXT NOT NULL,
      menu_item_id TEXT NOT NULL,
      menu_item_name TEXT NOT NULL,
      quantity INTEGER NOT NULL DEFAULT 1,
      price INTEGER NOT NULL,
      note TEXT DEFAULT '',
      FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
    )
  ''');

  db.execute('''
    CREATE TABLE IF NOT EXISTS reviews (
      id TEXT PRIMARY KEY,
      order_id TEXT,
      table_number INTEGER NOT NULL,
      rating INTEGER NOT NULL,
      comment TEXT DEFAULT '',
      created_at TEXT NOT NULL DEFAULT (datetime('now'))
    )
  ''');

  // Ensure admin
  final result = db.select('SELECT COUNT(*) as cnt FROM admin_users');
  if (result.first['cnt'] == 0) {
    final id = generateId();
    final hash = hashPassword('pho2025');
    db.execute(
      'INSERT INTO admin_users (id, username, password_hash) VALUES (?, ?, ?)',
      [id, 'admin', hash],
    );
    print('  ✅ Default admin created: admin / pho2025');
  }

  db.dispose();
  print('  📁 Database initialized: $path');
}
