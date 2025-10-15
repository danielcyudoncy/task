// screens/user_list_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:task/screens/chat_screen.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  State<UserListScreen> createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select a user')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value.trim().toLowerCase();
                });
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .where('uid', isNotEqualTo: currentUser.uid) // ✅ fixed
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allUsers = snapshot.data!.docs;

                final filteredUsers = allUsers.where((doc) {
                  final user = doc.data() as Map<String, dynamic>?;
                  if (user == null) return false;

                  final name = (user['fullName'] ?? '')
                      .toString()
                      .toLowerCase(); // ✅ fixed
                  return name.contains(searchQuery);
                }).toList();

                // Separate pinned and regular users
                final pinnedUsers = filteredUsers.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['isPinned'] == true;
                }).toList();

                final otherUsers = filteredUsers.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['isPinned'] != true;
                }).toList();

                final displayUsers = [...pinnedUsers, ...otherUsers];

                if (displayUsers.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                return ListView.builder(
                  itemCount: displayUsers.length,
                  itemBuilder: (context, index) {
                    final userData =
                        displayUsers[index].data() as Map<String, dynamic>?;

                    if (userData == null) return const SizedBox.shrink();

                    final userId = userData['uid'] ?? ''; // ✅ fixed
                    final userName =
                        userData['fullName'] ?? 'unknown'.tr; // ✅ fixed
                    final userAvatar = userData['photoUrl']; // ✅ fixed

                    final isPinned = userData['isPinned'] == true;

                    return ListTile(
                      leading: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                Theme.of(context).brightness == Brightness.dark
                                    ? Theme.of(context).colorScheme.onPrimary
                                    : Colors.white,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          child: (userAvatar != null && userAvatar.isNotEmpty)
                              ? ClipOval(
                                  child: CachedNetworkImage(
                                    imageUrl: userAvatar,
                                    width: 40,
                                    height: 40,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) =>
                                        CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                    ),
                                    errorWidget: (context, url, error) => Text(
                                      userName.isNotEmpty ? userName[0] : '?',
                                    ),
                                  ),
                                )
                              : Text(
                                  userName.isNotEmpty ? userName[0] : '?',
                                ),
                        ),
                      ),
                      title: Text(userName),
                      trailing: isPinned
                          ? const Icon(Icons.push_pin, color: Colors.orange)
                          : null,
                      onTap: () async {
                        final conversationId = await _startOrGetConversation(
                          currentUser.uid,
                          userId,
                        );

                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          Get.to(() => ChatScreen(
                                conversationId: conversationId,
                                otherUser: userData,
                                receiverId: userId,
                                receiverName: userName,
                                receiverAvatar: userAvatar ?? '',
                                chatId: conversationId,
                                otherUserId: userId,
                                otherUserName: userName,
                                chatBackground: '',
                              ));
                        });
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _startOrGetConversation(
      String currentUserId, String otherUserId) async {
    final query = await FirebaseFirestore.instance
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .get();

    for (var doc in query.docs) {
      final participants = List<String>.from(doc['participants']);
      if (participants.contains(otherUserId)) {
        return doc.id;
      }
    }

    final newDoc =
        await FirebaseFirestore.instance.collection('conversations').add({
      'participants': [currentUserId, otherUserId],
      'timestamp': FieldValue.serverTimestamp(),
      'lastMessage': '',
    });

    return newDoc.id;
  }
}
