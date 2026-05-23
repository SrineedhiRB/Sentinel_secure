// lib/services/vault_service.dart
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Simple encrypted key‑value vault.
/// Data is stored in an encrypted SQLite DB (SQLCipher) with a
/// hard‑coded passphrase for the demo (in production replace with
/// a device‑bound secret).
class VaultService {
  static const _dbName = 'secure_vault.db';
  static const _tableName = 'vault';
  static const _passphrase = 'SentinelSecurePassphrase123!';

  Database? _db;

  Future<Database> _getDb() async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, _dbName);
    _db = await openDatabase(
      path,
      password: _passphrase,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE $_tableName (
            id TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            createdAt INTEGER NOT NULL
          )
        ''');
      },
    );
    return _db!;
  }

  Future<void> putItem(String id, String value) async {
    final db = await _getDb();
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      _tableName,
      {'id': id, 'value': _encrypt(value), 'createdAt': now},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> getItem(String id) async {
    final db = await _getDb();
    final rows = await db.query(
      _tableName,
      columns: ['value'],
      where: 'id = ?',
      whereArgs: [id],
    );
    if (rows.isEmpty) return null;
    return _decrypt(rows.first['value'] as String);
  }

  Future<List<Map<String, dynamic>>> getAllItems() async {
    final db = await _getDb();
    final rows = await db.query(
      _tableName,
      columns: ['id', 'value', 'createdAt'],
      orderBy: 'createdAt DESC',
    );
    return rows
        .map((e) => {
              'id': e['id'],
              'value': _decrypt(e['value'] as String),
              'createdAt': DateTime.fromMillisecondsSinceEpoch(e['createdAt'] as int),
            })
        .toList();
  }

  Future<void> deleteItem(String id) async {
    final db = await _getDb();
    await db.delete(_tableName, where: 'id = ?', whereArgs: [id]);
  }

  // Simple XOR‑based encryption for demo (replace with proper AES in prod).
  String _encrypt(String plain) {
    final keyBytes = md5.convert(utf8.encode(_passphrase)).bytes;
    final plainBytes = utf8.encode(plain);
    final encrypted = List<int>.generate(
      plainBytes.length,
      (i) => plainBytes[i] ^ keyBytes[i % keyBytes.length],
    );
    return base64Encode(encrypted);
  }

  String _decrypt(String cipher) {
    final keyBytes = md5.convert(utf8.encode(_passphrase)).bytes;
    final cipherBytes = base64Decode(cipher);
    final decrypted = List<int>.generate(
      cipherBytes.length,
      (i) => cipherBytes[i] ^ keyBytes[i % keyBytes.length],
    );
    return utf8.decode(decrypted);
  }
}
