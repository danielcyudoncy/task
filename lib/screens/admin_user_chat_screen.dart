// screens/admin_user_chat_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:task/controllers/auth_controller.dart';
import 'package:task/controllers/chat_controller.dart';
import 'package:task/controllers/manage_users_controller.dart';
import 'package:task/controllers/settings_controller.dart';
import 'package:task/controllers/wallpaper_controller.dart';
import 'package:task/models/chat_model.dart';
import 'package:task/screens/chat_screen.dart';
import 'package:task/screens/wallpaper_screen.dart';
import 'package:task/utils/constants/app_fonts_family.dart';

class AdminUserChatScreen extends StatefulWidget {
  final String? chatBackground;

  const AdminUserChatScreen({super.key, this.chatBackground});

  @override
  State<AdminUserChatScreen> createState() => _AdminUserChatScreenState();
}

class _AdminUserChatScreenState extends State<AdminUserChatScreen>
    with SingleTickerProviderStateMixin {
  final AuthController authController = Get.find<AuthController>();
  // Use Get.put to ensure they are available if not already in the tree, or Get.find if guaranteed
  final ChatController _chatController = Get.find();
  final ManageUsersController _manageUsersController = Get.find();
  final WallpaperController _wallpaperController =
      Get.find<WallpaperController>();

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
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
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = isDark
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.primary;

    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to chat')),
      );
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark
            ? [Colors.grey[900]!, Colors.grey[800]!]
                .reduce((value, element) => value)
            : Theme.of(context).colorScheme.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onPrimary),
          onPressed: () {
            if (Get.isRegistered<SettingsController>()) {
              Get.find<SettingsController>().triggerFeedback();
            }
            Get.back();
          },
        ),
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 18.sp,
                  fontFamily: AppFontsStyles.raleway,
                ),
                decoration: InputDecoration(
                  hintText: 'Search...'.tr,
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.6),
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
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            color: theme.colorScheme.onPrimary,
            onPressed: _toggleSearch,
          ),
          IconButton(
            icon: const Icon(Icons.wallpaper),
            color: theme.colorScheme.onPrimary,
            tooltip: 'Change Chat Wallpaper',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                    builder: (context) => const WallpaperScreen()),
              );
            },
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
      ),
      body: Obx(() {
        final wallpaperValue = _wallpaperController.wallpaper.value;
        BoxDecoration decoration;
        if (wallpaperValue.isEmpty) {
          decoration = BoxDecoration(color: backgroundColor);
        } else if (wallpaperValue.startsWith('asset:')) {
          final path = wallpaperValue.substring(6);
          decoration = BoxDecoration(
            image: DecorationImage(
              image: AssetImage(path),
              fit: BoxFit.cover,
            ),
          );
        } else if (wallpaperValue.startsWith('#')) {
          decoration = BoxDecoration(
              color: Color(
                  int.parse('FF${wallpaperValue.substring(1)}', radix: 16)));
        } else {
          decoration = BoxDecoration(color: backgroundColor);
        }

        return Container(
          decoration: decoration,
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
                  _buildContactsTab(chattedUserIds, theme),
                ],
              );
            },
          ),
        );
      }),
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

  Widget _buildChatsTab(
      List<ChatConversation> conversations, Set<String> chattedUserIds) {
    if (conversations.isEmpty) {
      return _buildEmptyState(
          'No recent chats'.tr, 'Start a new conversation from Contacts'.tr);
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

        final userName =
            userMap['fullName'] ?? userMap['fullname'] ?? 'Unknown User';
        final userEmail = userMap['email'] ?? '';
        final userAvatar = userMap['photoUrl'] ?? '';
        final userRole = userMap['role'] ?? 'User';

        // Get last message and unread count
        final lastMessage = conv.lastMessage;
        final lastMessageContent = lastMessage != null
            ? lastMessage['content'] as String? ?? ''
            : '';
        
        String lastMessageTime = '';
        if (lastMessage != null && lastMessage['timestamp'] != null) {
          final ts = lastMessage['timestamp'];
          if (ts is Timestamp) {
            lastMessageTime = _formatMessageTime(ts.toDate());
          }
        }

        final unreadCount =
            conv.unreadCounts[_chatController.currentUserId] ?? 0;

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
            lastMessageTime: lastMessageTime,
            unreadCount: unreadCount,
          ),
        );
      }

      if (chatListWidgets.isEmpty) {
        if (_isSearching) {
          return _buildEmptyState(
              'No results found'.tr, 'Try adjusting your search'.tr);
        }
        return _buildEmptyState(
            'No recent chats'.tr, 'Start a new conversation from Contacts'.tr);
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: chatListWidgets.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) => chatListWidgets[index],
      );
    });
  }

  Widget _buildContactsTab(Set<String> chattedUserIds, ThemeData theme) {
    return Obx(() {
      if (_manageUsersController.isLoading.value) {
        return _buildLoadingState();
      }

      // filteredUsersList already has the search query applied from ManageUsersController
      // We just need to filter out the chatted users.

      final contactsToShow =
          _manageUsersController.filteredUsersList.where((user) {
        final uid = user['uid'];
        // Exclude current user and users we've already chatted with
        return uid != _chatController.currentUserId &&
            !chattedUserIds.contains(uid);
      }).toList();

      if (contactsToShow.isEmpty) {
        return _buildEmptyState(
            'No contacts found'.tr, 'Try adjusting your search'.tr);
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        itemCount: contactsToShow.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final user = contactsToShow[index];
          final userName =
              user['fullName'] ?? user['fullname'] ?? 'Unknown User';
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

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(time.year, time.month, time.day);

    if (date == today) {
      return DateFormat('hh:mm a').format(time);
    } else if (date == today.subtract(const Duration(days: 1))) {
      return 'Yesterday';
    } else if (now.difference(time).inDays < 7) {
      return DateFormat('EEEE').format(time);
    } else {
      return DateFormat('dd/MM/yy').format(time);
    }
  }

  Widget _buildUserListItem({
    required Map<String, dynamic> user,
    required String userName,
    required String userEmail,
    required String userRole,
    required String userAvatar,
    required bool isChatTab,
    String lastMessage = '',
    String lastMessageTime = '',
    int unreadCount = 0,
  }) {
    // Determine if we should use the emulator based on the environment flag
    const useEmulator =
        bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);

    FirebaseDatabase database;
    if (useEmulator) {
      database = FirebaseDatabase.instance;
    } else {
      // Use the default instance to ensure consistency with Firebase.initializeApp
      database = FirebaseDatabase.instance;
      // Log the database URL for debugging
      debugPrint(
          'AdminChat: Using Database URL: ${database.app.options.databaseURL}');
    }

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
            final conversationId =
                await _chatController.getOrCreateConversation(user['uid']);

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
                    chatBackground: widget.chatBackground ?? '',
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
                          colors:
                              Theme.of(context).brightness == Brightness.dark
                                  ? [
                                      Colors.white,
                                      Colors.white.withValues(alpha: 0.9),
                                    ]
                                  : [
                                      Theme.of(context).primaryColor,
                                      Theme.of(context)
                                          .primaryColor
                                          .withValues(alpha: 0.8),
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
                                userName.isNotEmpty
                                    ? userName[0].toUpperCase()
                                    : '?',
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
                        stream: database
                            .ref('status/${user['uid']}/status')
                            .onValue,
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            debugPrint(
                                'AdminChat: Error reading status: ${snapshot.error}');
                            return const SizedBox();
                          }

                          final statusValue = snapshot.data?.snapshot.value;
                          debugPrint(
                              'AdminChat: Status for ${user['uid']} (${user['fullName']}) -> $statusValue');
                          final isOnline = statusValue == 'online';
                          final isMissing = statusValue == null;

                          return Tooltip(
                            message: 'Status: $statusValue',
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: isOnline
                                    ? Colors.green
                                    : (isMissing ? Colors.orange : Colors.grey),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Theme.of(context).cardColor,
                                  width: 2,
                                ),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
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
                          ),
                          if (isChatTab && lastMessageTime.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                lastMessageTime,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                                  fontFamily: AppFontsStyles.raleway,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (isChatTab && lastMessage.isNotEmpty) ...[
                            Expanded(
                              child: Text(
                                lastMessage,
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: (0.7)),
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
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: (0.7)),
                                  fontSize: 13.sp,
                                  fontFamily: AppFontsStyles.raleway,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ] else if (!isChatTab) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .primaryColor
                                    .withValues(alpha: 0.1),
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
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: (0.5)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline,
              size: 64, color: Theme.of(context).disabledColor),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).disabledColor,
              fontFamily: AppFontsStyles.raleway,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).disabledColor,
              fontFamily: AppFontsStyles.raleway,
            ),
          ),
        ],
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
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: (0.7)),
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
}
