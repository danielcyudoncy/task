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

  Future<void> fetchTasks() async {
    isLoading(true);
    try {
      var snapshot = await firestore.collection("tasks").get();
      tasks.value =
          snapshot.docs.map((doc) => Task.fromMap(doc.data())).toList();
    } catch (e) {
      Get.snackbar("Error", "Failed to fetch tasks");
    } finally {
      isLoading(false);
    }
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

  Future<void> sendNotification(String token, String title, String body) async {
    const String serverKey =
        "YOUR_SERVER_KEY"; // Replace with your Firebase Server Key
    const String fcmUrl = "https://fcm.googleapis.com/fcm/send";

    try {
      await http.post(
        Uri.parse(fcmUrl),
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
    } catch (e) {
      if (kDebugMode) {
        print("Error sending notification: $e");
      }
    }
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
