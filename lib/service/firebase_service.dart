// service/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ✅ Get User Data by UID
  Future<DocumentSnapshot?> getUserData(String uid) async {
    try {
      return await _firestore.collection("users").doc(uid).get();
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching user data for UID $uid: $e");
      }
      return null; // Return null if an error occurs
    }
  }

  // ✅ Save User Data (Used for Signup)
  Future<void> saveUserData(String uid, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection("users").doc(uid).set(userData);
    } catch (e) {
      if (kDebugMode) {
        print("Error saving user data for UID $uid: $e");
      }
      rethrow; // Rethrow error to handle it at a higher level if needed
    }
  }

  // ✅ Update User Data
  Future<void> updateUserData(String uid, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection("users").doc(uid).update(updates);
    } catch (e) {
      if (kDebugMode) {
        print("Error updating user data for UID $uid: $e");
      }
      rethrow; // Rethrow error to handle it at a higher level if needed
    }
  }

  // ✅ Delete User (Admin Only)
  Future<void> deleteUser(String userId) async {
    try {
      await _firestore.collection("users").doc(userId).delete();
      if (kDebugMode) {
        print("User with ID $userId deleted successfully.");
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error deleting user with ID $userId: $e");
      }
      rethrow; // Rethrow error to handle it at a higher level if needed
    }
  }

  // ✅ Get Tasks Created by a Specific User
  Stream<QuerySnapshot> getTasksByUser(String userId) {
    try {
      return _firestore
          .collection("tasks")
          .where("createdBy", isEqualTo: userId)
          .snapshots();
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching tasks for user ID $userId: $e");
      }
      rethrow; // Rethrow error to inform the caller
    }
  }

  // ✅ Get All Tasks (For Admin, Editors, HoDs)
  Stream<QuerySnapshot> getAllTasks() {
    try {
      return _firestore.collection("tasks").snapshots();
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching all tasks: $e");
      }
      rethrow; // Rethrow error to inform the caller
    }
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
      rethrow; // Rethrow error to handle it at a higher level if needed
    }
  }

  // ✅ Update Task
  Future<void> updateTask(String taskId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection("tasks").doc(taskId).update(updates);
    } catch (e) {
      if (kDebugMode) {
        print("Error updating task with ID $taskId: $e");
      }
      rethrow; // Rethrow error to handle it at a higher level if needed
    }
  }

  // ✅ Assign Task to a User
  Future<void> assignTask(
      String taskId, String userId, String roleField) async {
    try {
      await _firestore
          .collection("tasks")
          .doc(taskId)
          .update({roleField: userId});
    } catch (e) {
      if (kDebugMode) {
        print("Error assigning task with ID $taskId to user ID $userId: $e");
      }
      rethrow; // Rethrow error to handle it at a higher level if needed
    }
  }
}

void useFirebaseEmulator() {
  // Only use emulators in debug mode
  if (kDebugMode) {
    // Use localhost for web, IP address for mobile
    final String host = kIsWeb ? 'localhost' : '192.168.1.7';
    
    // Auth Emulator
    FirebaseAuth.instance.useAuthEmulator(host, 8002);
    // Firestore Emulator
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8003);
    FirebaseFunctions.instance.useFunctionsEmulator(host, 8001);
    FirebaseStorage.instance.useStorageEmulator(host, 8005);
  }
}
