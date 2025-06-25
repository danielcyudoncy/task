// views/all_users_chat_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'chat_screen.dart';

class AllUsersChatScreen extends StatelessWidget {
  const AllUsersChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == null) {
      return const Scaffold(
        body: Center(child: Text('Please sign in to chat')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Users'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // Implement search functionality
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('uid', isNotEqualTo: currentUserId) // Exclude current user
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No other users found'));
          }

          final users = snapshot.data!.docs;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final userData = user.data() as Map<String, dynamic>;
              final name = userData['name'] ?? 'Unknown';
              final email = userData['email'] ?? '';
              final avatar = userData['profilePic'] ?? '';

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  child: avatar.isEmpty ? Text(name[0].toUpperCase()) : null,
                ),
                title: Text(name),
                subtitle: Text(email),
                onTap: () {
                  Get.to(() => ChatScreen(
                        receiverId: user.id,
                        receiverName: name,
                        receiverAvatar: avatar,
                      ));
                },
              );
            },
          );
        },
      ),
    );
  }
}
