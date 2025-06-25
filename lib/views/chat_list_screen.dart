// views/chat_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:task/views/chat_screen.dart';
import '../controllers/auth_controller.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final AuthController authController = Get.find<AuthController>();
  String searchQuery = '';
  TextEditingController searchController = TextEditingController();
  int totalUnread = 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.message_outlined),
                onPressed: () {},
              ),
              if (totalUnread > 0)
                Container(
                  margin: EdgeInsets.only(top: 8.h, right: 8.w),
                  padding: EdgeInsets.all(5.r),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    totalUnread.toString(),
                    style: TextStyle(fontSize: 10.sp, color: Colors.white),
                  ),
                ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(50.h),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            searchQuery = '';
                            searchController.clear();
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: isDark ? Colors.grey[900] : Colors.grey[200],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('conversations')
            .where('participants',
                arrayContains: FirebaseAuth.instance.currentUser!.uid)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          totalUnread = 0;

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final conversations = snapshot.data!.docs;

          return ListView.builder(
            padding: EdgeInsets.symmetric(vertical: 8.h),
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation =
                  conversations[index].data() as Map<String, dynamic>;
              final participants =
                  conversation['participants'] as List<dynamic>;
              final receiverId = participants.firstWhere(
                  (id) => id != FirebaseAuth.instance.currentUser!.uid);
              final lastMessage = conversation['lastMessage'] ?? '';
              final lastMessageTime =
                  conversation['lastMessageTime'] as Timestamp?;
              final unreadCount = (conversation['unreadCount'] ?? 0) as int;

              totalUnread += unreadCount;

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(receiverId)
                    .get(),
                builder: (context, userSnapshot) {
                  if (!userSnapshot.hasData) return const SizedBox();
                  final userData =
                      userSnapshot.data!.data() as Map<String, dynamic>;
                  final userName = userData['name'] ?? 'Unknown';
                  final userAvatar = userData['profilePic'] ?? '';
                  final isOnline = userData['isOnline'] ?? false;
                  final lastSeen = userData['lastSeen'];

                  if (searchQuery.isNotEmpty &&
                      !userName
                          .toLowerCase()
                          .contains(searchQuery.toLowerCase())) {
                    return const SizedBox.shrink();
                  }

                  return Dismissible(
                    key: Key(conversations[index].id),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: EdgeInsets.only(right: 20.w),
                      color: Colors.red,
                      child: const Icon(Icons.delete, color: Colors.white),
                    ),
                    confirmDismiss: (_) =>
                        _confirmDelete(conversations[index].id),
                    child: GestureDetector(
                      onLongPress: () =>
                          _confirmDelete(conversations[index].id),
                      child: Card(
                        margin: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 4.h),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r)),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundImage: userAvatar.isNotEmpty
                                ? NetworkImage(userAvatar)
                                : null,
                            child: userAvatar.isEmpty
                                ? Text(
                                    userName[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      color:
                                          isDark ? Colors.black : Colors.white,
                                    ),
                                  )
                                : null,
                          ),
                          title: Text(
                            userName,
                            style: TextStyle(
                              fontWeight: unreadCount > 0
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 16.sp,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 13.sp, color: Colors.grey),
                              ),
                              Text(
                                isOnline
                                    ? 'Online'
                                    : lastSeen != null
                                        ? 'Last seen ${_timeAgo(DateTime.fromMillisecondsSinceEpoch(lastSeen))}'
                                        : 'Offline',
                                style: TextStyle(
                                    fontSize: 11.sp,
                                    color:
                                        isOnline ? Colors.green : Colors.grey),
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (lastMessageTime != null)
                                Text(
                                  _formatTime(lastMessageTime.toDate()),
                                  style: TextStyle(
                                      fontSize: 12.sp, color: Colors.grey),
                                ),
                              if (unreadCount > 0)
                                TweenAnimationBuilder(
                                  tween: Tween<double>(begin: 0.8, end: 1.0),
                                  duration: const Duration(milliseconds: 300),
                                  curve: Curves.easeInOut,
                                  builder: (context, scale, child) {
                                    return Transform.scale(
                                      scale: scale,
                                      child: Container(
                                        padding: EdgeInsets.all(6.r),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).primaryColor,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          unreadCount.toString(),
                                          style: TextStyle(
                                              fontSize: 10.sp,
                                              color: Colors.white),
                                        ),
                                      ),
                                    );
                                  },
                                ),
                            ],
                          ),
                          onTap: () {
                            Get.to(() => ChatScreen(
                                  receiverId: receiverId,
                                  receiverName: userName,
                                  receiverAvatar: userAvatar,
                                ));
                          },
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 48.sp, color: Colors.grey),
          SizedBox(height: 16.h),
          Text('No conversations yet',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey)),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(String conversationId) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Conversation'),
        content: const Text('Are you sure you want to delete this chat?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection('conversations')
                  .doc(conversationId)
                  .delete();
              Navigator.pop(context, true);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirm ?? false;
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return DateFormat('hh:mm a').format(date);
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM d').format(date);
    }
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) {
      return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    }
    if (diff.inDays == 1) return 'yesterday';
    return '${diff.inDays} days ago';
  }
}
