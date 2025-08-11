// service/isar_task_service.dart
import 'package:isar/isar.dart';
import '../models/task_model.dart';

class IsarTaskService {
  final Isar isar;
  IsarTaskService(this.isar);

  Future<void> addTask(Task task) async {
    await isar.writeTxn(() async {
      await isar.tasks.put(task);
    });
  }

  Future<List<Task>> getAllTasks() async {
    return await isar.tasks.where().findAll();
  }

  Future<Task?> getTaskById(String taskId) async {
    return await isar.tasks.filter().taskIdEqualTo(taskId).findFirst();
  }

  Future<void> updateTask(Task task) async {
    await isar.writeTxn(() async {
      await isar.tasks.put(task);
    });
  }

  Future<void> deleteTask(String taskId) async {
    final task = await getTaskById(taskId);
    if (task != null) {
      await isar.writeTxn(() async {
        await isar.tasks.delete(task.isarId);
      });
    }
  }
} 