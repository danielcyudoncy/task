// controllers/user_controller.dart
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserController extends GetxController {
  var reporters = <Map<String, dynamic>>[].obs;
  var cameramen = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchReporters();
    fetchCameramen();
  }

  void fetchReporters() {
    FirebaseFirestore.instance
        .collection("users")
        .where("role", isEqualTo: "Reporter")
        .snapshots()
        .listen((snapshot) {
      reporters.value = snapshot.docs.map((doc) {
        return {"id": doc.id, "name": doc["name"]};
      }).toList();
    });
  }

  void fetchCameramen() {
    FirebaseFirestore.instance
        .collection("users")
        .where("role", isEqualTo: "Cameraman")
        .snapshots()
        .listen((snapshot) {
      cameramen.value = snapshot.docs.map((doc) {
        return {"id": doc.id, "name": doc["name"]};
      }).toList();
    });
  }
}
