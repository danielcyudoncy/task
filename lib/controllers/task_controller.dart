// controllers/task_controller.dart
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
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

  void fetchTasks() {
    FirebaseFirestore.instance
        .collection("tasks")
        .snapshots()
        .listen((snapshot) {
      tasks.value = snapshot.docs.map((doc) {
        return {
          "id": doc.id,
          "title": doc["title"],
          "description": doc["description"],
          "assignedReporter": doc["assignedReporter"],
          "assignedCameraman": doc["assignedCameraman"],
        };
      }).toList();
    });
  }

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
      Get.snackbar("Error", "Failed to create task");
    }
  }

  Future<void> assignReporter(
      String taskId, String reporterId, String reporterToken) async {
    try {
      await firestore
          .collection("tasks")
          .doc(taskId)
          .update({"assignedReporter": reporterId});
      sendNotification(
          reporterToken, "New Task Assigned", "You have been assigned a task.");
      Get.snackbar("Success", "Reporter Assigned & Notified");
    } catch (e) {
      Get.snackbar("Error", "Failed to assign reporter");
    }
  }

  Future<void> assignCameraman(
      String taskId, String cameramanId, String cameramanToken) async {
    try {
      await firestore
          .collection("tasks")
          .doc(taskId)
          .update({"assignedCameraman": cameramanId});
      sendNotification(cameramanToken, "New Task Assigned",
          "You have been assigned a task.");
      Get.snackbar("Success", "Cameraman Assigned & Notified");
    } catch (e) {
      Get.snackbar("Error", "Failed to assign cameraman");
    }
  }

  Future<void> assignTask(String taskId, String userId) async {
    try {
      await firestore
          .collection("tasks")
          .doc(taskId)
          .update({"assignedTo": userId});

      // Fetch FCM token of the assigned user
      var userDoc = await firestore.collection("users").doc(userId).get();
      String? fcmToken = userDoc.data()?["fcmToken"];

      if (fcmToken != null) {
        sendPushNotification(fcmToken, "New Task Assigned",
            "You have been assigned a new task!");
      }
    } catch (e) {
      Get.snackbar("Error", "Failed to assign task");
    }
  }

  Future<void> sendPushNotification(
      String token, String title, String body) async {
    const String serverKey = "YOUR_FIREBASE_SERVER_KEY";

    await http.post(
      Uri.parse("https://fcm.googleapis.com/fcm/send"),
      headers: {
        "Content-Type": "application/json",
        "Authorization": "key=$serverKey",
      },
      body: jsonEncode({
        "to": token,
        "notification": {
          "title": title,
          "body": body,
        }
      }),
    );
  }

  Future<void> markTaskAsCompleted(
      String taskId, String comment, String userId) async {
    try {
      var taskRef = firestore.collection("tasks").doc(taskId);
      var snapshot = await taskRef.get();
      List<Map<String, dynamic>> existingComments =
          List<Map<String, dynamic>>.from(snapshot['comments'] ?? []);
      existingComments.add({
        "userId": userId,
        "text": comment,
        "timestamp": DateTime.now().toString()
      });

      await taskRef.update({
        "status": "Completed",
        "comments": existingComments,
      });

      tasks.firstWhere((task) => task.taskId == taskId).status = "Completed";
      tasks.refresh();
      Get.snackbar("Success", "Task Marked as Completed");
    } catch (e) {
      Get.snackbar("Error", "Failed to mark task as completed");
    }
  }
}
