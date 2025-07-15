// service/mock_user_deletion_service.dart
import 'user_deletion_service.dart';

class MockUserDeletionService implements UserDeletionService {
  @override
  Future<void> deleteUserByAdmin(String uid) async {
    await Future.delayed(const Duration(milliseconds: 500));
    // print('Mock: User $uid deleted.');
  }
}
