// service/cloud_function_user_deletion_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:get/get.dart';
import 'user_deletion_service.dart';

class CloudFunctionUserDeletionService extends GetxService
    implements UserDeletionService {
  @override
  Future<void> deleteUserByAdmin(String uid) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('adminDeleteUser');
    final result = await callable.call({'uid': uid});
    if (result.data['success'] != true) {
      throw Exception('Failed to delete user.');
    }
  }
}
