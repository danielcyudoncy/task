import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task_model.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'tasks.db';
  static const int _databaseVersion = 1;
  
  // Table names
  static const String _tasksTable = 'tasks';
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _createTables,
    );
  }
  
  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tasksTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        taskId TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        assignedToUserId TEXT,
        assignedToUserName TEXT,
        assignedToUserEmail TEXT,
        assignedByUserId TEXT,
        assignedByUserName TEXT,
        assignedByUserEmail TEXT,
        status TEXT NOT NULL,
        comments TEXT,
        timestamp INTEGER NOT NULL,
        mediaAttachmentUrl TEXT,
        mediaAttachmentName TEXT,
        mediaAttachmentType TEXT,
        mediaAttachmentSize INTEGER,
        archivedAt INTEGER,
        archivedBy TEXT,
        archiveReason TEXT,
        archiveLocation TEXT,
        completedByUserIds TEXT,
        userCompletionTimestamps TEXT
      )
    ''');
  }
  
  // CRUD Operations
  
  Future<int> insertTask(Task task) async {
    final db = await database;
    return await db.insert(_tasksTable, task.toMap());
  }
  
  Future<List<Task>> getAllTasks() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(_tasksTable);
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }
  
  Future<Task?> getTaskById(String taskId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tasksTable,
      where: 'taskId = ?',
      whereArgs: [taskId],
    );
    
    if (maps.isNotEmpty) {
      return Task.fromMap(maps.first);
    }
    return null;
  }
  
  Future<int> updateTask(Task task) async {
    final db = await database;
    return await db.update(
      _tasksTable,
      task.toMap(),
      where: 'taskId = ?',
      whereArgs: [task.taskId],
    );
  }
  
  Future<int> deleteTask(String taskId) async {
    final db = await database;
    return await db.delete(
      _tasksTable,
      where: 'taskId = ?',
      whereArgs: [taskId],
    );
  }
  
  Future<List<Task>> getTasksByStatus(String status) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tasksTable,
      where: 'status = ?',
      whereArgs: [status],
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }
  
  Future<List<Task>> getTasksByUserId(String userId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      _tasksTable,
      where: 'assignedToUserId = ? OR assignedByUserId = ?',
      whereArgs: [userId, userId],
    );
    return List.generate(maps.length, (i) => Task.fromMap(maps[i]));
  }
  
  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}