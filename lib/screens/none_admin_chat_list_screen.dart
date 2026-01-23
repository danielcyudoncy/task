// screens/none_admin_chat_list_screen.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:task/controllers/chat_controller.dart';
import 'package:task/controllers/manage_users_controller.dart';
import 'package:task/models/chat_model.dart';
import 'package:task/screens/chat_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:task/utils/constants/app_fonts_family.dart';
import 'package:task/utils/constants/app_constants.dart';
import 'package:firebase_core/firebase_core.dart';

class NoneAdminChatListScreen extends StatefulWidget {
  const NoneAdminChatListScreen({super.key});

  @override
  State<NoneAdminChatListScreen> createState() => _NoneAdminChatListScreenState();
}

class _NoneAdminChatListScreenState extends State<NoneAdminChatListScreen> with SingleTickerProviderStateMixin {
  final ChatController _chatController = Get.find();
  final ManageUsersController _manageUsersController = Get.find();
  final TextEditingController _searchController = TextEditingController();
  
  late TabController _tabController;
  bool _isSearching = false;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchQuery = '';
        _searchController.clear();
        _manageUsersController.searchUsers('');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(
                  color: Theme.of(context).textTheme.titleLarge?.color,
                  fontSize: 18.sp,
                  fontFamily: AppFontsStyles.raleway,
                ),
                decoration: InputDecoration(
                  hintText: 'Search...'.tr,
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _manageUsersController.searchUsers(value);
                },
              )
            : Text(
                'DelegoChat',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontFamily: AppFontsStyles.raleway,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: _toggleSearch,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white,
          tabs: [
            Tab(text: 'Calls'.tr),
            Tab(text: 'Chats'.tr),
            Tab(text: 'Contacts'.tr),
          ],
          labelStyle: TextStyle(
            fontFamily: AppFontsStyles.raleway,
            fontWeight: FontWeight.bold,
            fontSize: 14.sp,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: AppFontsStyles.raleway,
            fontWeight: FontWeight.normal,
            fontSize: 14.sp,
          ),
        ),
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
        child: StreamBuilder<List<ChatConversation>>(
          stream: _chatController.getConversations(),
          builder: (context, snapshot) {
            // Get list of users we have chatted with
            final conversations = snapshot.data ?? [];
            final chattedUserIds = <String>{};
            
            for (var conv in conversations) {
              for (var id in conv.participants) {
                if (id != _chatController.currentUserId) {
                  chattedUserIds.add(id);
                }
              }
            }

            return TabBarView(
              controller: _tabController,
              children: [
                // Calls Tab (Placeholder)
                _buildCallsTab(),
                
                // Chats Tab (Users we have chatted with)
                _buildChatsTab(conversations, chattedUserIds),
                
                // Contacts Tab (Users we haven't chatted with)
                _buildContactsTab(chattedUserIds),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCallsTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.call, size: 64, color: Theme.of(context).disabledColor),
          const SizedBox(height: 16),
          Text(
            'No recent calls',
            style: TextStyle(
              fontSize: 16.sp,
              color: Theme.of(context).disabledColor,
              fontFamily: AppFontsStyles.raleway,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatsTab(List<ChatConversation> conversations, Set<String> chattedUserIds) {
    if (conversations.isEmpty) {
      return _buildEmptyState('No recent chats'.tr, 'Start a new conversation from Contacts'.tr);
    }

    return Obx(() {
      final allUsers = _manageUsersController.usersList;
      
      final chatListWidgets = <Widget>[];
      
      for (var conv in conversations) {
        // Find the other user ID
        final otherUserId = conv.participants.firstWhere(
          (id) => id != _chatController.currentUserId,
          orElse: () => '',
        );
        
        if (otherUserId.isEmpty) continue;

        // Find user details
        final userMap = allUsers.firstWhere(
          (u) => u['uid'] == otherUserId,
          orElse: () => <String, dynamic>{},
        );

        if (userMap.isEmpty) continue;

        final userName = userMap['fullName'] ?? userMap['fullname'] ?? 'Unknown User';
        final userEmail = userMap['email'] ?? '';
        final userAvatar = userMap['photoUrl'] ?? '';
        final userRole = userMap['role'] ?? 'User';

        // Get last message and unread count
        final lastMessage = conv.lastMessage;
        final lastMessageContent = lastMessage != null ? lastMessage['content'] as String? ?? '' : '';
        final unreadCount = conv.unreadCounts[_chatController.currentUserId] ?? 0;

        // Apply search filter
        if (_isSearching && _searchQuery.isNotEmpty) {
          if (!userName.toLowerCase().contains(_searchQuery.toLowerCase()) &&
              !userEmail.toLowerCase().contains(_searchQuery.toLowerCase())) {
            continue;
          }
        }

        chatListWidgets.add(
          _buildUserListItem(
            user: userMap,
            userName: userName,
            userEmail: userEmail,
            userRole: userRole,
            userAvatar: userAvatar,
            isChatTab: true,
            lastMessage: lastMessageContent,
            unreadCount: unreadCount,
          ),
        );
      }

      if (chatListWidgets.isEmpty) {
         if (_isSearching) {
           return _buildEmptyState('No results found'.tr, 'Try adjusting your search'.tr);
         }
         return _buildEmptyState('No recent chats'.tr, 'Start a new conversation from Contacts'.tr);
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: chatListWidgets.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) => chatListWidgets[index],
      );
    });
  }

  Widget _buildContactsTab(Set<String> chattedUserIds) {
    return Obx(() {
      if (_manageUsersController.isLoading.value) {
        return _buildLoadingState();
      }

      // filteredUsersList already has the search query applied from ManageUsersController
      // We just need to filter out the chatted users.
      
      final contactsToShow = _manageUsersController.filteredUsersList.where((user) {
        final uid = user['uid'];
        // Exclude current user and users we've already chatted with
        return uid != _chatController.currentUserId && !chattedUserIds.contains(uid);
      }).toList();

      if (contactsToShow.isEmpty) {
        return _buildEmptyState('No contacts found'.tr, 'Try adjusting your search'.tr);
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: contactsToShow.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final user = contactsToShow[index];
          final userName = user['fullName'] ?? user['fullname'] ?? 'Unknown User';
          final userEmail = user['email'] ?? '';
          final userRole = user['role'] ?? 'User';
          final userAvatar = user['photoUrl'] ?? '';

          return _buildUserListItem(
            user: user,
            userName: userName,
            userEmail: userEmail,
            userRole: userRole,
            userAvatar: userAvatar,
            isChatTab: false,
          );
        },
      );
    });
  }

  Widget _buildUserListItem({
    required Map<String, dynamic> user,
    required String userName,
    required String userEmail,
    required String userRole,
    required String userAvatar,
    required bool isChatTab,
    String lastMessage = '',
    int unreadCount = 0,
  }) {
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
                // Avatar with Online Indicator
                Stack(
                  children: [
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
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: StreamBuilder<DatabaseEvent>(
                        stream: FirebaseDatabase.instanceFor(
                          app: Firebase.app(),
                          databaseURL: ExternalUrls.firebaseRtdbUrl,
                        )
                            .ref('status/${user['uid']}/status')
                            .onValue,
                        builder: (context, snapshot) {
                          final isOnline = snapshot.hasData &&
                              snapshot.data!.snapshot.value == 'online';
                          
                          return Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: isOnline ? Colors.green : Colors.grey,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Theme.of(context).cardColor,
                                width: 2,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(width: 16),
                
                // User info
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
                          if (isChatTab && lastMessage.isNotEmpty) ...[
                            Expanded(
                              child: Text(
                                lastMessage,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: (0.7)),
                                  fontSize: 13.sp,
                                  fontFamily: AppFontsStyles.raleway,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else if (!isChatTab && userEmail.isNotEmpty) ...[
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
                          ] else if (!isChatTab) ...[
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
                
                // Chevron icon or Unread Badge
                if (isChatTab && unreadCount > 0)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
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
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
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
                'Loading...'.tr,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: (0.7)),
                  fontSize: 14.sp,
                  fontFamily: AppFontsStyles.raleway,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
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
        child: SingleChildScrollView(
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
                title,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                  fontFamily: AppFontsStyles.raleway,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: (0.7)),
                  fontFamily: AppFontsStyles.raleway,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
