// screens/user_chat_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:task/controllers/chat_controller.dart';
import 'package:task/controllers/manage_users_controller.dart';
import 'package:task/screens/chat_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:task/utils/constants/app_fonts_family.dart';

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
        title: Text('Select Contact'.tr,  style: TextStyle(
          fontSize: 18.sp,
          fontFamily: AppFontsStyles.raleway // Smaller font size
        ),),

        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.95),
            ],
          ),
        ),
        child: Column(
          children: [
            // Modern search bar with enhanced styling
            Container(
              margin: const EdgeInsets.all(20).copyWith(bottom: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                onChanged: (query) {
                  _manageUsersController.searchUsers(query);
                },
                decoration: InputDecoration(
                  hintText: 'Search contacts...'.tr,
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: (0.6)),
                    fontSize: 14.sp,
                    fontFamily: AppFontsStyles.raleway,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: (0.6)),
                    size: 20,
                  ),
                  suffixIcon: Obx(() =>
                    _manageUsersController.currentSearchQuery.value.isNotEmpty
                        ? IconButton(
                            icon: Icon(
                              Icons.clear,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: (0.6)),
                              size: 20,
                            ),
                            onPressed: () {
                              _manageUsersController.searchUsers('');
                            },
                          )
                        : const SizedBox.shrink(),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Theme.of(context).cardColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontFamily: AppFontsStyles.raleway,
                ),
              ),
            ),

            // Users list with modern card design
            Expanded(
              child: Obx(() {
                if (_manageUsersController.isLoading.value) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Loading contacts...'.tr,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: (0.7)),
                              fontSize: 14.sp,
                              fontFamily: AppFontsStyles.raleway,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (_manageUsersController.filteredUsersList.isEmpty) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.all(32),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.08),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.people_outline,
                              size: 48,
                              color: Theme.of(context).primaryColor,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'No contacts found'.tr,
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontFamily: AppFontsStyles.raleway,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try adjusting your search'.tr,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: (0.7)),
                              fontFamily: AppFontsStyles.raleway,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _manageUsersController.filteredUsersList.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = _manageUsersController.filteredUsersList[index];
                    final userName = user['fullName'] ?? user['fullname'] ?? 'Unknown User';
                    final userEmail = user['email'] ?? '';
                    final userRole = user['role'] ?? 'User';
                    final userAvatar = user['photoUrl'] ?? '';

                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
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
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Modern avatar with enhanced styling
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: Theme.of(context).brightness == Brightness.dark
                                          ? [
                                              Colors.white,
                                              Colors.white.withValues(alpha: 0.9),
                                            ]
                                          : [
                                              Theme.of(context).primaryColor,
                                              Theme.of(context).primaryColor.withValues(alpha: 0.8),
                                            ],
                                    ),
                                  ),
                                  child: CircleAvatar(
                                    radius: 28,
                                    backgroundColor: userAvatar.isEmpty
                                        ? Theme.of(context).primaryColor
                                        : Theme.of(context).cardColor,
                                    backgroundImage: userAvatar.isNotEmpty
                                        ? CachedNetworkImageProvider(userAvatar)
                                        : null,
                                    child: userAvatar.isEmpty
                                        ? Text(
                                            userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          )
                                        : null,
                                  ),
                                ),
                                
                                const SizedBox(width: 16),
                                
                                // User info with better typography
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 16.sp,
                                          color: Theme.of(context).colorScheme.onSurface,
                                          fontFamily: AppFontsStyles.raleway,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          if (userEmail.isNotEmpty) ...[
                                            Expanded(
                                              child: Text(
                                                userEmail,
                                                style: TextStyle(
                                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: (0.7)),
                                                  fontSize: 13.sp,
                                                  fontFamily: AppFontsStyles.raleway,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          ] else ...[
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                userRole,
                                                style: TextStyle(
                                                  color: Theme.of(context).primaryColor,
                                                  fontSize: 12.sp,
                                                  fontWeight: FontWeight.w600,
                                                  fontFamily: AppFontsStyles.raleway,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                
                                // Modern chevron icon
                                Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: (0.5)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

}