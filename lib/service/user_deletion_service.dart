// service/user_deletion_service.dart
abstract class UserDeletionService {
  Future<void> deleteUserByAdmin(String uid);
}
