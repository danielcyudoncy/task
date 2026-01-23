// models/chat_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ChatUser {
  final String uid;
  final String name;
  final String? avatarUrl;
  final String? email;
  final String? fcmToken;
  final bool isOnline;
  final DateTime? lastActive;

  ChatUser({
    required this.uid,
    required this.name,
    this.avatarUrl,
    this.email,
    this.fcmToken,
    this.isOnline = false,
    this.lastActive,
  });

  factory ChatUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final timestamp = data['lastActive'] as Timestamp?;

    return ChatUser(
      uid: doc.id,
      name: data['fullName'] ?? data['email']?.split('@').first ?? 'Unknown',
      avatarUrl: data['photoUrl'] ?? data['profilePic'],
      email: data['email'],
      fcmToken: data['fcmToken'],
      isOnline: data['isOnline'] ?? false,
      lastActive: timestamp?.toDate(),
    );
  }

  String get status => isOnline
      ? 'Online'
      : lastActive != null
          ? 'Last seen ${_formatTime(lastActive!)}'
          : 'Offline';

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) return 'just now';
    if (difference.inHours < 1) return '${difference.inMinutes}m ago';
    if (difference.inDays < 1) return '${difference.inHours}h ago';
    if (difference.inDays < 7) return '${difference.inDays}d ago';

    return DateFormat('MMM d').format(time);
  }
}

class ChatMessage {
  final String id;
  final String senderId;
  final String content;
  final DateTime timestamp;
  final bool isRead;
  final String type;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.content,
    required this.timestamp,
    this.isRead = false,
    this.type = 'text',
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] ?? '',
      content: data['content'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] ?? false,
      type: data['type'] ?? 'text',
    );
  }
}

class ChatConversation {
  final String id;
  final List<String> participants;
  final DateTime updatedAt;
  final Map<String, dynamic>? lastMessage;
  final Map<String, int> unreadCounts;

  ChatConversation({
    required this.id,
    required this.participants,
    required this.updatedAt,
    this.lastMessage,
    this.unreadCounts = const {},
  });

  factory ChatConversation.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    
    // Parse unread counts safely
    final unreadMap = data['unreadCount'] as Map<String, dynamic>? ?? {};
    final parsedUnreadCounts = <String, int>{};
    unreadMap.forEach((key, value) {
      if (value is int) {
        parsedUnreadCounts[key] = value;
      } else if (value is num) {
        parsedUnreadCounts[key] = value.toInt();
      }
    });

    return ChatConversation(
      id: doc.id,
      participants:
          (data['participants'] as List?)?.whereType<String>().toList() ?? [],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastMessage: data['lastMessage'] as Map<String, dynamic>?,
      unreadCounts: parsedUnreadCounts,
    );
  }
}
