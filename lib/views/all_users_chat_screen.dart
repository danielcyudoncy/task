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
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('All Users')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('users').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final users = snapshot.data!.docs
              .where((doc) => doc.id != currentUserId)
              .toList();

          if (users.isEmpty) {
            return const Center(child: Text('No other users found'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final name = user['name'] ?? 'Unnamed';
              final avatar = user['photoUrl'] ?? '';

              return ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                      avatar.isNotEmpty ? NetworkImage(avatar) : null,
                  child: avatar.isEmpty ? Text(name[0].toUpperCase()) : null,
                ),
                title: Text(name),
                subtitle: Text(user['email'] ?? ''),
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
