// controllers/chat_controller.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:task/models/chat_model.dart';


class ChatController extends GetxController {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  String get currentUserId => _auth.currentUser?.uid ?? '';

  Stream<List<ChatConversation>> getConversations() {
    if (currentUserId.isEmpty) return const Stream.empty();

    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: currentUserId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .handleError(
            (e) => Get.log('ChatController: getConversations error - $e'))
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatConversation.fromFirestore(doc))
            .toList());
  }

  Future<String> getOrCreateConversation(String otherUserId) async {
    if (currentUserId.isEmpty) return '';

    final participants = [currentUserId, otherUserId]..sort();
    final conversationId = participants.join('_');

    try {
      final doc = await _firestore
          .collection('conversations')
          .doc(conversationId)
          .get();

      if (!doc.exists) {
        await _firestore.collection('conversations').doc(conversationId).set({
          'participants': participants,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      return conversationId;
    } catch (e) {
      Get.log('ChatController: getOrCreateConversation error - $e');
      return '';
    }
  }

  Future<bool> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    if (currentUserId.isEmpty) return false;

    try {
      final batch = _firestore.batch();
      final messagesRef = _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc();

      batch.set(messagesRef, {
        'senderId': currentUserId,
        'content': content,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': false,
        'type': 'text',
      });

      batch.update(
        _firestore.collection('conversations').doc(conversationId),
        {
          'lastMessage': {
            'senderId': currentUserId,
            'content': content,
            'timestamp': FieldValue.serverTimestamp(),
          },
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();
      return true;
    } catch (e) {
      Get.log('ChatController: sendMessage error - $e');
      return false;
    }
  }
}
