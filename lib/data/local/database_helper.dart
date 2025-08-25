import 'dart:async';
import 'package:call_detector/model/call_data_model.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'call_detector.db');

    return await openDatabase(
      path,
      version: 5, // Increment version for new migration
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE calls (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            number TEXT NOT NULL,
            date TEXT NOT NULL,
            time TEXT NOT NULL,
            duration INTEGER NOT NULL,
            username TEXT,
            customerCode TEXT,
            status INTEGER DEFAULT -1,
            serviceStatus INTEGER DEFAULT -1,
            synced INTEGER DEFAULT 0,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
      onUpgrade: (Database db, int oldVersion, int newVersion) async {
        if (oldVersion < 2) {
          // Add username column to existing table
          await db.execute('ALTER TABLE calls ADD COLUMN username TEXT');
        }
        if (oldVersion < 3) {
          // Add status and serviceStatus columns, remove type column
          await db.execute(
            'ALTER TABLE calls ADD COLUMN status INTEGER DEFAULT -1',
          );
          await db.execute(
            'ALTER TABLE calls ADD COLUMN serviceStatus INTEGER DEFAULT -1',
          );

          // Create new table without type column
          await db.execute('''
            CREATE TABLE calls_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              number TEXT NOT NULL,
              timestamp TEXT NOT NULL,
              duration INTEGER NOT NULL,
              username TEXT,
              status INTEGER DEFAULT -1,
              serviceStatus INTEGER DEFAULT -1,
              created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
          ''');

          // Copy data from old table to new table (excluding type column)
          await db.execute('''
            INSERT INTO calls_new (id, number, timestamp, duration, username, status, serviceStatus, created_at)
            SELECT id, number, timestamp, duration, username, status, serviceStatus, created_at FROM calls
          ''');

          // Drop old table and rename new table
          await db.execute('DROP TABLE calls');
          await db.execute('ALTER TABLE calls_new RENAME TO calls');
        }
        if (oldVersion < 4) {
          // Add synced column
          await db.execute(
            'ALTER TABLE calls ADD COLUMN synced INTEGER DEFAULT 0',
          );
        }
        if (oldVersion < 5) {
          // Add customerCode column and split timestamp into date and time
          await db.execute('ALTER TABLE calls ADD COLUMN customerCode TEXT');
          await db.execute('ALTER TABLE calls ADD COLUMN date TEXT');
          await db.execute('ALTER TABLE calls ADD COLUMN time TEXT');

          // Migrate existing timestamp data to date and time columns
          final List<Map<String, dynamic>> existingCalls = await db.query(
            'calls',
          );
          for (final call in existingCalls) {
            if (call['timestamp'] != null) {
              try {
                final DateTime dt = DateTime.parse(call['timestamp']);
                final String date =
                    '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
                final String time =
                    '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}:${dt.second.toString().padLeft(2, '0')}';

                await db.update(
                  'calls',
                  {'date': date, 'time': time},
                  where: 'id = ?',
                  whereArgs: [call['id']],
                );
              } catch (e) {
                // If parsing fails, use current date/time
                final DateTime now = DateTime.now();
                final String date =
                    '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
                final String time =
                    '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

                await db.update(
                  'calls',
                  {'date': date, 'time': time},
                  where: 'id = ?',
                  whereArgs: [call['id']],
                );
              }
            }
          }

          // Make date and time columns NOT NULL after migration
          await db.execute('''
            CREATE TABLE calls_new (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              number TEXT NOT NULL,
              date TEXT NOT NULL,
              time TEXT NOT NULL,
              duration INTEGER NOT NULL,
              username TEXT,
              customerCode TEXT,
              status INTEGER DEFAULT -1,
              serviceStatus INTEGER DEFAULT -1,
              synced INTEGER DEFAULT 0,
              created_at DATETIME DEFAULT CURRENT_TIMESTAMP
            )
          ''');

          // Copy all data to new table
          await db.execute('''
            INSERT INTO calls_new (id, number, date, time, duration, username, customerCode, status, serviceStatus, synced, created_at)
            SELECT id, number, date, time, duration, username, customerCode, status, serviceStatus, synced, created_at FROM calls
          ''');

          // Drop old table and rename new table
          await db.execute('DROP TABLE calls');
          await db.execute('ALTER TABLE calls_new RENAME TO calls');
        }
      },
    );
  }

  Future<int> insertCall(CallData call) async {
    final Database db = await database;

    return await db.insert('calls', {
      'number': call.number,
      'date': call.date,
      'time': call.time,
      'duration': call.duration,
      'username': call.username,
      'customerCode': call.customerCode,
      'status': call.status,
      'serviceStatus': call.serviceStatus,
      'synced': call.synced ? 1 : 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // Get unsynced calls
  Future<List<CallData>> getUnsyncedCalls() async {
    final Database db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'calls',
      where: 'synced = ?',
      whereArgs: [0],
      orderBy: 'date ASC, time ASC',
    );

    return List.generate(maps.length, (i) {
      return CallData(
        number: maps[i]['number'],
        date: maps[i]['date'],
        time: maps[i]['time'],
        duration: Duration(seconds: maps[i]['duration']).toString(),
        username: maps[i]['username'],
        customerCode: maps[i]['customerCode'],
        status: maps[i]['status'] ?? -1,
        serviceStatus: maps[i]['serviceStatus'] ?? -1,
        synced: false,
      );
    });
  }

  // Update only the synced field
  Future<int> updateSyncStatus(
    String number,
    String date,
    String time,
    bool synced,
  ) async {
    final Database db = await database;

    return await db.update(
      'calls',
      {'synced': synced ? 1 : 0},
      where: 'number = ? AND date = ? AND time = ?',
      whereArgs: [number, date, time],
    );
  }

  // Delete a specific call log (only if synced)
  Future<int> deleteSyncedCall(
    String number,
    String date,
    String time,
  ) async {
    final Database db = await database;

    return await db.delete(
      'calls',
      where: 'number = ? AND date = ? AND time = ? AND synced = ?',
      whereArgs: [number, date, time, 1], // Only delete if synced = 1 (true)
    );
  }

  // Delete all synced calls
  Future<int> deleteAllSyncedCalls() async {
    final Database db = await database;

    return await db.delete(
      'calls',
      where: 'synced = ?',
      whereArgs: [1], // Only delete synced calls
    );
  }

  // Get synced calls (for verification purposes)
  Future<List<CallData>> getSyncedCalls() async {
    final Database db = await database;

    final List<Map<String, dynamic>> maps = await db.query(
      'calls',
      where: 'synced = ?',
      whereArgs: [1],
      orderBy: 'date ASC, time ASC',
    );

    return List.generate(maps.length, (i) {
      return CallData(
        number: maps[i]['number'],
        date: maps[i]['date'],
        time: maps[i]['time'],
        duration: Duration(seconds: maps[i]['duration']).toString(),
        username: maps[i]['username'],
        customerCode: maps[i]['customerCode'],
        status: maps[i]['status'] ?? -1,
        serviceStatus: maps[i]['serviceStatus'] ?? -1,
        synced: true,
      );
    });
  }

  // Get total count of calls
  Future<int> getCallCount({bool? synced}) async {
    final Database db = await database;

    if (synced != null) {
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM calls WHERE synced = ?',
        [synced ? 1 : 0],
      );
      return result.first['count'] as int;
    } else {
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM calls');
      return result.first['count'] as int;
    }
  }

  Future<void> close() async {
    final Database db = await database;
    db.close();
  }
}