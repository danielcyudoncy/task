// views/chat_list_screen.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../controllers/auth_controller.dart';
import 'chat_screen.dart';
import '../widgets/chat_nav_bar.dart';

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
  String currentUserId = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final result = await showSearch(
                context: context,
                delegate: ChatSearchDelegate(currentUserId),
              );
              if (result != null) {
                // You may want to navigate to chat here
              }
            },
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                icon: const Icon(Icons.message_outlined),
                onPressed: () {},
              ),
              if (totalUnread > 0)
                Positioned(
                  right: 8.w,
                  top: 8.h,
                  child: Container(
                    padding: EdgeInsets.all(5.r),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      totalUnread.toString(),
                      style: TextStyle(
                          fontSize: 10.sp,
                          color: Theme.of(context).colorScheme.onPrimary),
                    ),
                  ),
                )
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
                suffixIcon: queryClearIcon(isDark),
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
      body: Column(
        children: [
          // Horizontal list of online users
          SizedBox(
            height: 80,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('isOnline', isEqualTo: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final users = snapshot.data!.docs
                    .where((doc) => doc['uid'] != currentUserId)
                    .toList();
                if (users.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 8.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('No one is online',
                          style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Colors.grey[400]
                                  : Colors.grey[600])),
                    ),
                  );
                }
                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 12.0),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    final user = users[index].data() as Map<String, dynamic>;
                    final avatar = user['photoUrl'] ?? '';
                    final name = user['fullName'] ?? '';
                    return Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Theme.of(context).brightness ==
                                      Brightness.dark
                                  ? Theme.of(context).colorScheme.onPrimary
                                  : Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                          ),
                          child: avatar.isNotEmpty
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: avatar,
                                    width: 52,
                                    height: 52,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => CircleAvatar(
                                      radius: 26,
                                      child: Text(name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : '?'),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        CircleAvatar(
                                      radius: 26,
                                      child: Text(name.isNotEmpty
                                          ? name[0].toUpperCase()
                                          : '?'),
                                    ),
                                  ),
                                )
                              : CircleAvatar(
                                  radius: 26,
                                  child: Text(name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : '?'),
                                ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 56,
                          child: Text(
                            name.split(' ').first,
                            style: TextStyle(
                                fontSize: 12,
                                color: Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[400]
                                    : Colors.grey[600]),
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          // Expanded chat list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('conversations')
                  .where('participants', arrayContains: currentUserId)
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

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat, size: 48.sp, color: Colors.grey),
                        SizedBox(height: 16.h),
                        Text(
                          'No conversations yet',
                          style: TextStyle(
                              fontSize: 16.sp,
                              color: Theme.of(context).colorScheme.primary),
                        ),
                      ],
                    ),
                  );
                }

                docs.sort((a, b) {
                  final aPinned =
                      (a['pinnedUsers'] ?? []).contains(currentUserId);
                  final bPinned =
                      (b['pinnedUsers'] ?? []).contains(currentUserId);
                  if (aPinned && !bPinned) return -1;
                  if (!aPinned && bPinned) return 1;
                  return 0;
                });

                return ListView.builder(
                  padding: EdgeInsets.symmetric(vertical: 8.h),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final conversation = docs[index];
                    final data = conversation.data() as Map<String, dynamic>;
                    final participants =
                        List<String>.from(data['participants'] ?? []);
                    final receiverId =
                        participants.firstWhere((id) => id != currentUserId);
                    final lastMessage = data['lastMessage'] as String? ?? '';
                    final lastMessageTime =
                        (data['lastMessageTime'] as Timestamp?)?.toDate();
                    final unreadCountMap =
                        Map<String, dynamic>.from(data['unreadCount'] ?? {});
                    final unreadCount =
                        ((unreadCountMap[currentUserId] ?? 0) as num).toInt();

                    final pinnedList =
                        List<String>.from(data['pinnedUsers'] ?? []);
                    final pinned = pinnedList.contains(currentUserId);

                    totalUnread += unreadCount;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('users')
                          .doc(receiverId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (!userSnapshot.hasData) {
                          return const ListTile(title: Text('Loading...'));
                        }

                        final userData =
                            userSnapshot.data!.data() as Map<String, dynamic>;
                        final userName =
                            userData['fullName'] as String? ?? 'Unknown';
                        final userAvatar =
                            userData['photoUrl'] as String? ?? '';
                        final isOnline = userData['isOnline'] as bool? ?? false;
                        final lastSeenTimestamp =
                            (userData['lastSeen'] as Timestamp?)?.toDate();

                        if (searchQuery.isNotEmpty &&
                            !userName
                                .toLowerCase()
                                .contains(searchQuery.toLowerCase())) {
                          return const SizedBox.shrink();
                        }

                        return Dismissible(
                          key: Key(conversation.id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) => Future.value(true),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 20.w),
                            color: Colors.red,
                            child:
                                const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) {
                            FirebaseFirestore.instance
                                .collection('conversations')
                                .doc(conversation.id)
                                .delete();
                          },
                          child: GestureDetector(
                            onLongPress: () async {
                              await togglePin(conversation.id, pinned);
                            },
                            child: buildChatTile(
                              conversation.id,
                              userName,
                              userAvatar,
                              isOnline,
                              lastSeenTimestamp,
                              lastMessage,
                              lastMessageTime,
                              unreadCount,
                              pinned,
                              receiverId,
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ChatNavBar(currentIndex: 0),
    );
  }

  Widget queryClearIcon(bool isDark) {
    if (searchQuery.isNotEmpty) {
      return IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          setState(() {
            searchQuery = '';
            searchController.clear();
          });
        },
      );
    }
    return const SizedBox.shrink();
  }

  Widget buildChatTile(
    String conversationId,
    String userName,
    String userAvatar,
    bool isOnline,
    DateTime? lastSeenTimestamp,
    String lastMessage,
    DateTime? lastMessageTime,
    int unreadCount,
    bool pinned,
    String receiverId,
  ) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: ListTile(
        leading: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.primary,
              width: 2,
            ),
          ),
          child: userAvatar.isNotEmpty
              ? ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: userAvatar,
                    width: 48.r,
                    height: 48.r,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => CircleAvatar(
                      radius: 24.r,
                      child: Text(userName[0].toUpperCase()),
                    ),
                    errorWidget: (context, url, error) => CircleAvatar(
                      radius: 24.r,
                      child: Text(userName[0].toUpperCase()),
                    ),
                  ),
                )
              : CircleAvatar(
                  radius: 24.r,
                  child: Text(userName[0].toUpperCase()),
                ),
        ),
        title: buildTitleRow(userName, pinned, unreadCount),
        subtitle: buildSubtitle(conversationId, lastMessage),
        trailing: buildTrailing(lastMessageTime, unreadCount),
        onTap: () => openChatScreen(
          receiverId,
          userName,
          userAvatar,
          conversationId,
        ),
      ),
    );
  }

  Widget buildTitleRow(String name, bool pinned, int unreadCount) {
    return Row(
      children: [
        Expanded(
          child: Text(
            name,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        if (pinned) Icon(Icons.push_pin, size: 18.sp, color: Colors.grey),
      ],
    );
  }

  Widget buildSubtitle(String conversationId, String lastMessage) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('conversations')
          .doc(conversationId)
          .collection('typingStatus')
          .doc(currentUserId)
          .snapshots(),
      builder: (context, typingSnapshot) {
        final data = typingSnapshot.data?.data() as Map<String, dynamic>?;
        final isTyping = data?['isTyping'] == true;
        final text = isTyping ? 'Typing...' : lastMessage;
        return Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14.sp,
            fontStyle: isTyping ? FontStyle.italic : FontStyle.normal,
            color: isTyping ? Colors.blue : Colors.black,
          ),
        );
      },
    );
  }

  Widget buildTrailing(DateTime? time, int unreadCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          time != null ? _formatTime(time) : '',
          style: TextStyle(fontSize: 12.sp),
        ),
        if (unreadCount > 0)
          Container(
            margin: EdgeInsets.only(top: 4.h),
            padding: EdgeInsets.all(6.r),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Text(
              unreadCount.toString(),
              style: TextStyle(
                  fontSize: 10.sp,
                  color: Theme.of(context).colorScheme.onPrimary),
            ),
          ),
      ],
    );
  }

  Future<void> togglePin(String conversationId, bool currentlyPinned) async {
    final convoRef = FirebaseFirestore.instance
        .collection('conversations')
        .doc(conversationId);
    await convoRef.update({
      if (currentlyPinned)
        'pinnedUsers': FieldValue.arrayRemove([currentUserId])
      else
        'pinnedUsers': FieldValue.arrayUnion([currentUserId])
    });
  }

  void openChatScreen(
      String receiverId, String name, String avatarUrl, String conversationId) {
    Get.to(
      () => ChatScreen(
        receiverId: receiverId,
        receiverName: name,
        receiverAvatar: avatarUrl,
        conversationId: conversationId,
        otherUserId: '',
        otherUserName: null,
        otherUser: const {},
        chatId: '',
        chatBackground: '',
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final msgDate = DateTime(date.year, date.month, date.day);
    if (msgDate == today) {
      return DateFormat('HH:mm').format(date);
    } else if (msgDate == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('MMM dd').format(date);
    }
  }
}

class ChatSearchDelegate extends SearchDelegate<String> {
  final String currentUserId;
  ChatSearchDelegate(this.currentUserId);

  @override
  List<Widget>? buildActions(BuildContext context) => [
        IconButton(
          icon: const Icon(Icons.clear),
          onPressed: () => query = '',
        ),
      ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => close(context, ''),
      );

  @override
  Widget buildResults(BuildContext context) => const SizedBox.shrink();

  @override
  Widget buildSuggestions(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('users').get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final suggestions = snapshot.data!.docs.where((doc) {
          final name = (doc.data() as Map)['name'] as String? ?? '';
          return name.toLowerCase().contains(query.toLowerCase());
        }).toList();

        return ListView.builder(
          itemCount: suggestions.length,
          itemBuilder: (context, index) {
            final doc = suggestions[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['fullName'] as String? ?? 'Unknown';
            final avatar = data['photoUrl'] as String? ?? '';
            final uid = doc.id;
            return ListTile(
              leading: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: avatar.isNotEmpty
                    ? ClipOval(
                        child: CachedNetworkImage(
                          imageUrl: avatar,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => CircleAvatar(
                            child: Text(name[0].toUpperCase()),
                          ),
                          errorWidget: (context, url, error) => CircleAvatar(
                            child: Text(name[0].toUpperCase()),
                          ),
                        ),
                      )
                    : CircleAvatar(
                        child: Text(name[0].toUpperCase()),
                      ),
              ),
              title: Text(name),
              onTap: () {
                close(context, uid);
              },
            );
          },
        );
      },
    );
  }
}
