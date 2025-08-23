import '../models/task_model.dart';
import 'database_service.dart';

class TaskService {
  final DatabaseService _databaseService = DatabaseService();

  // Initialize the service
  Future<void> initialize() async {
    // Initialize database by accessing the database getter
    // This will trigger the database initialization if not already done
    await _databaseService.database;
  }

  // Add a new task
  Future<void> addTask(Task task) async {
    await _databaseService.insertTask(task);
  }

  // Get all tasks
  Future<List<Task>> getAllTasks() async {
    return await _databaseService.getAllTasks();
  }

  // Get task by ID
  Future<Task?> getTaskById(String taskId) async {
    return await _databaseService.getTaskById(taskId);
  }

  // Update a task
  Future<void> updateTask(Task task) async {
    await _databaseService.updateTask(task);
  }

  // Delete a task
  Future<void> deleteTask(String taskId) async {
    await _databaseService.deleteTask(taskId);
  }

  // Get tasks by status
  Future<List<Task>> getTasksByStatus(String status) async {
    return await _databaseService.getTasksByStatus(status);
  }

  // Get tasks by user ID
  Future<List<Task>> getTasksByUserId(String userId) async {
    return await _databaseService.getTasksByUserId(userId);
  }

  // Close database connection
  Future<void> close() async {
    await _databaseService.close();
  }

  // Compatibility methods to match the old Isar service interface
  Future<void> put(Task task) async {
    if (task.taskId.isEmpty) {
      // Generate a new task ID if not provided
      task.taskId = DateTime.now().millisecondsSinceEpoch.toString();
    }
    
    final existingTask = await getTaskById(task.taskId);
    if (existingTask != null) {
      await updateTask(task);
    } else {
      await addTask(task);
    }
  }

  Future<List<Task>> getAll() async {
    return await getAllTasks();
  }

  Future<Task?> get(String taskId) async {
    return await getTaskById(taskId);
  }

  Future<void> delete(String taskId) async {
    await deleteTask(taskId);
  }
}