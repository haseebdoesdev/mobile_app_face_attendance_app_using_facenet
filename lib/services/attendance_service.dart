import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import '../models/attendance_record.dart';

class AttendanceService {
  static final AttendanceService _instance = AttendanceService._internal();
  late Database _database;

  factory AttendanceService() {
    return _instance;
  }

  AttendanceService._internal();

  Future<Database> get database async {
    _database = await _initializeDatabase();
    return _database;
  }

  Future<Database> _initializeDatabase() async {
    String path = join(await getDatabasesPath(), 'attendance.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE attendance (id INTEGER PRIMARY KEY, name TEXT, date TEXT, time TEXT, status TEXT)',
        );
      },
    );
  }

  Future<void> insertAttendance(AttendanceRecord record) async {
    final db = await database;
    await db.insert('attendance', record.toMap());
  }

  Future<bool> isStudentMarkedToday(String name) async {
    final db = await database;
    final today = DateTime.now().toString().split(' ')[0];
    final result = await db.query(
      'attendance',
      where: 'name = ? AND date = ?',
      whereArgs: [name, today],
    );
    return result.isNotEmpty;
  }

  Future<List<AttendanceRecord>> getTodayAttendance() async {
    final db = await database;
    final today = DateTime.now().toString().split(' ')[0];
    final maps = await db.query(
      'attendance',
      where: 'date = ?',
      whereArgs: [today],
    );
    return List.generate(maps.length, (i) => AttendanceRecord.fromMap(maps[i]));
  }

  Future<void> deleteAttendance(int id) async {
    final db = await database;
    await db.delete(
      'attendance',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteAllTodayAttendance() async {
    final db = await database;
    final today = DateTime.now().toString().split(' ')[0];
    await db.delete(
      'attendance',
      where: 'date = ?',
      whereArgs: [today],
    );
  }
}
