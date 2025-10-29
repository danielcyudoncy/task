// screens/user_chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:task/controllers/chat_controller.dart';
import 'package:task/controllers/manage_users_controller.dart';
import 'package:task/screens/chat_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class UserChatListScreen extends StatefulWidget {
  const UserChatListScreen({super.key});

  @override
  State<UserChatListScreen> createState() => _UserChatListScreenState();
}

class _UserChatListScreenState extends State<UserChatListScreen> {
  final ChatController _chatController = Get.find();
  final ManageUsersController _manageUsersController = Get.find();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Contact'.tr),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (query) {
                _manageUsersController.searchUsers(query);
              },
              decoration: InputDecoration(
                hintText: 'Search contacts...'.tr,
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),

          // Users list
          Expanded(
            child: Obx(() {
              if (_manageUsersController.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_manageUsersController.filteredUsersList.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No contacts found'.tr,
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: _manageUsersController.filteredUsersList.length,
                itemBuilder: (context, index) {
                  final user = _manageUsersController.filteredUsersList[index];
                  final userName = user['fullName'] ?? user['fullname'] ?? 'Unknown User';
                  final userEmail = user['email'] ?? '';
                  final userRole = user['role'] ?? 'User';
                  final userAvatar = user['photoUrl'] ?? '';

                  return ListTile(
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: userAvatar.isEmpty
                          ? Theme.of(context).primaryColor
                          : null,
                      backgroundImage: userAvatar.isNotEmpty
                          ? CachedNetworkImageProvider(userAvatar)
                          : null,
                      child: userAvatar.isEmpty
                          ? Text(
                              userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            )
                          : null,
                    ),
                    title: Text(
                      userName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text(
                      userEmail.isNotEmpty ? userEmail : userRole,
                      style: TextStyle(
                        color: userEmail.isNotEmpty ? Colors.grey[600] : Theme.of(context).primaryColor,
                        fontSize: 14,
                        fontWeight: userEmail.isNotEmpty ? FontWeight.normal : FontWeight.w500,
                      ),
                    ),
                    onTap: () async {
                      // Create or get conversation
                      final conversationId = await _chatController.getOrCreateConversation(user['uid']);

                      if (conversationId.isNotEmpty) {
                        Get.to(() => ChatScreen(
                              receiverId: user['uid'],
                              receiverName: userName,
                              receiverAvatar: userAvatar,
                              conversationId: conversationId,
                              chatId: conversationId,
                              otherUserId: user['uid'],
                              otherUserName: userName,
                              otherUser: const {},
                              chatBackground: '',
                            ));
                      } else {
                        Get.snackbar(
                          'Error',
                          'Could not start conversation'.tr,
                          snackPosition: SnackPosition.TOP,
                          backgroundColor: Colors.red,
                          colorText: Colors.white,
                        );
                      }
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

}