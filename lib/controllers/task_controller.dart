// controllers/task_controller.dart
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';

class TaskController extends GetxController {
  FirebaseFirestore firestore = FirebaseFirestore.instance;
  var tasks = <Task>[].obs;
  var isLoading = false.obs;

  @override
  void onInit() {
    fetchTasks();
    super.onInit();
  }

  // Fetch all tasks from Firestore in real-time
  void fetchTasks() {
    firestore.collection("tasks").snapshots().listen((snapshot) {
      tasks.value = snapshot.docs.map((doc) {
        return Task(
          taskId: doc.id,
          title: doc["title"],
          description: doc["description"],
          assignedReporter: doc["assignedReporter"] ?? "",
          assignedCameraman: doc["assignedCameraman"] ?? "",
          createdBy: doc["createdBy"],
          status: doc["status"] ?? "Pending",
          comments: List<Map<String, dynamic>>.from(doc["comments"] ?? []),
        );
      }).toList();
    });
  }

  // Create a new task
  Future<void> createTask(
      String title, String description, String createdBy) async {
    try {
      String taskId = firestore.collection("tasks").doc().id;
      Task newTask = Task(
        taskId: taskId,
        title: title,
        description: description,
        createdBy: createdBy,
      );

      await firestore.collection("tasks").doc(taskId).set(newTask.toMap());
      tasks.add(newTask);
      Get.snackbar("Success", "Task Created Successfully");
    } catch (e) {
      Get.snackbar("Error", "Failed to create task: ${e.toString()}");
    }
  }

  // Assign Task to Reporter
  Future<void> assignTaskToReporter(String taskId, String reporterId) async {
    try {
      await firestore.collection("tasks").doc(taskId).update({
        "assignedReporter": reporterId,
      });

      // Get FCM Token
      String? fcmToken = await getUserFCMToken(reporterId);
      if (fcmToken != null) {
        sendTaskNotification(fcmToken, "You have been assigned a task.");
      }

      Get.snackbar("Success", "Reporter Assigned & Notified");
    } catch (e) {
      Get.snackbar("Error", "Failed to assign reporter: ${e.toString()}");
    }
  }

  // Assign Task to Cameraman
  Future<void> assignTaskToCameraman(String taskId, String cameramanId) async {
    try {
      await firestore.collection("tasks").doc(taskId).update({
        "assignedCameraman": cameramanId,
      });

      // Get FCM Token
      String? fcmToken = await getUserFCMToken(cameramanId);
      if (fcmToken != null) {
        sendTaskNotification(fcmToken, "You have been assigned a task.");
      }

      Get.snackbar("Success", "Cameraman Assigned & Notified");
    } catch (e) {
      Get.snackbar("Error", "Failed to assign cameraman: ${e.toString()}");
    }
  }

  // Assign Task to a General User (Reporter or Cameraman)
  Future<void> assignTask(String taskId, String userId) async {
    try {
      await firestore.collection("tasks").doc(taskId).update({
        "assignedTo": userId,
      });

      // Get FCM Token
      String? fcmToken = await getUserFCMToken(userId);
      if (fcmToken != null) {
        sendTaskNotification(fcmToken, "You have been assigned a new task!");
      }

      Get.snackbar("Success", "Task Assigned & Notification Sent");
    } catch (e) {
      Get.snackbar("Error", "Failed to assign task: ${e.toString()}");
    }
  }

  // Fetch FCM Token for user
  Future<String?> getUserFCMToken(String userId) async {
    try {
      var userDoc = await firestore.collection("users").doc(userId).get();
      return userDoc.data()?["fcmToken"];
    } catch (e) {
      return null;
    }
  }

  // Send Push Notification via FCM
  Future<void> sendTaskNotification(String fcmToken, String message) async {
    String serverKey =
        "YOUR_FIREBASE_SERVER_KEY"; // Replace with actual Firebase server key

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

    // Save notification in Firestore
    await firestore.collection("notifications").add({
      "title": "New Task Assigned",
      "message": message,
      "timestamp": FieldValue.serverTimestamp(),
      "isRead": false,
    });
  }

  // Mark Task as Completed
  Future<void> markTaskAsCompleted(
      String taskId, String comment, String userId) async {
    try {
      var taskRef = firestore.collection("tasks").doc(taskId);
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

      // Update UI
      tasks.firstWhere((task) => task.taskId == taskId).status = "Completed";
      tasks.refresh();

      Get.snackbar("Success", "Task Marked as Completed");
    } catch (e) {
      Get.snackbar(
          "Error", "Failed to mark task as completed: ${e.toString()}");
    }
  }
}
