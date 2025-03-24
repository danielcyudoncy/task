// controllers/user_controller.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  var reporters = <Map<String, dynamic>>[].obs;
  var cameramen = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchReporters();
    fetchCameramen();
  }

  // Fetch all Reporters in real-time
  void fetchReporters() {
    reporters.bindStream(
      _firestore
          .collection("users")
          .where("role", isEqualTo: "Reporter")
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return {
            "id": doc.id,
            "name": doc["fullName"] ??
                "Unknown", // Changed from "name" to "fullName"
          };
        }).toList();
      }),
    );
  }

  // Fetch all Cameramen in real-time
  void fetchCameramen() {
    cameramen.bindStream(
      _firestore
          .collection("users")
          .where("role", isEqualTo: "Cameraman")
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) {
          return {
            "id": doc.id,
            "name": doc["fullName"] ??
                "Unknown", // Changed from "name" to "fullName"
          };
        }).toList();
      }),
    );
  }
}
