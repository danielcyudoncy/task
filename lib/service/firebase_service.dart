// service/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Get User Data by UID
  Future<DocumentSnapshot?> getUserData(String uid) async {
    try {
      return await _firestore.collection("users").doc(uid).get();
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching user data: $e");
      }
      return null;
    }
  }

  // ✅ Save User Data (Used for Signup)
  Future<void> saveUserData(String uid, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection("users").doc(uid).set(userData);
    } catch (e) {
      if (kDebugMode) {
        print("Error saving user data: $e");
      }
    }
  }

  // ✅ Update User Data
  Future<void> updateUserData(String uid, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection("users").doc(uid).update(updates);
    } catch (e) {
      if (kDebugMode) {
        print("Error updating user data: $e");
      }
    }
  }

  // ✅ Delete User (Admin Only)
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection("users").doc(userId).delete();
      if (kDebugMode) {
        print("User $userId deleted successfully");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error deleting user: $e");
      }
      throw Exception("Failed to delete user");
    }
  }

  // ✅ Get Tasks Created by a Specific User
  Stream<QuerySnapshot> getTasksByUser(String userId) {
    return _firestore
        .collection("tasks")
        .where("createdBy", isEqualTo: userId)
        .snapshots();
  }

  // ✅ Get All Tasks (For Admin, Editors, HoDs)
  Stream<QuerySnapshot> getAllTasks() {
    return _firestore.collection("tasks").snapshots();
  }

  // ✅ Create a New Task
  Future<void> createTask(Map<String, dynamic> taskData) async {
    try {
      String taskId = _firestore.collection("tasks").doc().id;
      taskData["taskId"] = taskId;
      taskData["timestamp"] = FieldValue.serverTimestamp(); // ✅ Add timestamp
      await _firestore.collection("tasks").doc(taskId).set(taskData);
    } catch (e) {
      if (kDebugMode) {
        print("Error creating task: $e");
      }
    }
  }

  // ✅ Update Task
  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection("tasks").doc(taskId).update(updates);
    } catch (e) {
      if (kDebugMode) {
        print("Error updating task: $e");
      }
    }
  }

  // ✅ Assign Task to a User
  Future<void> assignTask(String taskId, String userId, String roleField) async {
    try {
      await _firestore.collection("tasks").doc(taskId).update({roleField: userId});
    } catch (e) {
      if (kDebugMode) {
        print("Error assigning task: $e");
      }
    }
  }
}
