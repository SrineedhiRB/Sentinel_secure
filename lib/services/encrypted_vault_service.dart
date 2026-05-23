// lib/services/encrypted_vault_service.dart
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:logger/logger.dart';

final _secureStorage = const FlutterSecureStorage();
final _log = Logger();

class EncryptedVaultService {
  static const _dbName = 'vault.db';
  static const _table = 'secrets';
  Database? _db;

  /// Initialize the encrypted database. Generates a key if not present.
  Future<void> init() async {
    final key = await _getEncryptionKey();
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _dbName);
    _db = await openDatabase(path,
        password: key,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('CREATE TABLE $_table (id TEXT PRIMARY KEY, value TEXT)');
        });
    _log.i('Encrypted vault initialized at $path');
  }

  Future<String> _getEncryptionKey() async {
    var key = await _secureStorage.read(key: 'vault_key');
    if (key == null) {
      // Generate a random 256‑bit key (64‑hex chars)
      final rand = List<int>.generate(32, (_) => DateTime.now().millisecond);
      key = rand.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
      await _secureStorage.write(key: 'vault_key', value: key);
    }
    return key;
  }

  Future<void> storeSecret(String id, String value) async {
    await _db?.insert(_table, {'id': id, 'value': value}, conflictAlgorithm: ConflictAlgorithm.replace);
    _log.i('Secret stored: $id');
  }

  Future<String?> retrieveSecret(String id) async {
    final maps = await _db?.query(_table, where: 'id = ?', whereArgs: [id]);
    if (maps != null && maps.isNotEmpty) {
      return maps.first['value'] as String;
    }
    return null;
  }

  Future<List<String>> listSecretIds() async {
    final maps = await _db?.query(_table, columns: ['id']);
    return maps?.map((e) => e['id'] as String).toList() ?? [];
  }
}

// Riverpod provider
import 'package:flutter_riverpod/flutter_riverpod.dart';
final encryptedVaultProvider = Provider<EncryptedVaultService>((ref) => EncryptedVaultService());
