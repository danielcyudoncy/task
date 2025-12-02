// screens/all_users_chat_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import '../controllers/auth_controller.dart';
import '../controllers/settings_controller.dart';
import 'chat_screen.dart';
import 'wallpaper_screen.dart';
import '../controllers/wallpaper_controller.dart';

class AllUsersChatScreen extends StatefulWidget {
  final String? chatBackground;

  const AllUsersChatScreen({super.key, this.chatBackground});

  @override
  State<AllUsersChatScreen> createState() => _AllUsersChatScreenState();
}

class _AllUsersChatScreenState extends State<AllUsersChatScreen> {
  final AuthController authController = Get.find<AuthController>();
  String searchQuery = '';
  bool isRefreshing = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final WallpaperController _wallpaperController =
      Get.find<WallpaperController>();

  // Map to store conversation data for each user
  Map<String, Map<String, dynamic>> _userConversations = {};

  @override
  void initState() {
    super.initState();
    _refreshUsers();

    // Fetch conversations when screen initializes
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId != null) {
      _fetchConversations(currentUserId);
    }
  }

  @override
  void dispose() {
    // Clean up any active operations
    super.dispose();
  }

  Future<void> _refreshUsers() async {
    // Use single setState with delayed callback to avoid multiple rebuilds
    setState(() {
      isRefreshing = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            isRefreshing = false;
          });

          // Refresh conversations data as well
          final currentUserId = FirebaseAuth.instance.currentUser?.uid;
          if (currentUserId != null) {
            _fetchConversations(currentUserId);
          }
        }
      });
    });
  }

  // Helper method to format timestamp for display
  String _formatMessageTime(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final date = timestamp.toDate();
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'now'.tr;
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return DateFormat('EEE').format(date); // Shows day name like "Mon", "Tue"
    } else if (difference.inDays < 365) {
      return DateFormat('d/MM').format(date); // Shows date like "15/12"
    } else {
      return DateFormat('d/MM/yy').format(date); // Shows date like "15/12/23"
    }
  }

  // Build subtitle with WhatsApp-like behavior
  Widget _buildSubtitle(String userId, String email, ThemeData theme) {
    final conversation = _userConversations[userId];

    if (conversation != null) {
      // User has an existing conversation
      final lastMessage = conversation['lastMessage'] as String? ?? '';
      final lastMessageTime = conversation['lastMessageTime'] as Timestamp?;

      if (lastMessage.isNotEmpty) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                lastMessage,
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (lastMessageTime != null) ...[
              const SizedBox(width: 8),
              Text(
                _formatMessageTime(lastMessageTime),
                style: TextStyle(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        );
      }
    }

    // User has no conversation - show "Chat" text like WhatsApp
    return Text(
      'Chat',
      style: TextStyle(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // Fetch conversation data for the current user
  Future<void> _fetchConversations(String currentUserId) async {
    try {
      final conversationsSnapshot = await FirebaseFirestore.instance
          .collection('conversations')
          .where('participants', arrayContains: currentUserId)
          .get();

      Map<String, Map<String, dynamic>> conversationMap = {};

      for (final doc in conversationsSnapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants'] ?? []);

        // Find the other participant (not current user)
        final otherUserId = participants.firstWhere(
          (id) => id != currentUserId,
          orElse: () => '',
        );

        if (otherUserId.isNotEmpty) {
          conversationMap[otherUserId] = {
            'lastMessage': data['lastMessage'] ?? '',
            'lastMessageTime': data['lastMessageTime'],
            'conversationId': doc.id,
          };
        }
      }

      if (mounted) {
        setState(() {
          _userConversations = conversationMap;
        });
      }
    } catch (e) {
      // Handle error silently or log using proper logging service
      // print('Error fetching conversations: $e');
    }
  }

  void _handleUserTap(DocumentSnapshot user) async {
    final otherUser = user.data() as Map<String, dynamic>;
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    if (currentUserId == null) return;

    final conversationId = [currentUserId, otherUser['uid']]..sort();
    final chatId = conversationId.join('_');

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final conversationDoc = await FirebaseFirestore.instance
          .collection('conversations')
          .doc(chatId)
          .get();

      if (!conversationDoc.exists) {
        await FirebaseFirestore.instance
            .collection('conversations')
            .doc(chatId)
            .set({
          'participants': [currentUserId, otherUser['uid']],
          'lastMessage': '',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ChatScreen(
            receiverId: otherUser['uid'],
            receiverName: otherUser['fullName'] ?? 'User',
            receiverAvatar: otherUser['photoUrl'] ?? '',
            conversationId: chatId,
            chatId: chatId,
            otherUserId: otherUser['uid'],
            otherUserName: otherUser['fullName'] ?? 'User',
            otherUser: otherUser,
            chatBackground: widget.chatBackground,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to start chat: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Add safety check for build phase
    if (!mounted) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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
          child: Column(
            children: [
              AppBar(
                backgroundColor: Theme.of(context).brightness == Brightness.dark
                    ? [Colors.grey[900]!, Colors.grey[800]!]
                        .reduce((value, element) => value)
                    : Theme.of(context).colorScheme.primary,
                elevation: 1,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back,
                      color: theme.colorScheme.onPrimary),
                  onPressed: () {
                    Get.find<SettingsController>().triggerFeedback();
                    Get.back();
                  },
                ),
                title: Text('Chat With Users',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.bold,
                    )),
                actions: [
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
              ),
              Expanded(
                child: _buildBody(context, currentUserId, theme),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBody(
      BuildContext context, String currentUserId, ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(12.w),
          child: TextField(
            onChanged: (value) => setState(() => searchQuery = value.trim()),
            decoration: InputDecoration(
              hintText: 'Search users...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: theme.inputDecorationTheme.fillColor,
              border: theme.inputDecorationTheme.border,
            ),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshUsers,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('uid', isNotEqualTo: currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                // Add safety check for build phase
                if (!mounted) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.connectionState == ConnectionState.waiting &&
                    !isRefreshing) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users = snapshot.data!.docs
                    .where((doc) => doc['uid'] != currentUserId)
                    .toList();
                if (users.isEmpty) {
                  return const Padding(
                    padding:
                        EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('No one is online',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: users.length,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    // Add safety check for build phase
                    if (!mounted) {
                      return const SizedBox.shrink();
                    }
                    final user = users[index];
                    final userData = user.data() as Map<String, dynamic>;
                    final name = userData['fullName'] ?? 'Unknown';
                    final email = userData['email'] ?? '';
                    final avatar = userData['photoUrl'] ?? '';
                    final isOnline = userData['isOnline'] == true;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      padding:
                          EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      child: Card(
                        color: theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        elevation: 2,
                        child: ListTile(
                          leading: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? Theme.of(context)
                                            .colorScheme
                                            .onPrimary
                                        : Theme.of(context).colorScheme.primary,
                                    width: 2,
                                  ),
                                ),
                                child: avatar.isNotEmpty
                                    ? ClipOval(
                                        child: CachedNetworkImage(
                                          imageUrl: avatar,
                                          width: 48.r,
                                          height: 48.r,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              CircleAvatar(
                                            radius: 24.r,
                                            child: Text(
                                              name.isNotEmpty
                                                  ? name[0].toUpperCase()
                                                  : '?',
                                              style: TextStyle(
                                                color:
                                                    theme.colorScheme.onSurface,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              CircleAvatar(
                                            radius: 24.r,
                                            child: Text(
                                              name.isNotEmpty
                                                  ? name[0].toUpperCase()
                                                  : '?',
                                              style: TextStyle(
                                                color:
                                                    theme.colorScheme.onSurface,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      )
                                    : CircleAvatar(
                                        radius: 24.r,
                                        child: Text(
                                          name.isNotEmpty
                                              ? name[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            color: theme.colorScheme.onSurface,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                              ),
                              if (isOnline)
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    width: 12.w,
                                    height: 12.h,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: theme.colorScheme.surface,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          title: Text(
                            name,
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle:
                              _buildSubtitle(userData['uid'], email, theme),
                          onTap: () => _handleUserTap(user),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
