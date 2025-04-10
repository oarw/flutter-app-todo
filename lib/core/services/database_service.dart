import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';
import '../models/schedule.dart';
import '../models/pomodoro.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService instance = DatabaseService._init();

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('timemaster.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE tasks(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        dueDate TEXT,
        isCompleted INTEGER,
        subtasks TEXT,
        priority INTEGER,
        aiSuggestion TEXT,
        createdAt TEXT NOT NULL,
        completedAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE schedules(
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        description TEXT,
        startTime TEXT NOT NULL,
        endTime TEXT NOT NULL,
        isAllDay INTEGER,
        location TEXT,
        participants TEXT,
        isRecurring INTEGER,
        recurrenceRule TEXT,
        reminderType TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE pomodoros(
        id TEXT PRIMARY KEY,
        taskId TEXT NOT NULL,
        startTime TEXT NOT NULL,
        endTime TEXT,
        duration INTEGER NOT NULL,
        isBreak INTEGER,
        isCompleted INTEGER,
        notes TEXT,
        createdAt TEXT NOT NULL
      )
    ''');
  }

  // Task CRUD operations
  Future<String> createTask(Task task) async {
    final db = await database;
    await db.insert('tasks', task.toMap());
    return task.id;
  }

  Future<Task?> getTask(String id) async {
    final db = await database;
    final maps = await db.query('tasks', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Task.fromMap(maps.first);
  }

  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final result = await db.query('tasks', orderBy: 'createdAt DESC');
    return result.map((map) => Task.fromMap(map)).toList();
  }

  Future<int> updateTask(Task task) async {
    final db = await database;
    return db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]);
  }

  Future<int> deleteTask(String id) async {
    final db = await database;
    return await db.delete('tasks', where: 'id = ?', whereArgs: [id]);
  }

  // Schedule CRUD operations
  Future<String> createSchedule(Schedule schedule) async {
    final db = await database;
    await db.insert('schedules', schedule.toMap());
    return schedule.id;
  }

  Future<Schedule?> getSchedule(String id) async {
    final db = await database;
    final maps = await db.query('schedules', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Schedule.fromMap(maps.first);
  }

  Future<List<Schedule>> getAllSchedules() async {
    final db = await database;
    final result = await db.query('schedules', orderBy: 'startTime DESC');
    return result.map((map) => Schedule.fromMap(map)).toList();
  }

  Future<int> updateSchedule(Schedule schedule) async {
    final db = await database;
    return db.update('schedules', schedule.toMap(), where: 'id = ?', whereArgs: [schedule.id]);
  }

  Future<int> deleteSchedule(String id) async {
    final db = await database;
    return await db.delete('schedules', where: 'id = ?', whereArgs: [id]);
  }

  // Pomodoro CRUD operations
  Future<String> createPomodoro(Pomodoro pomodoro) async {
    final db = await database;
    await db.insert('pomodoros', pomodoro.toMap());
    return pomodoro.id;
  }

  Future<Pomodoro?> getPomodoro(String id) async {
    final db = await database;
    final maps = await db.query('pomodoros', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return Pomodoro.fromMap(maps.first);
  }

  Future<List<Pomodoro>> getAllPomodoros() async {
    final db = await database;
    final result = await db.query('pomodoros', orderBy: 'startTime DESC');
    return result.map((map) => Pomodoro.fromMap(map)).toList();
  }

  Future<int> updatePomodoro(Pomodoro pomodoro) async {
    final db = await database;
    return db.update('pomodoros', pomodoro.toMap(), where: 'id = ?', whereArgs: [pomodoro.id]);
  }

  Future<int> deletePomodoro(String id) async {
    final db = await database;
    return await db.delete('pomodoros', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}