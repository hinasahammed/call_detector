// database_helper.dart
import 'dart:async';
import 'package:call_detector/call_data.dart';
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
      version: 1,
      onCreate: (Database db, int version) async {
        await db.execute('''
          CREATE TABLE calls (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            number TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            duration INTEGER NOT NULL,
            type TEXT NOT NULL,
            created_at DATETIME DEFAULT CURRENT_TIMESTAMP
          )
        ''');
      },
    );
  }

  Future<int> insertCall(CallData call) async {
    final Database db = await database;
    
    return await db.insert(
      'calls',
      {
        'number': call.number,
        'timestamp': call.timestamp.toIso8601String(),
        'duration': call.duration.inSeconds,
        'type': call.type,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<CallData>> getAllCalls() async {
    final Database db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'calls',
      orderBy: 'timestamp DESC',
      limit: 100, // Limit to last 100 calls
    );

    return List.generate(maps.length, (i) {
      return CallData(
        number: maps[i]['number'],
        timestamp: DateTime.parse(maps[i]['timestamp']),
        duration: Duration(seconds: maps[i]['duration']),
        type: maps[i]['type'],
      );
    });
  }

  Future<List<CallData>> getCallsByDate(DateTime date) async {
    final Database db = await database;
    
    String startDate = DateTime(date.year, date.month, date.day).toIso8601String();
    String endDate = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'calls',
      where: 'timestamp >= ? AND timestamp <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'timestamp DESC',
    );

    return List.generate(maps.length, (i) {
      return CallData(
        number: maps[i]['number'],
        timestamp: DateTime.parse(maps[i]['timestamp']),
        duration: Duration(seconds: maps[i]['duration']),
        type: maps[i]['type'],
      );
    });
  }

  Future<int> deleteCall(String number, DateTime timestamp) async {
    final Database db = await database;
    
    return await db.delete(
      'calls',
      where: 'number = ? AND timestamp = ?',
      whereArgs: [number, timestamp.toIso8601String()],
    );
  }

  Future<int> deleteAllCalls() async {
    final Database db = await database;
    
    return await db.delete('calls');
  }

  Future<int> getCallCount() async {
    final Database db = await database;
    
    int? count = Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM calls'));
    return count ?? 0;
  }

  Future<void> close() async {
    final Database db = await database;
    db.close();
  }
}