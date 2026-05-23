import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:path/path.dart';
import '../security/security_service.dart';
import '../../models/app_models.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'sentinel_vault.db');
    
    // Get secure high-entropy master key for DB password from SecurityService
    final password = await SecurityService().getOrGenerateMasterKey();

    return await openDatabase(
      path,
      password: password,
      version: 1,
      onCreate: (db, version) async {
        // Users table
        await db.execute('''
          CREATE TABLE users (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            role TEXT NOT NULL,
            embedding TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');

        // Audit Logs table with detailed spoofing and environment logs
        await db.execute('''
          CREATE TABLE audit_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT,
            status TEXT NOT NULL,
            confidence REAL NOT NULL,
            liveness_score REAL NOT NULL,
            spoof_details TEXT,
            timestamp TEXT NOT NULL,
            gps_lat REAL,
            gps_lng REAL,
            device_id TEXT NOT NULL
          )
        ''');

        // Seed with a default Administrator, Officer, and Contractor for demo purposes
        await _seedMockUsers(db);
      },
    );
  }

  Future<void> _seedMockUsers(Database db) async {
    // Generate simulated 128-dimensional embeddings
    final adminEmbedding = List<double>.generate(128, (i) => i == 5 ? 0.8 : 0.05);
    final officerEmbedding = List<double>.generate(128, (i) => i == 10 ? 0.85 : 0.02);
    final contractorEmbedding = List<double>.generate(128, (i) => i == 20 ? 0.9 : -0.01);

    final security = SecurityService();
    
    // We encrypt embeddings using AES-256 for double protection before writing to the encrypted database
    final adminEnc = await security.encryptData(AppUser(
      id: 'NHAI-ADM-001',
      name: 'Dr. Rajesh Sharma',
      role: 'Admin',
      embedding: adminEmbedding,
      createdAt: DateTime.now(),
    ).toMap()['embedding']);

    final officerEnc = await security.encryptData(AppUser(
      id: 'NHAI-OFC-072',
      name: 'Inspector Vikram Singh',
      role: 'Highway Officer',
      embedding: officerEmbedding,
      createdAt: DateTime.now(),
    ).toMap()['embedding']);

    final contractorEnc = await security.encryptData(AppUser(
      id: 'NHAI-CON-940',
      name: 'Amit Patel (GMR Infra)',
      role: 'Contractor',
      embedding: contractorEmbedding,
      createdAt: DateTime.now(),
    ).toMap()['embedding']);

    await db.insert('users', {
      'id': 'NHAI-ADM-001',
      'name': 'Dr. Rajesh Sharma',
      'role': 'Admin',
      'embedding': adminEnc,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('users', {
      'id': 'NHAI-OFC-072',
      'name': 'Inspector Vikram Singh',
      'role': 'Highway Officer',
      'embedding': officerEnc,
      'created_at': DateTime.now().toIso8601String(),
    });

    await db.insert('users', {
      'id': 'NHAI-CON-940',
      'name': 'Amit Patel (GMR Infra)',
      'role': 'Contractor',
      'embedding': contractorEnc,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // --- CRUD Operations ---

  Future<void> saveUser(AppUser user) async {
    final db = await database;
    final security = SecurityService();
    
    // Double encryption: encrypt the embedding string
    final rawEmbeddingStr = user.toMap()['embedding'];
    final encryptedEmbedding = await security.encryptData(rawEmbeddingStr);

    await db.insert('users', {
      'id': user.id,
      'name': user.name,
      'role': user.role,
      'embedding': encryptedEmbedding,
      'created_at': user.createdAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<List<AppUser>> getAllUsers() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users');
    final security = SecurityService();

    final List<AppUser> users = [];
    for (var map in maps) {
      try {
        final decryptedEmbedding = await security.decryptData(map['embedding']);
        users.add(AppUser(
          id: map['id'],
          name: map['name'],
          role: map['role'],
          embedding: List<double>.from(decryptedEmbedding
              .replaceFirst('[', '')
              .replaceFirst(']', '')
              .split(',')
              .map((e) => double.parse(e.trim()))),
          createdAt: DateTime.parse(map['created_at']),
        ));
      } catch (e) {
        print("Error decrypting user data: $e");
      }
    }
    return users;
  }

  Future<void> deleteUser(String userId) async {
    final db = await database;
    await db.delete('users', where: 'id = ?', whereArgs: [userId]);
  }

  Future<void> logAuthAttempt(AuditLog log) async {
    final db = await database;
    await db.insert('audit_logs', log.toMap());
  }
  
  Future<List<AuditLog>> getAuditLogs() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('audit_logs', orderBy: 'timestamp DESC');
    
    return List.generate(maps.length, (i) {
      return AuditLog(
        id: maps[i]['id'],
        userId: maps[i]['user_id'],
        status: maps[i]['status'],
        confidence: maps[i]['confidence'],
        livenessScore: maps[i]['liveness_score'],
        spoofDetails: maps[i]['spoof_details'],
        timestamp: DateTime.parse(maps[i]['timestamp']),
        lat: maps[i]['gps_lat'],
        lng: maps[i]['gps_lng'],
        deviceId: maps[i]['device_id'] ?? 'UNKNOWN',
      );
    });
  }

  Future<List<AuditLog>> searchAuditLogs(String query) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'audit_logs',
      where: 'user_id LIKE ? OR status LIKE ? OR spoof_details LIKE ?',
      whereArgs: ['%$query%', '%$query%', '%$query%'],
      orderBy: 'timestamp DESC',
    );
    
    return List.generate(maps.length, (i) {
      return AuditLog(
        id: maps[i]['id'],
        userId: maps[i]['user_id'],
        status: maps[i]['status'],
        confidence: maps[i]['confidence'],
        livenessScore: maps[i]['liveness_score'],
        spoofDetails: maps[i]['spoof_details'],
        timestamp: DateTime.parse(maps[i]['timestamp']),
        lat: maps[i]['gps_lat'],
        lng: maps[i]['gps_lng'],
        deviceId: maps[i]['device_id'] ?? 'UNKNOWN',
      );
    });
  }

  Future<void> clearAuditLogs() async {
    final db = await database;
    await db.delete('audit_logs');
  }
}
