// service/firebase_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get User Data by UID
  Future<DocumentSnapshot?> getUserData(String uid) async {
    try {
      return await _firestore.collection("users").doc(uid).get();
    } catch (e) {
      return null; // Return null on failure
    }
  }

  // Save User Data (Used for Signup)
  Future<void> saveUserData(String uid, Map<String, dynamic> userData) async {
    try {
      await _firestore.collection("users").doc(uid).set(userData);
    } catch (_) {}
  }

  // Update User Data
  Future<void> updateUserData(String uid, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection("users").doc(uid).update(updates);
    } catch (_) {}
  }

  // Get All Tasks (Real-time Listener)
  Stream<List<QueryDocumentSnapshot>> getAllTasks() {
    return _firestore
        .collection("tasks")
        .snapshots()
        .map((snapshot) => snapshot.docs);
  }

  // Create a New Task
  Future<void> createTask(Map<String, dynamic> taskData) async {
    try {
      await _firestore.collection("tasks").add(taskData);
    } catch (_) {}
  }

  // Assign Task to User
  Future<void> assignTask(
      String taskId, String assignedTo, String roleField) async {
    try {
      await _firestore.collection("tasks").doc(taskId).update({
        roleField: assignedTo,
      });
    } catch (_) {}
  }

  // Mark Task as Completed
  Future<void> markTaskAsCompleted(
      String taskId, Map<String, dynamic> commentData) async {
    try {
      var taskRef = _firestore.collection("tasks").doc(taskId);
      var snapshot = await taskRef.get();

      List<Map<String, dynamic>> existingComments =
          List<Map<String, dynamic>>.from(snapshot["comments"] ?? []);
      existingComments.add(commentData);

      await taskRef.update({
        "status": "Completed",
        "comments": existingComments,
      });
    } catch (_) {}
  }

  // Save Notification
  Future<void> saveNotification(
      String userId, Map<String, dynamic> notificationData) async {
    try {
      await _firestore
          .collection("users")
          .doc(userId)
          .collection("notifications")
          .add(notificationData);
    } catch (_) {}
  }
}
