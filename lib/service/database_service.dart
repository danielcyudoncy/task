// service/database_service.dart
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/task.dart';

class DatabaseService {
  static Database? _database;
  static const String _databaseName = 'tasks.db';
  static const int _databaseVersion = 4;

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
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add new columns for version 2
      await db.execute('ALTER TABLE $_tasksTable ADD COLUMN createdBy TEXT');
      await db
          .execute('ALTER TABLE $_tasksTable ADD COLUMN assignedReporter TEXT');
      await db.execute(
          'ALTER TABLE $_tasksTable ADD COLUMN assignedCameraman TEXT');
      await db
          .execute('ALTER TABLE $_tasksTable ADD COLUMN assignedDriver TEXT');
      await db.execute(
          'ALTER TABLE $_tasksTable ADD COLUMN assignedLibrarian TEXT');
      await db.execute('ALTER TABLE $_tasksTable ADD COLUMN assignedTo TEXT');
      await db.execute(
          'ALTER TABLE $_tasksTable ADD COLUMN assignmentTimestamp INTEGER');
      await db.execute('ALTER TABLE $_tasksTable ADD COLUMN createdById TEXT');
      await db.execute(
          'ALTER TABLE $_tasksTable ADD COLUMN assignedReporterId TEXT');
      await db.execute(
          'ALTER TABLE $_tasksTable ADD COLUMN assignedCameramanId TEXT');
      await db
          .execute('ALTER TABLE $_tasksTable ADD COLUMN assignedDriverId TEXT');
      await db.execute(
          'ALTER TABLE $_tasksTable ADD COLUMN assignedLibrarianId TEXT');
      await db
          .execute('ALTER TABLE $_tasksTable ADD COLUMN creatorAvatar TEXT');
      await db.execute('ALTER TABLE $_tasksTable ADD COLUMN category TEXT');
      await db.execute('ALTER TABLE $_tasksTable ADD COLUMN tags TEXT');
      await db.execute('ALTER TABLE $_tasksTable ADD COLUMN dueDate INTEGER');
      await db.execute('ALTER TABLE $_tasksTable ADD COLUMN priority TEXT');
      await db
          .execute('ALTER TABLE $_tasksTable ADD COLUMN lastModified INTEGER');
      await db.execute('ALTER TABLE $_tasksTable ADD COLUMN syncStatus TEXT');
      await db
          .execute('ALTER TABLE $_tasksTable ADD COLUMN attachmentUrls TEXT');
      await db
          .execute('ALTER TABLE $_tasksTable ADD COLUMN attachmentNames TEXT');
      await db
          .execute('ALTER TABLE $_tasksTable ADD COLUMN attachmentTypes TEXT');
      await db
          .execute('ALTER TABLE $_tasksTable ADD COLUMN attachmentSizes TEXT');
      await db.execute(
          'ALTER TABLE $_tasksTable ADD COLUMN lastAttachmentAdded INTEGER');
    }
    if (oldVersion < 3) {
      // Add approval system columns for version 3
      await db.execute(
          'ALTER TABLE $_tasksTable ADD COLUMN approvalStatus TEXT DEFAULT "pending"');
      await db.execute('ALTER TABLE $_tasksTable ADD COLUMN approvedBy TEXT');
      await db.execute(
          'ALTER TABLE $_tasksTable ADD COLUMN approvalTimestamp INTEGER');
      await db
          .execute('ALTER TABLE $_tasksTable ADD COLUMN approvalReason TEXT');
    }
    if (oldVersion < 4) {
      // Add report completion and task review columns for version 4
      await db.execute(
          'ALTER TABLE $_tasksTable ADD COLUMN reportCompletionInfo TEXT');
      await db.execute('ALTER TABLE $_tasksTable ADD COLUMN taskReviews TEXT');
      await db.execute('ALTER TABLE $_tasksTable ADD COLUMN taskRatings TEXT');
      await db
          .execute('ALTER TABLE $_tasksTable ADD COLUMN reviewTimestamps TEXT');
      await db
          .execute('ALTER TABLE $_tasksTable ADD COLUMN reviewerRoles TEXT');
    }
  }

  Future<void> _createTables(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tasksTable(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        taskId TEXT UNIQUE NOT NULL,
        title TEXT NOT NULL,
        description TEXT,
        createdBy TEXT,
        assignedReporter TEXT,
        assignedCameraman TEXT,
        assignedDriver TEXT,
        assignedLibrarian TEXT,
        assignedToUserId TEXT,
        assignedToUserName TEXT,
        assignedToUserEmail TEXT,
        assignedByUserId TEXT,
        assignedByUserName TEXT,
        assignedByUserEmail TEXT,
        status TEXT NOT NULL,
        comments TEXT,
        timestamp INTEGER NOT NULL,
        assignedTo TEXT,
        assignmentTimestamp INTEGER,
        createdById TEXT,
        assignedReporterId TEXT,
        assignedCameramanId TEXT,
        assignedDriverId TEXT,
        assignedLibrarianId TEXT,
        creatorAvatar TEXT,
        category TEXT,
        tags TEXT,
        dueDate INTEGER,
        priority TEXT,
        lastModified INTEGER,
        syncStatus TEXT,
        mediaAttachmentUrl TEXT,
        mediaAttachmentName TEXT,
        mediaAttachmentType TEXT,
        mediaAttachmentSize INTEGER,
        archivedAt INTEGER,
        archivedBy TEXT,
        archiveReason TEXT,
        archiveLocation TEXT,
        attachmentUrls TEXT,
        attachmentNames TEXT,
        attachmentTypes TEXT,
        attachmentSizes TEXT,
        lastAttachmentAdded INTEGER,
        completedByUserIds TEXT,
        userCompletionTimestamps TEXT,
        approvalStatus TEXT DEFAULT 'pending',
        approvedBy TEXT,
        approvalTimestamp INTEGER,
        approvalReason TEXT,
        reportCompletionInfo TEXT,
        taskReviews TEXT,
        taskRatings TEXT,
        reviewTimestamps TEXT,
        reviewerRoles TEXT
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
