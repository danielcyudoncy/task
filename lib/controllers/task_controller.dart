// controllers/task_controller.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';

class TaskController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  var tasks = <Task>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchTasks();
  }

  // Fetch tasks in real-time
  void fetchTasks() {
    tasks.bindStream(
      _firestore.collection("tasks").snapshots().map((snapshot) {
        return snapshot.docs.map((doc) => Task.fromMap(doc.data())).toList();
      }),
    );
  }

  // Create a new task
  Future<void> createTask(String title, String description, String createdBy) async {
    try {
      isLoading(true);
      String taskId = _firestore.collection("tasks").doc().id;
      Task newTask = Task(
        taskId: taskId,
        title: title,
        description: description,
        createdBy: createdBy,
      );

      await _firestore.collection("tasks").doc(taskId).set(newTask.toMap());
      Get.snackbar("Success", "Task Created Successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to create task: ${e.toString()}");
    } finally {
      isLoading(false);
    }
  }

  // Assign Task to Reporter
  Future<void> assignTaskToReporter(String taskId, String reporterId) async {
    await _assignTask(taskId, reporterId, "assignedReporter");
  }

  // Assign Task to Cameraman
  Future<void> assignTaskToCameraman(String taskId, String cameramanId) async {
    await _assignTask(taskId, cameramanId, "assignedCameraman");
  }

  // General method to assign a task
  Future<void> _assignTask(String taskId, String userId, String roleField) async {
    try {
      await _firestore.collection("tasks").doc(taskId).update({
        roleField: userId,
      });

      String? fcmToken = await _getUserFCMToken(userId);
      if (fcmToken != null) {
        _sendTaskNotification(fcmToken, "You have been assigned a task.");
      }

      Get.snackbar("Success", "Task Assigned & Notification Sent");
    } catch (e) {
      Get.snackbar("Error", "Failed to assign task: ${e.toString()}");
    }
  }

  // Get User's FCM Token
  Future<String?> _getUserFCMToken(String userId) async {
    try {
      var userDoc = await _firestore.collection("users").doc(userId).get();
      return userDoc.data()?["fcmToken"];
    } catch (e) {
      return null;
    }
  }

  // Send Push Notification via FCM
  Future<void> _sendTaskNotification(String fcmToken, String message) async {
    const String serverKey = "YOUR_FIREBASE_SERVER_KEY"; // Replace with actual Firebase server key

    await http.post(
      Uri.parse("https://fcm.googleapis.com/fcm/send"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "key=$serverKey",
      },
      body: jsonEncode({
        "to": fcmToken,
        "notification": {
          "title": "New Task Assigned",
          "body": message,
        }
      }),
    );

    await _firestore.collection("notifications").add({
      "title": "New Task Assigned",
      "message": message,
      "timestamp": FieldValue.serverTimestamp(),
      "isRead": false,
    });
  }

  // Mark Task as Completed
  Future<void> markTaskAsCompleted(String taskId, String comment, String userId) async {
    try {
      var taskRef = _firestore.collection("tasks").doc(taskId);
      var snapshot = await taskRef.get();

      List<Map<String, dynamic>> existingComments =
          List<Map<String, dynamic>>.from(snapshot["comments"] ?? []);
      existingComments.add({
        "userId": userId,
        "text": comment,
        "timestamp": FieldValue.serverTimestamp(),
      });

      await taskRef.update({
        "status": "Completed",
        "comments": existingComments,
      });

      tasks.refresh();
      Get.snackbar("Success", "Task Marked as Completed");
    } catch (e) {
      Get.snackbar("Error", "Failed to mark task as completed: ${e.toString()}");
    }
  }
}
